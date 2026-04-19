# frozen_string_literal: true

module Vident
  module StimulusAttributes
    extend ActiveSupport::Concern
    # `extend` + `include` so Naming helpers are callable both in the module
    # body (outside define_method args) and inside define_method blocks
    # (at instance call-time).
    extend Stimulus::Naming
    include Stimulus::Naming

    class_methods do
      # Symbol so the action parser treats it as a Stimulus event type.
      def stimulus_scoped_event(event)
        :"#{component_name}:#{stimulus_js_name(event)}"
      end

      def stimulus_scoped_event_on_window(event)
        :"#{component_name}:#{stimulus_js_name(event)}@window"
      end

      private

      def stimulus_js_name(name) = name.to_s.camelize(:lower)
    end

    def stimulus_controller(*args)
      return args.first if args.length == 1 && args.first.is_a?(StimulusController)
      StimulusController.new(*args, implied_controller: implied_controller_path)
    end

    # Plural parsers `stimulus_<kind>s(*args)` — generated from the primitives
    # registry below. Each accepts: pre-built Value (pass-through), pre-built
    # Collection (unwrapped; a single one is returned as-is), Array (splatted
    # into the singular builder), Hash (expanded per-pair for
    # `hash_expands: true`, single-arg descriptor otherwise), else passed to
    # the singular builder. Methods defined this way: `stimulus_controllers`,
    # `stimulus_actions`, `stimulus_targets`, `stimulus_outlets`,
    # `stimulus_values`, `stimulus_params`, `stimulus_classes`.
    Stimulus::PRIMITIVES.each do |primitive|
      define_method(primitive.key) do |*args|
        collection_class = primitive.collection_class
        return collection_class.new if args.empty? || args.all?(&:blank?)
        return args.first if args.length == 1 && args.first.is_a?(collection_class)

        singular = primitive.singular_key
        converted = []
        args.each do |arg|
          case arg
          when primitive.value_class then converted << arg
          when collection_class then converted.concat(arg.to_a)
          when Hash
            if primitive.keyed?
              arg.each { |name, val| converted << send(singular, name, val) }
            else
              converted << send(singular, arg)
            end
          when Array then converted << send(singular, *arg)
          else converted << send(singular, arg)
          end
        end
        collection_class.new(converted)
      end
    end

    def stimulus_action(*args)
      return args.first if args.length == 1 && args.first.is_a?(StimulusAction)
      StimulusAction.new(*args, implied_controller:)
    end

    def stimulus_target(*args)
      return args.first if args.length == 1 && args.first.is_a?(StimulusTarget)
      StimulusTarget.new(*args, implied_controller:)
    end

    # `component_id: @id` scopes the auto-generated selector to this component
    # instance (e.g. `#<host-id> [data-controller~=<outlet>]`).
    def stimulus_outlet(*args)
      return args.first if args.length == 1 && args.first.is_a?(StimulusOutlet)
      StimulusOutlet.new(*args, implied_controller:, component_id: @id)
    end

    def stimulus_value(*args)
      return args.first if args.length == 1 && args.first.is_a?(StimulusValue)
      StimulusValue.new(*args, implied_controller:)
    end

    def stimulus_param(*args)
      return args.first if args.length == 1 && args.first.is_a?(StimulusParam)
      StimulusParam.new(*args, implied_controller:)
    end

    def stimulus_class(*args)
      return args.first if args.length == 1 && args.first.is_a?(StimulusClass)
      StimulusClass.new(*args, implied_controller:)
    end

    # Mutators `add_stimulus_<kind>s` — build from input, merge into the
    # per-kind collection ivar. Methods defined: `add_stimulus_controllers`,
    # `add_stimulus_actions`, `add_stimulus_targets`, `add_stimulus_outlets`,
    # `add_stimulus_values`, `add_stimulus_params`, `add_stimulus_classes`.
    Stimulus::PRIMITIVES.each do |primitive|
      define_method(mutator_method(primitive)) do |input|
        added = send(primitive.key, *Array.wrap(input))
        existing = instance_variable_get(collection_ivar(primitive))
        instance_variable_set(collection_ivar(primitive), existing ? existing.merge(added) : added)
      end
    end

    def stimulus_scoped_event(event) = self.class.stimulus_scoped_event(event)

    def stimulus_scoped_event_on_window(event) = self.class.stimulus_scoped_event_on_window(event)

    private

    def implied_controller
      StimulusController.new(implied_controller: implied_controller_path)
    end

    # The first registered controller path becomes the implied controller for
    # unqualified DSL entries (e.g. `actions :click` → `implied#click`).
    def implied_controller_path
      return @implied_controller_path if defined?(@implied_controller_path)
      path = Array.wrap(@stimulus_controllers).first
      raise(StandardError, "No controllers have been specified") unless path
      @implied_controller_path = path
    end
  end
end
