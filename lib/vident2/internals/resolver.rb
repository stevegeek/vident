# frozen_string_literal: true

require_relative "registry"
require_relative "draft"

module Vident2
  module Internals
    # @api private
    # Resolves Declarations + instance state into a Draft of typed
    # Stimulus::* values. The implied controller seeds first (unless
    # `no_stimulus_controller`); prop and root_element_attributes paths
    # both APPEND.
    #
    # Two entry points:
    #   `call`               — pure; returns a new Draft. Use `:static` or `:all`.
    #   `resolve_procs_into` — mutates an existing Draft. Called at render
    #                          time so DSL procs can reach `helpers` /
    #                          `view_context` (not wired at `after_initialize`).
    #
    # Phases: `:static` skips anything with a `when_proc` or top-level Proc
    # in args; `:procs` processes only those; `:all` does everything.
    #
    # Procs nested inside a Hash descriptor (`action(method: -> { ... })`)
    # escape the gate — unsupported shape; use the fluent builder or a
    # top-level Proc.
    module Resolver
      module_function

      def call(declarations, instance, phase: :all)
        raise ArgumentError, "use resolve_procs_into for phase: :procs" if phase == :procs

        draft = Draft.new
        implied = build_implied_controller(instance)

        seed_implied_controller(draft, instance)
        resolve_declarations(draft, declarations, instance, implied, phase: phase)
        absorb_stimulus_props(draft, instance, implied, phase: phase)
        absorb_root_element_attributes(draft, instance, implied, phase: phase)

        draft
      end

      # Caller owns idempotence (Component uses `@__vident2_procs_resolved`).
      def resolve_procs_into(draft, declarations, instance)
        implied = build_implied_controller(instance)
        resolve_declarations(draft, declarations, instance, implied, phase: :procs)
        absorb_stimulus_props(draft, instance, implied, phase: :procs)
        absorb_root_element_attributes(draft, instance, implied, phase: :procs)
        draft
      end

      def build_implied_controller(instance)
        path = instance.class.stimulus_identifier_path
        name = instance.class.stimulus_identifier
        ::Vident2::Stimulus::Controller.new(path: path, name: name)
      end

      def seed_implied_controller(draft, instance)
        return unless instance.class.stimulus_controller?
        draft.add_controllers(build_implied_controller(instance))
      end

      def resolve_declarations(draft, declarations, instance, implied, phase:)
        resolve_positional(draft, :controllers, declarations.controllers, instance, phase: phase) do |args, meta, _inst|
          ::Vident2::Stimulus::Controller.parse(*args, implied: implied, **meta_for_controller(meta))
        end

        resolve_positional(draft, :actions, declarations.actions, instance, phase: phase) do |args, _meta, _inst|
          parse_single(::Vident2::Stimulus::Action, args, implied: implied, component_id: instance_id(instance))
        end

        resolve_positional(draft, :targets, declarations.targets, instance, phase: phase) do |args, _meta, _inst|
          parse_single(::Vident2::Stimulus::Target, args, implied: implied, component_id: instance_id(instance))
        end

        resolve_keyed(draft, :outlets, declarations.outlets, instance, phase: phase) do |key, args, _meta|
          parsed_args = [key_for_parse(key), *args]
          parse_single(::Vident2::Stimulus::Outlet, parsed_args, implied: implied, component_id: instance_id(instance))
        end

        resolve_keyed_values(draft, declarations, instance, implied, phase: phase)
        resolve_keyed_scalars(draft, :params, declarations.params, instance, implied, ::Vident2::Stimulus::Param, phase: phase)
        resolve_keyed_scalars(draft, :class_maps, declarations.class_maps, instance, implied, ::Vident2::Stimulus::ClassMap, phase: phase)
      end

      def resolve_positional(draft, kind, entries, instance, phase:)
        entries.each do |decl|
          next unless phase_matches?(decl, phase)
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
        (args.size == 1 && args[0].is_a?(Array)) ? args[0] : args
      end

      def resolve_keyed(draft, kind, entries, instance, phase:)
        entries.each do |(key, decl)|
          next unless phase_matches?(decl, phase)
          next if gated_out?(decl.when_proc, instance)
          args = resolve_args(decl.args, instance)
          next if args.nil?
          parsed = yield(key, args, decl.meta)
          draft.public_send(:"add_#{kind}", parsed) if parsed
        end
      end

      def resolve_keyed_values(draft, declarations, instance, implied, phase:)
        declarations.values.each do |(key, decl)|
          next unless phase_matches?(decl, phase)
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

        # values_from_props is a plain Symbol list (no Declarations, so
        # phase_matches? doesn't apply). Ivar reads only; run once.
        return if phase == :procs
        declarations.values_from_props.each do |name|
          raw = read_prop(instance, name)
          next if raw.nil?
          draft.add_values(::Vident2::Stimulus::Value.parse(name, raw, implied: implied))
        end
      end

      def resolve_keyed_scalars(draft, kind, entries, instance, implied, value_class, phase:)
        entries.each do |(key, decl)|
          next unless phase_matches?(decl, phase)
          next if gated_out?(decl.when_proc, instance)
          raw = resolve_value_meta(decl, instance)
          next if raw.nil?
          draft.public_send(:"add_#{kind}", value_class.parse(key, raw, implied: implied))
        end
      end

      # Declaration-level phase gate. Nested Procs inside Hash args
      # aren't inspected — see module docstring.
      def phase_matches?(decl, phase)
        return true if phase == :all
        has_proc = decl.when_proc || decl.args.any? { |a| a.is_a?(Proc) }
        (phase == :procs) ? has_proc : !has_proc
      end

      def absorb_stimulus_props(draft, instance, implied, phase:)
        absorb_input(draft, :controllers, instance_ivar(instance, :@stimulus_controllers), instance, implied, phase: phase)
        absorb_input(draft, :actions,     instance_ivar(instance, :@stimulus_actions),     instance, implied, phase: phase)
        absorb_input(draft, :targets,     instance_ivar(instance, :@stimulus_targets),     instance, implied, phase: phase)
        absorb_input(draft, :outlets,     instance_ivar(instance, :@stimulus_outlets),     instance, implied, phase: phase)
        absorb_input(draft, :values,      instance_ivar(instance, :@stimulus_values),      instance, implied, phase: phase)
        absorb_input(draft, :params,      instance_ivar(instance, :@stimulus_params),      instance, implied, phase: phase)
        absorb_input(draft, :class_maps,  instance_ivar(instance, :@stimulus_classes),     instance, implied, phase: phase)
      end

      def absorb_root_element_attributes(draft, instance, implied, phase:)
        return unless instance.respond_to?(:resolved_root_element_attributes, true)
        attrs = instance.send(:resolved_root_element_attributes)
        return unless attrs.is_a?(Hash) && !attrs.empty?

        absorb_input(draft, :controllers, attrs[:stimulus_controllers], instance, implied, phase: phase)
        absorb_input(draft, :actions,     attrs[:stimulus_actions],     instance, implied, phase: phase)
        absorb_input(draft, :targets,     attrs[:stimulus_targets],     instance, implied, phase: phase)
        absorb_input(draft, :outlets,     attrs[:stimulus_outlets],     instance, implied, phase: phase)
        absorb_input(draft, :values,      attrs[:stimulus_values],      instance, implied, phase: phase)
        absorb_input(draft, :params,      attrs[:stimulus_params],      instance, implied, phase: phase)
        absorb_input(draft, :class_maps,  attrs[:stimulus_classes],     instance, implied, phase: phase)
      end

      # Fold a prop / root_element_attributes value into the Draft.
      # Each Hash value / Array element may be a Proc; phase-gated.
      def absorb_input(draft, kind, input, instance, implied, phase:)
        return if input.nil?

        kind_meta = Registry.fetch(kind)
        case input
        when Hash
          input.each do |key, raw|
            is_proc = raw.is_a?(Proc)
            next unless phase_allows?(is_proc, phase)
            absorbed = is_proc ? instance.instance_exec(&raw) : raw
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
            is_proc = entry.is_a?(Proc)
            next unless phase_allows?(is_proc, phase)
            parsed = absorb_one(kind_meta, entry, instance, implied)
            draft.public_send(:"add_#{kind}", parsed) if parsed
          end
        else
          is_proc = input.is_a?(Proc)
          return unless phase_allows?(is_proc, phase)
          parsed = absorb_one(kind_meta, input, instance, implied)
          draft.public_send(:"add_#{kind}", parsed) if parsed
        end
      end

      # Element-level gate (raw boolean; parallels Declaration-level `phase_matches?`).
      def phase_allows?(is_proc, phase)
        case phase
        when :all    then true
        when :static then !is_proc
        when :procs  then is_proc
        end
      end

      def absorb_one(kind_meta, entry, instance, implied)
        entry = instance.instance_exec(&entry) if entry.is_a?(Proc)
        return nil if entry.nil?
        return entry if entry.is_a?(kind_meta.value_class)

        parse_entry(kind_meta, entry, implied: implied, component_id: instance_id(instance))
      end

      def parse_entry(kind_meta, entry, implied:, component_id:)
        case entry
        when Hash
          if kind_meta.keyed
            first_key, first_val = entry.first
            kind_meta.value_class.parse(first_key, first_val, implied: implied, component_id: component_id)
          else
            kind_meta.value_class.parse(entry, implied: implied, component_id: component_id)
          end
        when Array
          kind_meta.value_class.parse(*entry, implied: implied, component_id: component_id)
        else
          kind_meta.value_class.parse(entry, implied: implied, component_id: component_id)
        end
      end

      # Evaluate proc args in the instance binding. Only nil drops —
      # false / blank strings / empty collections reach the parser.
      def resolve_args(args, instance)
        resolved = args.map { |arg| arg.is_a?(Proc) ? instance.instance_exec(&arg) : arg }
        return nil if resolved.any?(&:nil?)
        resolved
      end

      # Values accept the raw in args (proc or literal) or meta (`static:`).
      def resolve_value_meta(decl, instance)
        return decl.meta[:static] if decl.meta.key?(:static)
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

      def key_for_parse(key) = key

      # Controller parse takes `as:` as a kwarg, not a positional.
      def meta_for_controller(meta) = meta.slice(:as)

      def instance_ivar(instance, name)
        return nil unless instance.instance_variable_defined?(name)
        instance.instance_variable_get(name)
      end

      # Raw ivar — calling `#id` would trigger auto-generation, and
      # outlet auto-selectors include the `#<id>` prefix only when the
      # user explicitly set one.
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
