# frozen_string_literal: true

require_relative "../internals/registry"
require_relative "../stimulus/collection"

module Vident
  module Capabilities
    module ChildElementRendering
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
          actions: [stimulus_actions, stimulus_action],
          targets: [stimulus_targets, stimulus_target],
          outlets: [stimulus_outlets, stimulus_outlet],
          values: [stimulus_values, stimulus_value],
          params: [stimulus_params, stimulus_param],
          class_maps: [stimulus_classes, stimulus_class]
        }

        data_attrs = {}
        ::Vident::Internals::Registry.each do |kind|
          plural, singular = inputs.fetch(kind.name)
          child_element_check_plural!(plural, singular, kind)
          coll = child_element_build_collection(kind, plural, singular)
          data_attrs.merge!(coll.to_h) unless coll.empty?
        end

        generate_child_element(tag_name, data_attrs, options, &block)
      end

      def generate_child_element(tag_name, stimulus_data_attributes, options, &block)
        raise NoMethodError, "adapter must implement generate_child_element"
      end

      private

      def child_element_check_plural!(plural, singular, kind)
        if plural && singular
          raise ArgumentError,
            "'stimulus_#{kind.plural_name}:' and 'stimulus_#{kind.singular_name}:' " \
            "are mutually exclusive — pass one or the other."
        end
        return if plural.nil?
        return if plural.is_a?(Enumerable) && !plural.is_a?(Hash)
        return if plural.is_a?(Hash) && kind.keyed?
        raise ArgumentError,
          "'stimulus_#{kind.plural_name}:' must be an enumerable. " \
          "Did you mean 'stimulus_#{kind.singular_name}:'?"
      end

      # Exactly one of `plural` / `singular` is non-nil; guard above
      # rejects both-set.
      def child_element_build_collection(kind, plural, singular)
        plural_method = :"stimulus_#{kind.plural_name}"
        singular_method = :"stimulus_#{kind.singular_name}"

        if plural
          if kind.keyed? && plural.is_a?(Hash)
            send(plural_method, plural)
          elsif plural.is_a?(Array)
            send(plural_method, *plural)
          else
            send(plural_method, *Array.wrap(plural))
          end
        elsif singular
          coll_items = [send(singular_method, *Array.wrap(singular))]
          ::Vident::Stimulus::Collection.new(kind: kind, items: coll_items)
        else
          ::Vident::Stimulus::Collection.new(kind: kind, items: [])
        end
      end
    end
  end
end
