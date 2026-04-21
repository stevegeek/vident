# frozen_string_literal: true

require_relative "registry"
require_relative "draft"

module Vident
  module Internals
    # Resolves raw Declarations and instance state into a Draft of typed Stimulus values.
    # Phase `:static` skips proc-bearing entries; `:procs` processes only those; `:all` does both.
    # Procs nested inside a Hash descriptor escape the phase gate — use the fluent builder instead.
    module Resolver
      module_function

      def call(declarations, instance, phase: :all)
        raise ArgumentError, "use resolve_procs_into for phase: :procs" if phase == :procs

        draft = Draft.new
        implied = build_implied_controller(instance)
        alias_map = build_alias_map(declarations)

        seed_implied_controller(draft, instance)
        resolve_declarations(draft, declarations, instance, implied, phase:, alias_map:)
        absorb_stimulus_props(draft, instance, implied, phase:, alias_map:)
        absorb_root_element_attributes(draft, instance, implied, phase:, alias_map:)

        draft
      end

      def resolve_procs_into(draft, declarations, instance)
        implied = build_implied_controller(instance)
        alias_map = build_alias_map(declarations)
        resolve_declarations(draft, declarations, instance, implied, phase: :procs, alias_map:)
        absorb_stimulus_props(draft, instance, implied, phase: :procs, alias_map:)
        absorb_root_element_attributes(draft, instance, implied, phase: :procs, alias_map:)
        draft
      end

      def build_alias_map(declarations)
        map = {}
        declarations.controllers.each do |decl|
          alias_name = decl.meta[:as]
          next unless alias_name
          raw_path = decl.args.first
          next if raw_path.nil?
          map[alias_name] = raw_path.to_s
        end
        map
      end

      def build_implied_controller(instance)
        path = instance.class.stimulus_identifier_path
        name = instance.class.stimulus_identifier
        ::Vident::Stimulus::Controller.new(path: path, name: name)
      end

      def seed_implied_controller(draft, instance)
        return unless instance.class.stimulus_controller?
        draft.add_controllers(build_implied_controller(instance))
      end

      def resolve_declarations(draft, declarations, instance, implied, phase:, alias_map: {})
        resolve_positional(draft, :controllers, declarations.controllers, instance, phase:) do |args, meta, _inst|
          ::Vident::Stimulus::Controller.parse(*args, implied: implied, **meta_for_controller(meta))
        end

        resolve_positional(draft, :actions, declarations.actions, instance, phase:) do |args, _meta, _inst|
          parse_single(::Vident::Stimulus::Action, resolve_action_aliases(args, alias_map), implied: implied, component_id: instance_id(instance))
        end

        resolve_positional(draft, :targets, declarations.targets, instance, phase:) do |args, _meta, _inst|
          parse_single(::Vident::Stimulus::Target, args, implied: implied, component_id: instance_id(instance))
        end

        resolve_keyed(draft, :outlets, declarations.outlets, instance, phase:) do |key, args, _meta|
          parsed_args = [key_for_parse(key), *args]
          parse_single(::Vident::Stimulus::Outlet, parsed_args, implied: implied, component_id: instance_id(instance))
        end

        resolve_keyed_values(draft, declarations, instance, implied, phase:)
        resolve_keyed_scalars(draft, :params, declarations.params, instance, implied, ::Vident::Stimulus::Param, phase:)
        resolve_keyed_scalars(draft, :class_maps, declarations.class_maps, instance, implied, ::Vident::Stimulus::ClassMap, phase:)
      end

      # Unknown aliases raise — a symbolic controller ref is declared intent, not a guess.
      def resolve_action_aliases(args, alias_map)
        return args if alias_map.empty?
        args.map do |arg|
          next arg unless arg.is_a?(Hash) && arg[:controller].is_a?(Symbol)
          sym = arg[:controller]
          unless alias_map.key?(sym)
            raise ::Vident::DeclarationError, "Unknown controller alias :#{sym} in action. Declared aliases: #{alias_map.keys.inspect}"
          end
          arg.merge(controller: alias_map[sym])
        end
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
            draft.add_values(::Vident::Stimulus::Value.parse(key, raw, implied: implied))
            next
          end

          raw = resolve_value_meta(decl, instance)
          next if raw.nil?
          draft.add_values(::Vident::Stimulus::Value.parse(key, raw, implied: implied))
        end

        # values_from_props has no when_proc, so phase_matches? doesn't apply; skip on :procs pass.
        return if phase == :procs
        declarations.values_from_props.each do |name|
          raw = read_prop(instance, name)
          next if raw.nil?
          draft.add_values(::Vident::Stimulus::Value.parse(name, raw, implied: implied))
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

      def phase_matches?(decl, phase)
        return true if phase == :all
        has_proc = decl.when_proc || decl.args.any? { |a| a.is_a?(Proc) }
        (phase == :procs) ? has_proc : !has_proc
      end

      def absorb_stimulus_props(draft, instance, implied, phase:, alias_map: {})
        absorb_input(draft, :controllers, instance_ivar(instance, :@stimulus_controllers), instance, implied, phase:, alias_map:)
        absorb_input(draft, :actions, instance_ivar(instance, :@stimulus_actions), instance, implied, phase:, alias_map:)
        absorb_input(draft, :targets, instance_ivar(instance, :@stimulus_targets), instance, implied, phase:, alias_map:)
        absorb_input(draft, :outlets, instance_ivar(instance, :@stimulus_outlets), instance, implied, phase:, alias_map:)
        absorb_input(draft, :values, instance_ivar(instance, :@stimulus_values), instance, implied, phase:, alias_map:)
        absorb_input(draft, :params, instance_ivar(instance, :@stimulus_params), instance, implied, phase:, alias_map:)
        absorb_input(draft, :class_maps, instance_ivar(instance, :@stimulus_classes), instance, implied, phase:, alias_map:)
      end

      def absorb_root_element_attributes(draft, instance, implied, phase:, alias_map: {})
        return unless instance.respond_to?(:resolved_root_element_attributes, true)
        attrs = instance.send(:resolved_root_element_attributes)
        return unless attrs.is_a?(Hash) && !attrs.empty?

        absorb_input(draft, :controllers, attrs[:stimulus_controllers], instance, implied, phase:, alias_map:)
        absorb_input(draft, :actions, attrs[:stimulus_actions], instance, implied, phase:, alias_map:)
        absorb_input(draft, :targets, attrs[:stimulus_targets], instance, implied, phase:, alias_map:)
        absorb_input(draft, :outlets, attrs[:stimulus_outlets], instance, implied, phase:, alias_map:)
        absorb_input(draft, :values, attrs[:stimulus_values], instance, implied, phase:, alias_map:)
        absorb_input(draft, :params, attrs[:stimulus_params], instance, implied, phase:, alias_map:)
        absorb_input(draft, :class_maps, attrs[:stimulus_classes], instance, implied, phase:, alias_map:)
      end

      def absorb_input(draft, kind, input, instance, implied, phase:, alias_map: {})
        return if input.nil?

        kind_meta = Registry.fetch(kind)
        case input
        in Hash => h
          h.each do |key, raw|
            is_proc = raw.is_a?(Proc)
            next unless phase_allows?(is_proc, phase)
            absorbed = is_proc ? instance.instance_exec(&raw) : raw
            next if absorbed.nil?
            if kind_meta.keyed?
              parsed = kind_meta.value_class.parse(key, absorbed, implied: implied, component_id: instance_id(instance))
              draft.public_send(:"add_#{kind}", parsed)
            else
              entry = resolve_absorb_alias(kind, [key, absorbed], alias_map)
              parsed = parse_entry(kind_meta, entry, implied: implied, component_id: instance_id(instance))
              draft.public_send(:"add_#{kind}", parsed) if parsed
            end
          end
        in Array => a
          a.each do |entry|
            is_proc = entry.is_a?(Proc)
            next unless phase_allows?(is_proc, phase)
            parsed = absorb_one(kind_meta, entry, instance, implied, kind:, alias_map:)
            draft.public_send(:"add_#{kind}", parsed) if parsed
          end
        else
          is_proc = input.is_a?(Proc)
          return unless phase_allows?(is_proc, phase)
          parsed = absorb_one(kind_meta, input, instance, implied, kind:, alias_map:)
          draft.public_send(:"add_#{kind}", parsed) if parsed
        end
      end

      def resolve_absorb_alias(kind, entry, alias_map)
        return entry unless kind == :actions && alias_map.any?
        return entry unless entry.is_a?(Hash) && entry[:controller].is_a?(Symbol)
        sym = entry[:controller]
        unless alias_map.key?(sym)
          raise ::Vident::DeclarationError, "Unknown controller alias :#{sym} in stimulus_actions input. Declared aliases: #{alias_map.keys.inspect}"
        end
        entry.merge(controller: alias_map[sym])
      end

      # Uses pattern matching so an unknown phase raises NoMatchingPatternError early.
      def phase_allows?(is_proc, phase)
        case phase
        in :all then true
        in :static then !is_proc
        in :procs then is_proc
        end
      end

      def absorb_one(kind_meta, entry, instance, implied, kind: nil, alias_map: {})
        entry = instance.instance_exec(&entry) if entry.is_a?(Proc)
        return nil if entry.nil?
        return entry if entry.is_a?(kind_meta.value_class)

        entry = resolve_absorb_alias(kind, entry, alias_map) if kind
        parse_entry(kind_meta, entry, implied: implied, component_id: instance_id(instance))
      end

      def parse_entry(kind_meta, entry, implied:, component_id:)
        case entry
        when Hash
          if kind_meta.keyed?
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

      # Only nil drops — false, blank strings, and empty collections reach the parser.
      def resolve_args(args, instance)
        resolved = args.map { |arg| arg.is_a?(Proc) ? instance.instance_exec(&arg) : arg }
        return nil if resolved.any?(&:nil?)
        resolved
      end

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

      def meta_for_controller(meta) = meta.slice(:as)

      def instance_ivar(instance, name)
        return nil unless instance.instance_variable_defined?(name)
        instance.instance_variable_get(name)
      end

      # Raw ivar read — calling `#id` would trigger auto-generation.
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
