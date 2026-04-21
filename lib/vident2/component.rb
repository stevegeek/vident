# frozen_string_literal: true

require "set"

require_relative "error"
require_relative "internals/declarations"
require_relative "internals/dsl"
require_relative "internals/registry"
require_relative "internals/draft"
require_relative "internals/plan"
require_relative "internals/resolver"
require_relative "internals/attribute_writer"
require_relative "internals/class_list_builder"
require_relative "stimulus/collection"
require_relative "tailwind"

module Vident2
  # Composition root for Vident 2.0 components: props, DSL receiver,
  # singular/plural parsers, add_stimulus_* mutators, and the render
  # pipeline glue.
  module Component
    extend ActiveSupport::Concern

    include ::Vident2::Tailwind

    included do
      extend Literal::Properties

      prop :element_tag, Symbol, default: :div
      prop :id, _Nilable(String)
      prop :classes, _Union(String, _Array(String)), default: -> { [] }
      prop :html_options, Hash, default: -> { {} }

      # Stimulus input props. Resolver folds these into the Draft at init.
      # `stimulus_controllers:` APPENDS to the implied controller (which
      # seeds first unless `no_stimulus_controller`).
      prop :stimulus_controllers,
        _Array(_Union(String, Symbol, ::Vident2::Stimulus::Controller)),
        default: -> { [] }
      prop :stimulus_actions,
        _Array(_Union(String, Symbol, Array, Hash, ::Vident2::Stimulus::Action)),
        default: -> { [] }
      prop :stimulus_targets,
        _Array(_Union(String, Symbol, Array, ::Vident2::Stimulus::Target)),
        default: -> { [] }
      prop :stimulus_outlets,
        _Array(_Union(String, Symbol, Array, ::Vident2::Stimulus::Outlet)),
        default: -> { [] }
      prop :stimulus_outlet_host, _Nilable(::Vident2::Component)
      prop :stimulus_values,
        _Union(_Hash(Symbol, _Any), Array, ::Vident2::Stimulus::Value),
        default: -> { {} }
      prop :stimulus_params,
        _Union(_Hash(Symbol, _Any), Array, ::Vident2::Stimulus::Param),
        default: -> { {} }
      prop :stimulus_classes,
        _Union(_Hash(Symbol, _Any), Array, ::Vident2::Stimulus::ClassMap),
        default: -> { {} }

      # Eager inheritance: subclasses copy parent's frozen Declarations
      # (see `inherited` below).
      @__vident2_declarations = ::Vident2::Internals::Declarations.empty
      @__vident2_no_stimulus_controller = false
    end

    class_methods do
      def prop_names
        literal_properties.properties_index.keys.map(&:to_sym)
      end

      # `Admin::UserCardComponent` → `admin/user_card_component`.
      # Anonymous classes return a stable placeholder.
      def stimulus_identifier_path
        name&.underscore || "anonymous_component"
      end

      # The `data-controller` / root-class form, e.g. `admin--user-card-component`.
      def stimulus_identifier
        stimulus_identifier_path.split("/").map(&:dasherize).join("--")
      end

      def component_name
        @component_name ||= stimulus_identifier
      end

      # Frozen DSL aggregate (own + inherited). Always non-nil.
      def declarations
        @__vident2_declarations ||= ::Vident2::Internals::Declarations.empty
      end

      # Suppresses the implied controller. A `stimulus do` block with
      # entries after this call raises `DeclarationError`.
      def no_stimulus_controller
        if declarations.any?
          raise ::Vident2::DeclarationError,
            "#{name || "anonymous component"} called `no_stimulus_controller` after " \
            "`stimulus do` already recorded DSL entries. Declare `no_stimulus_controller` " \
            "before any `stimulus do` block."
        end
        @__vident2_no_stimulus_controller = true
      end

      def stimulus_controller?
        !@__vident2_no_stimulus_controller
      end

      # `stimulus do ... end` block receiver. Second+ calls append
      # (positional) or last-write-wins (keyed).
      def stimulus(&block)
        call_site = caller_locations(1, 1)&.first
        dsl = ::Vident2::Internals::DSL.new(caller_location: call_site)
        dsl.instance_eval(&block) if block
        fresh = dsl.to_declarations

        if !stimulus_controller? && fresh.any?
          location = call_site ? " at #{call_site.path}:#{call_site.lineno}" : ""
          raise ::Vident2::DeclarationError,
            "#{name || "anonymous component"} declared `no_stimulus_controller` but `stimulus do` emitted DSL entries#{location}. " \
            "A class with no implied controller cannot route DSL entries; drop the `stimulus do` block or remove `no_stimulus_controller`."
        end

        @__vident2_declarations = declarations.merge(fresh).freeze
      end

      # Component-scoped Stimulus event (Symbol, usable directly in `action` DSL).
      def stimulus_scoped_event(event)
        :"#{component_name}:#{event.to_s.camelize(:lower)}"
      end

      def stimulus_scoped_event_on_window(event)
        :"#{component_name}:#{event.to_s.camelize(:lower)}@window"
      end

      # @api private — called by the Ruby VM on subclass definition.
      def inherited(subclass)
        super
        subclass.instance_variable_set(:@__vident2_declarations, declarations)
        subclass.instance_variable_set(
          :@__vident2_no_stimulus_controller,
          instance_variable_get(:@__vident2_no_stimulus_controller) || false
        )
      end
    end

    def prop_names = self.class.prop_names
    def component_name = self.class.component_name
    def stimulus_identifier = self.class.stimulus_identifier

    private def default_controller_path = self.class.stimulus_identifier_path

    def stimulus_scoped_event(event) = self.class.stimulus_scoped_event(event)
    def stimulus_scoped_event_on_window(event) = self.class.stimulus_scoped_event_on_window(event)

    # Auto-id: `<component-name>-<stable-id>`. `.presence` is intentional
    # — blank string falls through to auto-generation.
    def id
      return @id if @id.present?
      @__vident2_auto_id ||= "#{component_name}-#{::Vident::StableId.next_id_in_sequence}"
    end

    # Stable `[identifier, "#<id>"]` pair for connecting an outlet to
    # this instance.
    def outlet_id
      @outlet_id ||= [stimulus_identifier, "##{id}"]
    end

    # Fresh instance with current props merged with overrides.
    def clone(overrides = {})
      self.class.new(**to_h.merge(overrides))
    end

    # Custom format kept for tooling / specs that regex-match output.
    def inspect(klass_name = "Component")
      attr_text = to_h.map { |k, v| "#{k}=#{v.inspect}" }.join(", ")
      "#<#{self.class.name}<Vident::#{klass_name}> #{attr_text}>"
    end

    # Memoised `root_element_attributes`: the user's override runs exactly
    # once (across Resolver + renderer reads).
    private def resolved_root_element_attributes
      return @__vident2_rea if defined?(@__vident2_rea)
      value = root_element_attributes
      @__vident2_rea = value.is_a?(Hash) ? value : {}
    end

    # User override: extra attrs for the root. `stimulus_*:` keys APPEND
    # into the Draft (same as props).
    def root_element_attributes = {}

    # User override: instance-level extra classes for the root (one tier
    # of ClassListBuilder's cascade). Return nil for no contribution.
    def root_element_classes
      nil
    end

    # User hook: runs after the Draft is built but before seal.
    def after_component_initialize
    end

    # Singular parsers return a pre-built value object; pre-built input
    # passes through unchanged.
    SINGULAR_PARSERS = {
      controllers: :stimulus_controller,
      actions:     :stimulus_action,
      targets:     :stimulus_target,
      outlets:     :stimulus_outlet,
      values:      :stimulus_value,
      params:      :stimulus_param,
      class_maps:  :stimulus_class
    }.freeze

    SINGULAR_PARSERS.each do |kind_name, method_name|
      kind = ::Vident2::Internals::Registry.fetch(kind_name)
      define_method(method_name) do |*args|
        return args.first if args.length == 1 && args.first.is_a?(kind.value_class)
        kind.value_class.parse(*args, implied: implied_controller, component_id: id)
      end
    end

    # Plural parsers return a Collection (exposes `#to_h` for `data:`
    # splatting). Inputs: Symbol / String / Array (= singular parser's
    # arg tuple) / Hash (keyed: one pair each) / pre-built Value or
    # Collection (pass-through).
    PLURAL_PARSERS = {
      controllers: :stimulus_controllers,
      actions:     :stimulus_actions,
      targets:     :stimulus_targets,
      outlets:     :stimulus_outlets,
      values:      :stimulus_values,
      params:      :stimulus_params,
      class_maps:  :stimulus_classes
    }.freeze

    PLURAL_PARSERS.each do |kind_name, method_name|
      kind = ::Vident2::Internals::Registry.fetch(kind_name)
      define_method(method_name) do |*args|
        return ::Vident2::Stimulus::Collection.new(kind: kind, items: []) if args.empty? || args.all?(&:nil?)
        return args.first if args.length == 1 && args.first.is_a?(::Vident2::Stimulus::Collection)

        items = []
        args.each do |arg|
          case arg
          when kind.value_class
            items << arg
          when ::Vident2::Stimulus::Collection
            items.concat(arg.items)
          when Hash
            if kind.keyed
              arg.each { |name, val| items << kind.value_class.parse(name, val, implied: implied_controller, component_id: id) }
            else
              items << kind.value_class.parse(arg, implied: implied_controller, component_id: id)
            end
          when Array
            items << kind.value_class.parse(*arg, implied: implied_controller, component_id: id)
          else
            items << kind.value_class.parse(arg, implied: implied_controller, component_id: id)
          end
        end
        ::Vident2::Stimulus::Collection.new(kind: kind, items: items)
      end
    end

    # Mutators. One call = one entry: Array input is the singular
    # parser's arg tuple, NOT splatted across multiple mutator calls.
    MUTATOR_METHODS = {
      controllers: :add_stimulus_controllers,
      actions:     :add_stimulus_actions,
      targets:     :add_stimulus_targets,
      outlets:     :add_stimulus_outlets,
      values:      :add_stimulus_values,
      params:      :add_stimulus_params,
      class_maps:  :add_stimulus_classes
    }.freeze

    # Kind name → `stimulus_<singular>` suffix (used by child_element).
    SINGULAR_NAMES = {
      controllers: :controller,
      actions:     :action,
      targets:     :target,
      outlets:     :outlet,
      values:      :value,
      params:      :param,
      class_maps:  :class
    }.freeze

    MUTATOR_METHODS.each do |kind_name, method_name|
      kind = ::Vident2::Internals::Registry.fetch(kind_name)
      define_method(method_name) do |input|
        raise_if_sealed!
        values = unwrap_mutator_input(kind, input)
        values.each { |v| @__vident2_draft.public_send(:"add_#{kind.name}", v) if v }
        self
      end
    end

    # SSR helper: resolved ClassMap entries matching `names` as a
    # space-joined String. Tailwind-merged if available. `""` on miss.
    def class_list_for_stimulus_classes(*names)
      resolve_stimulus_attributes_at_render_time
      plan = seal_draft
      maps = plan.class_maps
      return "" if maps.empty? || names.empty?

      result = ::Vident2::Internals::ClassListBuilder.call(
        stimulus_classes: maps,
        stimulus_class_names: names,
        tailwind_merger: tailwind_merger
      )
      result || ""
    end

    # Emit a child element with stimulus_* kwargs folded into data-*
    # attrs. Plural kwargs must be Enumerable. Adapter provides the tag
    # emission (`generate_child_element`).
    def child_element(
      tag_name,
      stimulus_controllers: nil,
      stimulus_targets: nil,
      stimulus_actions: nil,
      stimulus_outlets: nil,
      stimulus_values: nil,
      stimulus_params: nil,
      stimulus_classes: nil,
      stimulus_controller: nil,
      stimulus_target: nil,
      stimulus_action: nil,
      stimulus_outlet: nil,
      stimulus_value: nil,
      stimulus_param: nil,
      stimulus_class: nil,
      **options,
      &block
    )
      inputs = {
        controllers: [stimulus_controllers, stimulus_controller],
        actions:     [stimulus_actions, stimulus_action],
        targets:     [stimulus_targets, stimulus_target],
        outlets:     [stimulus_outlets, stimulus_outlet],
        values:      [stimulus_values, stimulus_value],
        params:      [stimulus_params, stimulus_param],
        class_maps:  [stimulus_classes, stimulus_class]
      }

      data_attrs = {}
      ::Vident2::Internals::Registry.each do |kind|
        plural, singular = inputs.fetch(kind.name)
        child_element_check_plural!(plural, singular, kind)
        coll = child_element_build_collection(kind, plural, singular)
        data_attrs.merge!(coll.to_h) unless coll.empty?
      end

      generate_child_element(tag_name, data_attrs, options, &block)
    end

    private

    # Literal callback after props are assigned. Builds the Draft with
    # STATIC entries; DSL procs defer to render (adapter's
    # `before_template` / `before_render` — `view_context` isn't wired yet).
    def after_initialize
      @__vident2_draft = ::Vident2::Internals::Resolver.call(
        self.class.declarations, self, phase: :static
      )
      @stimulus_outlet_host&.add_stimulus_outlets(self)
      after_component_initialize
    end

    public

    # Resolve DSL proc entries deferred at `after_initialize`. Called by
    # the adapter's `before_template` / `before_render`; `seal_draft` and
    # `class_list_for_stimulus_classes` call it as safety nets.
    #
    # Flag set before the guards so a sealed Draft can't trap us in a
    # loop where every subsequent call re-takes the sealed branch.
    def resolve_stimulus_attributes_at_render_time
      return if @__vident2_procs_resolved
      @__vident2_procs_resolved = true
      # Nil = test double. Sealed = someone consumed the Draft already.
      return if @__vident2_draft.nil? || @__vident2_draft.sealed?
      ::Vident2::Internals::Resolver.resolve_procs_into(
        @__vident2_draft, self.class.declarations, self
      )
    end

    private

    def implied_controller
      @__vident2_implied_controller ||= ::Vident2::Stimulus::Controller.new(
        path: self.class.stimulus_identifier_path,
        name: self.class.stimulus_identifier
      )
    end

    # Array input is ONE entry — V2 intentionally does not splat Arrays
    # across entries (mirrors the DSL's plural→singular forwarding).
    def unwrap_mutator_input(kind, input)
      return [] if input.nil?
      return [input] if input.is_a?(kind.value_class)
      return input.items if input.is_a?(::Vident2::Stimulus::Collection)

      if kind.keyed && input.is_a?(Hash)
        return input.map do |name, raw|
          kind.value_class.parse(name, raw, implied: implied_controller, component_id: id)
        end
      end

      args = input.is_a?(Array) ? input : [input]
      [kind.value_class.parse(*args, implied: implied_controller, component_id: id)]
    end

    def raise_if_sealed!
      return unless @__vident2_draft&.sealed?
      raise ::Vident2::StateError,
        "cannot modify stimulus attributes after rendering has begun"
    end

    # Seal Draft and memoise the Plan. Also a safety net for deferred
    # proc resolution when the adapter hook didn't fire.
    def seal_draft
      resolve_stimulus_attributes_at_render_time
      @__vident2_plan ||= @__vident2_draft.seal!
    end

    # Merged root-element attribute Hash for adapters. `overrides` come
    # from `root_element(**overrides)` and win on non-data keys.
    def build_root_element_attributes(overrides)
      plan = seal_draft
      data_attrs = ::Vident2::Internals::AttributeWriter.call(plan)

      extra = resolved_root_element_attributes
      extra_html_options = extra[:html_options] || {}
      extra_class = extra[:classes]
      extra_id = extra[:id]
      extra_data = extra_html_options[:data] || {}

      # data precedence (low→high): Plan fragments → attrs html_options[:data]
      # → instance html_options[:data] → overrides[:data].
      merged_data = data_attrs.dup
      merged_data.merge!(symbolize_keys(extra_data))
      merged_data.merge!(symbolize_keys(@html_options[:data] || {}))
      merged_data.merge!(symbolize_keys(overrides[:data] || {}))

      # 6-tier class-list cascade — see ClassListBuilder.
      class_list = ::Vident2::Internals::ClassListBuilder.call(
        component_name: component_name,
        root_element_classes: root_element_classes,
        root_element_attributes_classes: extra_class,
        root_element_html_class: overrides[:class],
        html_options_class: (@html_options[:class] || extra_html_options[:class]),
        classes_prop: @classes,
        tailwind_merger: tailwind_merger
      )

      merged = {}
      merged.merge!(extra_html_options.except(:data, :class))
      merged.merge!(@html_options.except(:data, :class))
      merged.merge!(overrides.except(:data, :class))
      merged[:class] = class_list if class_list
      merged[:data] = merged_data unless merged_data.empty?
      merged[:id] ||= extra_id || id

      merged
    end

    def symbolize_keys(hash)
      return {} unless hash.is_a?(Hash)
      hash.transform_keys { |k| k.is_a?(String) ? k.to_sym : k }
    end

    def root_element_tag_type
      tag = resolved_root_element_attributes[:element_tag] || @element_tag
      tag.presence&.to_sym || :div
    end

    # --- child_element helpers ------------------------------------------

    def child_element_check_plural!(plural, singular, kind)
      if plural && singular
        raise ArgumentError,
          "'stimulus_#{kind.plural_name}:' and 'stimulus_#{SINGULAR_NAMES.fetch(kind.name)}:' " \
          "are mutually exclusive — pass one or the other."
      end
      return if plural.nil?
      return if plural.is_a?(Enumerable) && !plural.is_a?(Hash)
      return if plural.is_a?(Hash) && kind.keyed
      raise ArgumentError,
        "'stimulus_#{kind.plural_name}:' must be an enumerable. " \
        "Did you mean 'stimulus_#{SINGULAR_NAMES.fetch(kind.name)}:'?"
    end

    # Exactly one of `plural` / `singular` is non-nil; guard above
    # rejects both-set.
    def child_element_build_collection(kind, plural, singular)
      plural_method = :"stimulus_#{kind.plural_name}"
      singular_method = :"stimulus_#{SINGULAR_NAMES.fetch(kind.name)}"

      if plural
        if kind.keyed && plural.is_a?(Hash)
          send(plural_method, plural)
        elsif plural.is_a?(Array)
          send(plural_method, *plural)
        else
          send(plural_method, *Array(plural))
        end
      elsif singular
        coll_items = [send(singular_method, *Array.wrap(singular))]
        ::Vident2::Stimulus::Collection.new(kind: kind, items: coll_items)
      else
        ::Vident2::Stimulus::Collection.new(kind: kind, items: [])
      end
    end

    public

    def root_element(**overrides, &block)
      raise NoMethodError, "subclass must implement root_element"
    end

    # Dispatches to the adapter-specific `root_element` on subclasses
    # (Phlex / ViewComponent). Keep as `def` not `alias_method` so Ruby's
    # dynamic dispatch finds the subclass override.
    def root(...)
      root_element(...)
    end

    # @api private — adapter override point. Phlex: Phlex tag DSL + invalid-
    # tag guard. VC: content_tag / tag.
    def generate_child_element(tag_name, stimulus_data_attributes, options, &block)
      raise NoMethodError, "adapter must implement generate_child_element"
    end
  end
end
