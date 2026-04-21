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
  # Composition root for Vident 2.0 components. Until the capability
  # split lands, this module carries the whole surface directly: props,
  # DSL receiver, singular/plural parsers, add_stimulus_* mutators, and
  # the render pipeline glue.
  module Component
    extend ActiveSupport::Concern

    include ::Vident2::Tailwind

    included do
      extend Literal::Properties

      prop :element_tag, Symbol, default: :div
      prop :id, _Nilable(String)
      prop :classes, _Union(String, _Array(String)), default: -> { [] }
      prop :html_options, Hash, default: -> { {} }

      # Stimulus input props. Each maps onto a Draft via the Resolver at
      # `after_initialize`. Union types mirror V1's (see
      # lib/vident/stimulus_component.rb:44-57) so existing call sites
      # keep working. The controller prop APPENDS to the implied
      # controller (the Resolver always seeds the implied first unless
      # the class opted out via `no_stimulus_controller`).
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

      # Eager inheritance: start from parent's frozen Declarations so
      # every subclass sees its ancestors' DSL effect without calling
      # anything. `inherited` below then keeps the chain building.
      @__vident2_declarations = ::Vident2::Internals::Declarations.empty
      @__vident2_no_stimulus_controller = false
    end

    class_methods do
      def prop_names
        literal_properties.properties_index.keys.map(&:to_sym)
      end

      # Underscored class path: `Admin::UserCardComponent` → `admin/user_card_component`.
      # Anonymous classes fall back to a stable placeholder so DSL/renderer
      # code doesn't nil-crash in fixtures.
      def stimulus_identifier_path
        name&.underscore || "anonymous_component"
      end

      # Kebab-cased, `--`-separated identifier — the string that appears
      # in `data-controller` and as the implicit class on the root.
      def stimulus_identifier
        stimulus_identifier_path.split("/").map(&:dasherize).join("--")
      end

      def component_name
        @component_name ||= stimulus_identifier
      end

      # Frozen aggregate of everything the DSL declared on this class
      # and its ancestors. Always non-nil (may be `Declarations.empty`).
      def declarations
        @__vident2_declarations ||= ::Vident2::Internals::Declarations.empty
      end

      # Suppresses the implied controller. A `stimulus do` block after
      # this call with any entry raises `DeclarationError` — the
      # resolver has no controller to route entries through.
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

      # Block receiver for `stimulus do ... end`. Runs the block against
      # a fresh DSL instance, then merges the resulting Declarations
      # into the class-level aggregate. Calling twice APPENDS (positional
      # kinds) or LAST-WRITE-WINS (keyed kinds).
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

      # Format a component-scoped Stimulus event for cross-component
      # dispatch. Returns a Symbol (callable directly in `action` DSL).
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

    # The underscored class path used to build the implied controller.
    private def default_controller_path = self.class.stimulus_identifier_path

    def stimulus_scoped_event(event) = self.class.stimulus_scoped_event(event)
    def stimulus_scoped_event_on_window(event) = self.class.stimulus_scoped_event_on_window(event)

    # Auto-id format: "<component-name>-<stable-id>". Users can override
    # via the `id:` prop at construction; blank string falls through to
    # auto-generation (`.presence` is intentional, not `nil?`).
    def id
      return @id if @id.present?
      @__vident2_auto_id ||= "#{component_name}-#{::Vident::StableId.next_id_in_sequence}"
    end

    # If connecting an outlet to a specific instance, use this pair.
    # Memoised — the `"#<id>"` form is stable across calls.
    def outlet_id
      @outlet_id ||= [stimulus_identifier, "##{id}"]
    end

    # Return a fresh instance with the current prop-hash merged with
    # overrides. Literal-backed props expose `#to_h`; rely on that.
    def clone(overrides = {})
      self.class.new(**to_h.merge(overrides))
    end

    # Custom inspect mirroring v1's format so tooling / specs that
    # regex-match the output keep working. Default klass_name label is
    # "Component" (kept for tooling / specs that regex-match output).
    def inspect(klass_name = "Component")
      attr_text = to_h.map { |k, v| "#{k}=#{v.inspect}" }.join(", ")
      "#<#{self.class.name}<Vident::#{klass_name}> #{attr_text}>"
    end

    # Memoised view of `root_element_attributes`. Called by the Resolver
    # at init and by `build_root_element_attributes` / `root_element_tag_type`
    # at render — must return the same Hash across all sites, so the
    # user's `root_element_attributes` override runs exactly once.
    private def resolved_root_element_attributes
      return @__vident2_rea if defined?(@__vident2_rea)
      value = root_element_attributes
      @__vident2_rea = value.is_a?(Hash) ? value : {}
    end

    # User override point: returns extra attributes to fold into the root
    # element at render time. Returning a Hash with `stimulus_*:` keys
    # APPENDS those into the Draft (same merge semantic as the props).
    def root_element_attributes = {}

    # User override point: instance-level extra classes for the root. One
    # of four tiers in the cascade (see ClassListBuilder). Returning nil
    # means "don't contribute"; any String / Array-of-String is folded in.
    def root_element_classes
      nil
    end

    # User hook: runs after the Draft is built but before seal. May call
    # `add_stimulus_*` to append entries conditionally.
    def after_component_initialize
    end

    # Singular parsers `stimulus_<singular>(*args)` return a pre-built
    # value object. Pre-built value input passes through unchanged.
    # Method names (hardcoded for clarity over regex gymnastics):
    #   stimulus_controller / _action / _target / _outlet /
    #   _value / _param / _class
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

    # Plural parsers `stimulus_<plural>(*args)` return a Collection wrapper
    # exposing `#to_h` (for splatting into a `data:` option).
    #
    # Input shapes: Symbol / String (bare names), Array (splatted as the
    # singular parser's arg tuple), Hash (for keyed kinds: one pair each;
    # for non-keyed kinds: a single descriptor), pre-built Value
    # (pass-through), pre-built Collection (pass-through).
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

    # Mutators `add_stimulus_<plural>(input)`. One call = one logical
    # entry — Array input is the entry's argument tuple passed to the
    # singular parser, NOT splatted across multiple mutator calls.
    MUTATOR_METHODS = {
      controllers: :add_stimulus_controllers,
      actions:     :add_stimulus_actions,
      targets:     :add_stimulus_targets,
      outlets:     :add_stimulus_outlets,
      values:      :add_stimulus_values,
      params:      :add_stimulus_params,
      class_maps:  :add_stimulus_classes
    }.freeze

    # Maps an internal kind name to the `stimulus_<singular>` method /
    # `stimulus_<singular>:` kwarg. Used by child_element's error paths
    # and plural-vs-singular routing.
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

    # SSR helper: resolves the component's declared ClassMap entries
    # whose `name` matches `names` into a space-joined String, running
    # through Tailwind merge when available. Returns "" for no matches
    # so users can inline it directly.
    def class_list_for_stimulus_classes(*names)
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

    # Emit a child element's opening tag + data attributes + block content.
    # Child-element builder: 7 singular + 7 plural stimulus
    # kwargs. Plural kwargs must be Enumerable. Delegates the actual tag
    # emission to the adapter's `generate_child_element` (Phlex vs VC).
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

    # Literal callback — runs after props are assigned. Build the Draft,
    # register on outlet host if present, then invoke the user hook.
    def after_initialize
      @__vident2_draft = ::Vident2::Internals::Resolver.call(
        self.class.declarations, self
      )
      @stimulus_outlet_host&.add_stimulus_outlets(self)
      after_component_initialize
    end

    # Implied controller used by singular parsers + add_stimulus_*.
    def implied_controller
      @__vident2_implied_controller ||= ::Vident2::Stimulus::Controller.new(
        path: self.class.stimulus_identifier_path,
        name: self.class.stimulus_identifier
      )
    end

    # Decompose mutator input into 0+ parsed entries. Pre-built Value /
    # Collection pass through (Collection unwraps to its items). Hash
    # input for keyed kinds fans out one entry per pair. Array input is
    # ONE entry (gotcha: V2 intentionally does not splat Arrays across
    # multiple entries — mirrors the DSL's plural-forwarding shape).
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

    # Seal Draft and memoise the Plan. First caller wins; subsequent
    # calls return the same Plan object.
    def seal_draft
      @__vident2_plan ||= @__vident2_draft.seal!
    end

    # Builds the merged root-element attribute Hash for adapters.
    # Accepts `overrides` from `root_element(**overrides)` (highest
    # precedence for non-data keys) and folds data-* from the Plan.
    def build_root_element_attributes(overrides)
      plan = seal_draft
      data_attrs = ::Vident2::Internals::AttributeWriter.call(plan)

      extra = resolved_root_element_attributes
      extra_html_options = extra[:html_options] || {}
      extra_class = extra[:classes]
      extra_id = extra[:id]
      extra_data = extra_html_options[:data] || {}

      # data merge: Plan fragments first (lowest), then root_element_attributes[:html_options][:data],
      # then instance html_options[:data], then overrides[:data] (highest).
      merged_data = data_attrs.dup
      merged_data.merge!(symbolize_keys(extra_data))
      merged_data.merge!(symbolize_keys(@html_options[:data] || {}))
      merged_data.merge!(symbolize_keys(overrides[:data] || {}))

      # 6-tier class list precedence — see ClassListBuilder for the
      # full description. Here we marshal the tiers out of the various
      # sources (instance method, attrs Hash, template kwarg, prop).
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

    # Build a Collection for one kind from the (plural, singular) pair.
    # Exactly one of `plural` / `singular` is non-nil (the guard above
    # rejects both-set).
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
