# frozen_string_literal: true

require_relative "registry"
require_relative "draft"

module Vident2
  module Internals
    # @api private
    # Pure function: (Declarations, instance) -> Draft.
    #
    # Resolves class-level DSL entries into typed Stimulus::* value objects,
    # evaluating procs in the instance binding, reading props for
    # `values_from_props`, and absorbing `stimulus_*:` entries from the
    # instance's props + `root_element_attributes`. The Draft comes back
    # with the implied controller already seeded (unless the class has
    # `no_stimulus_controller`); both the prop and root_element_attributes
    # controller paths APPEND to the implied rather than replace it.
    module Resolver
      module_function

      # Build a fresh Draft for `instance` from its class's frozen
      # Declarations and its instance state. Does not mutate `instance`.
      def call(declarations, instance)
        draft = Draft.new
        implied = build_implied_controller(instance)

        seed_implied_controller(draft, instance, implied)
        resolve_declarations(draft, declarations, instance, implied)
        absorb_stimulus_props(draft, instance, implied)
        absorb_root_element_attributes(draft, instance, implied)

        draft
      end

      # Implied controller for a component is its own class's stimulus
      # identifier (e.g. `ButtonComponent` -> `"button_component"` /
      # `"button-component"`). `no_stimulus_controller` classes get a Null
      # placeholder — the Resolver won't seed it, but value classes that
      # parse with `implied:` can still reference one if a user writes a
      # qualified entry that doesn't need it.
      def build_implied_controller(instance)
        path = instance.class.stimulus_identifier_path
        name = instance.class.stimulus_identifier
        ::Vident2::Stimulus::Controller.new(path: path, name: name)
      end

      # The implied controller always appears as the FIRST controller on
      # the Draft unless the class opted out via `no_stimulus_controller`.
      # prop and root_element_attributes inputs append after it.
      def seed_implied_controller(draft, instance, implied)
        return unless instance.class.stimulus_controller?
        draft.add_controllers(implied)
      end

      def resolve_declarations(draft, declarations, instance, implied)
        resolve_positional(draft, :controllers, declarations.controllers, instance, implied) do |args, meta, _inst|
          ::Vident2::Stimulus::Controller.parse(*args, implied: implied, **meta_for_controller(meta))
        end

        resolve_positional(draft, :actions, declarations.actions, instance, implied) do |args, _meta, _inst|
          parse_single(::Vident2::Stimulus::Action, args, implied: implied, component_id: instance_id(instance))
        end

        resolve_positional(draft, :targets, declarations.targets, instance, implied) do |args, _meta, _inst|
          parse_single(::Vident2::Stimulus::Target, args, implied: implied, component_id: instance_id(instance))
        end

        resolve_keyed(draft, :outlets, declarations.outlets, instance, implied) do |key, args, _meta|
          parsed_args = [key_for_parse(key), *args]
          parse_single(::Vident2::Stimulus::Outlet, parsed_args, implied: implied, component_id: instance_id(instance))
        end

        resolve_keyed_values(draft, declarations, instance, implied)
        resolve_keyed_scalars(draft, :params, declarations.params, instance, implied, ::Vident2::Stimulus::Param)
        resolve_keyed_scalars(draft, :class_maps, declarations.class_maps, instance, implied, ::Vident2::Stimulus::ClassMap)
      end

      # Positional kinds: each Declaration contributes one entry. A proc
      # that resolves to `[sym, :method]` splats into the singular parser
      # (matches V1's plural→singular forwarding); the DSL already splats
      # Array-literal input.
      def resolve_positional(draft, kind, entries, instance, _implied)
        entries.each do |decl|
          next if gated_out?(decl.when_proc, instance)
          args = resolve_args(decl.args, instance)
          next if args.nil?
          args = splat_single_array(args)
          parsed = yield(args, decl.meta, instance)
          draft.public_send(:"add_#{kind}", parsed) if parsed
        end
      end

      # If `args` is a single Array element, unwrap it — positional kinds
      # treat Array values as the singular parser's arg tuple.
      def splat_single_array(args)
        if args.size == 1 && args[0].is_a?(Array)
          args[0]
        else
          args
        end
      end

      # Keyed kinds (outlets): positional shape is `[key, Declaration]`;
      # the Declaration's args are what follow the key.
      def resolve_keyed(draft, kind, entries, instance, _implied)
        entries.each do |(key, decl)|
          next if gated_out?(decl.when_proc, instance)
          args = resolve_args(decl.args, instance)
          next if args.nil?
          parsed = yield(key, args, decl.meta)
          draft.public_send(:"add_#{kind}", parsed) if parsed
        end
      end

      # Values have `from_prop:` / `static:` meta paths in addition to
      # normal proc/literal resolution.
      def resolve_keyed_values(draft, declarations, instance, implied)
        declarations.values.each do |(key, decl)|
          next if gated_out?(decl.when_proc, instance)

          if decl.meta[:from_prop]
            raw = read_prop(instance, key)
            next if raw.nil?
            draft.add_values(::Vident2::Stimulus::Value.parse(key, raw, implied: implied))
            next
          end

          raw = resolve_value_meta(decl, instance)
          next if raw.nil?
          draft.add_values(::Vident2::Stimulus::Value.parse(key, raw, implied: implied))
        end

        declarations.values_from_props.each do |name|
          raw = read_prop(instance, name)
          next if raw.nil?
          draft.add_values(::Vident2::Stimulus::Value.parse(name, raw, implied: implied))
        end
      end

      # Params and class_maps share the same "one raw arg per key" shape.
      def resolve_keyed_scalars(draft, kind, entries, instance, implied, value_class)
        entries.each do |(key, decl)|
          next if gated_out?(decl.when_proc, instance)
          raw = resolve_value_meta(decl, instance)
          next if raw.nil?
          draft.public_send(:"add_#{kind}", value_class.parse(key, raw, implied: implied))
        end
      end

      # Instance-side Resolver inputs: stimulus_* props at .new(). These
      # are concatenated AFTER the implied controller and declaration
      # entries — prop path and attrs path share the same merge semantic.
      def absorb_stimulus_props(draft, instance, implied)
        absorb_input(draft, :controllers, instance_ivar(instance, :@stimulus_controllers), instance, implied)
        absorb_input(draft, :actions,     instance_ivar(instance, :@stimulus_actions),     instance, implied)
        absorb_input(draft, :targets,     instance_ivar(instance, :@stimulus_targets),     instance, implied)
        absorb_input(draft, :outlets,     instance_ivar(instance, :@stimulus_outlets),     instance, implied)
        absorb_input(draft, :values,      instance_ivar(instance, :@stimulus_values),      instance, implied)
        absorb_input(draft, :params,      instance_ivar(instance, :@stimulus_params),      instance, implied)
        absorb_input(draft, :class_maps,  instance_ivar(instance, :@stimulus_classes),     instance, implied)
      end

      # root_element_attributes is a Hash users override to add attrs at
      # render time. Its stimulus_* keys merge into the Draft like the
      # props — same unified append semantic.
      def absorb_root_element_attributes(draft, instance, implied)
        return unless instance.respond_to?(:resolved_root_element_attributes, true)
        attrs = instance.send(:resolved_root_element_attributes)
        return unless attrs.is_a?(Hash) && !attrs.empty?

        absorb_input(draft, :controllers, attrs[:stimulus_controllers], instance, implied)
        absorb_input(draft, :actions,     attrs[:stimulus_actions],     instance, implied)
        absorb_input(draft, :targets,     attrs[:stimulus_targets],     instance, implied)
        absorb_input(draft, :outlets,     attrs[:stimulus_outlets],     instance, implied)
        absorb_input(draft, :values,      attrs[:stimulus_values],      instance, implied)
        absorb_input(draft, :params,      attrs[:stimulus_params],      instance, implied)
        absorb_input(draft, :class_maps,  attrs[:stimulus_classes],     instance, implied)
      end

      # Input from props / root_element_attributes is always an enumerable
      # or keyed Hash in V2 (the prop types enforce it). Each element is
      # one entry: Symbol, String, Array (= single entry's args tuple),
      # Hash (for values/params/classes/outlets as kwargs), pre-built value.
      def absorb_input(draft, kind, input, instance, implied)
        return if input.nil?

        kind_meta = Registry.fetch(kind)
        case input
        when Hash
          input.each do |key, raw|
            absorbed = raw.is_a?(Proc) ? instance.instance_exec(&raw) : raw
            next if absorbed.nil?
            if kind_meta.keyed
              parsed = kind_meta.value_class.parse(key, absorbed, implied: implied, component_id: instance_id(instance))
              draft.public_send(:"add_#{kind}", parsed)
            else
              parsed = parse_entry(kind_meta, [key, absorbed], implied: implied, component_id: instance_id(instance))
              draft.public_send(:"add_#{kind}", parsed) if parsed
            end
          end
        when Array
          input.each do |entry|
            parsed = absorb_one(kind_meta, entry, instance, implied)
            draft.public_send(:"add_#{kind}", parsed) if parsed
          end
        else
          parsed = absorb_one(kind_meta, input, instance, implied)
          draft.public_send(:"add_#{kind}", parsed) if parsed
        end
      end

      # Single entry from a prop Array: Symbol / String / Array /
      # pre-built value / Hash (for keyed kinds that arrive as one Hash
      # per prop element).
      def absorb_one(kind_meta, entry, instance, implied)
        entry = instance.instance_exec(&entry) if entry.is_a?(Proc)
        return nil if entry.nil?
        return entry if entry.is_a?(kind_meta.value_class)

        parse_entry(kind_meta, entry, implied: implied, component_id: instance_id(instance))
      end

      def parse_entry(kind_meta, entry, implied:, component_id:)
        case entry
        when Hash
          # Hash entry for a keyed kind arriving directly: unwrap
          # {name => raw} pairs.
          if kind_meta.keyed
            first_key, first_val = entry.first
            kind_meta.value_class.parse(first_key, first_val, implied: implied, component_id: component_id)
          else
            # Hash for a positional kind (e.g. action descriptor) — pass through.
            kind_meta.value_class.parse(entry, implied: implied, component_id: component_id)
          end
        when Array
          kind_meta.value_class.parse(*entry, implied: implied, component_id: component_id)
        else
          kind_meta.value_class.parse(entry, implied: implied, component_id: component_id)
        end
      end

      # Declaration arg tuples may contain Procs; evaluate in instance
      # binding. Only nil drops — false / blank strings / empty collections
      # survive and reach the parser.
      def resolve_args(args, instance)
        resolved = args.map do |arg|
          if arg.is_a?(Proc)
            instance.instance_exec(&arg)
          else
            arg
          end
        end
        # If any proc resolved to nil, drop the whole entry.
        return nil if resolved.any?(&:nil?)
        resolved
      end

      # Value-kind Declarations carry the raw in either args (proc or
      # literal) or meta (`static:`). Returns the raw value to pass to
      # `Value.parse(name, raw)`, or nil to drop.
      def resolve_value_meta(decl, instance)
        if decl.meta.key?(:static)
          return decl.meta[:static]
        end

        return nil if decl.args.empty?

        raw = decl.args.first
        raw = instance.instance_exec(&raw) if raw.is_a?(Proc)
        raw
      end

      def gated_out?(when_proc, instance)
        return false unless when_proc
        !instance.instance_exec(&when_proc)
      end

      def parse_single(value_class, args, implied:, component_id:)
        value_class.parse(*args, implied: implied, component_id: component_id)
      end

      # Keys stored in keyed entries may be Symbol or String (latter for
      # namespaced identifiers like `"admin--users"`). Parsers accept
      # either; no conversion needed.
      def key_for_parse(key) = key

      # Controller parse takes `as:` as a kwarg, not a positional. Split
      # it out of the declaration's meta Hash.
      def meta_for_controller(meta) = meta.slice(:as)

      def instance_ivar(instance, name)
        return nil unless instance.instance_variable_defined?(name)
        instance.instance_variable_get(name)
      end

      # Read the raw @id ivar directly — calling `#id` would trigger
      # auto-generation, and outlet auto-selectors intentionally include
      # the `#<id> ` prefix only when the user has explicitly set one.
      def instance_id(instance)
        return nil unless instance.instance_variable_defined?(:@id)
        raw = instance.instance_variable_get(:@id)
        raw.presence
      end

      def read_prop(instance, name)
        ivar = :"@#{name}"
        return nil unless instance.instance_variable_defined?(ivar)
        instance.instance_variable_get(ivar)
      end
    end
  end
end
