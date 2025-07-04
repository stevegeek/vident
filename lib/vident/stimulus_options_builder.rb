# frozen_string_literal: true

module Vident
  class StimulusOptionsBuilder
    def initialize(
      id:,
      element_tag:,
      html_options:,
      stimulus_controllers:,
      stimulus_actions:,
      stimulus_targets:,
      stimulus_outlets:,
      stimulus_outlet_host:,
      stimulus_classes:,
      stimulus_values:,
      default_controller_path:,
      stimulus_controller_enabled:,
      class_list_builder:
    )
      @id = id
      @element_tag = element_tag
      @html_options = html_options
      @stimulus_controllers = stimulus_controllers
      @stimulus_actions = stimulus_actions
      @stimulus_targets = stimulus_targets
      @stimulus_outlets = stimulus_outlets
      @stimulus_outlet_host = stimulus_outlet_host
      @stimulus_classes = stimulus_classes
      @stimulus_values = stimulus_values
      @default_controller_path = default_controller_path
      @stimulus_controller_enabled = stimulus_controller_enabled
      @class_list_builder = class_list_builder
    end

    def build(options = {}, pending_actions: [], pending_targets: [], pending_named_classes: {})
      # Add pending actions
      all_actions = @stimulus_actions + Array.wrap(options[:actions])
      all_actions += pending_actions if pending_actions.any?

      # Add pending targets
      all_targets = @stimulus_targets + Array.wrap(options[:targets])
      all_targets += pending_targets if pending_targets.any?

      # Merge pending named classes
      named_classes_option = merge_stimulus_option(options, :stimulus_classes)
      if pending_named_classes.any?
        named_classes_option = named_classes_option.merge(pending_named_classes)
      end

      {
        id: @id || options[:id],
        element_tag: options[:element_tag] || @element_tag || :div,
        html_options: prepare_html_options(options[:html_options]),
        stimulus_controllers: build_controllers(options),
        stimulus_actions: all_actions,
        stimulus_targets: all_targets,
        stimulus_outlets: @stimulus_outlets + Array.wrap(options[:outlets]),
        stimulus_outlet_host: @stimulus_outlet_host,
        stimulus_classes: named_classes_option,
        stimulus_values: prepare_stimulus_option(options, :stimulus_values)
      }
    end

    private

    def build_controllers(options)
      controllers = []
      controllers << @default_controller_path if @stimulus_controller_enabled
      controllers.concat(Array.wrap(options[:controllers]))
      controllers.concat(@stimulus_controllers)
      controllers
    end

    def prepare_html_options(erb_options)
      # Options should override in this order:
      # - defined on component class methods (lowest priority)
      # - defined by passing to component erb
      # - defined by passing to component constructor (highest priority)
      options = erb_options&.except(:class) || {}
      classes_from_view = Array.wrap(erb_options[:class]) if erb_options&.key?(:class)
      options[:class] = @class_list_builder.build(classes_from_view)
      options.merge!(@html_options.except(:class)) if @html_options
      options
    end

    def prepare_stimulus_option(options, name)
      # Get the value from instance variables based on the name
      instance_var_value = instance_variable_get("@#{name}")
      resolved = Array.wrap(instance_var_value)
      resolved.concat(Array.wrap(options[name]))
      resolved
    end

    def merge_stimulus_option(options, name)
      option_key = name
      instance_var_value = instance_variable_get("@#{name}") || {}
      instance_var_value.merge(options[option_key] || {})
    end
  end
end
