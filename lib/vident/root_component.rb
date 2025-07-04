# frozen_string_literal: true

module Vident
  module RootComponent
    include Tailwind

    def initialize(
      stimulus_controllers: nil,
      stimulus_actions: nil,
      stimulus_targets: nil,
      stimulus_outlets: nil,
      stimulus_outlet_host: nil, # A component that will host this component as an outlet
      stimulus_classes: nil, # https://stimulus.hotwired.dev/reference/css-classes
      stimulus_values: nil,
      element_tag: nil,
      id: nil,
      # class: nil, # TODO: Shortcut for `html_options[:class]` ??
      html_options: nil
    )
      @element_tag = element_tag
      @html_options = html_options
      @id = id

      @implied_controller_path = Array.wrap(stimulus_controllers)&.first
      
      # Convert raw attributes to stimulus attribute collections
      @stimulus_controllers_collection = wrap_stimulus_controllers(stimulus_controllers)
      @stimulus_actions_collection = wrap_stimulus_actions(stimulus_actions)
      @stimulus_targets_collection = wrap_stimulus_targets(stimulus_targets)
      @stimulus_outlets_collection = wrap_stimulus_outlets(stimulus_outlets)
      @stimulus_values_collection = wrap_stimulus_values(stimulus_values)
      @stimulus_classes_collection = wrap_stimulus_classes(stimulus_classes)

      stimulus_outlet_host.connect_stimulus_outlet(self) if stimulus_outlet_host.respond_to?(:connect_outlet)
    end

    # The view component's helpers for setting stimulus data-* attributes on this component.

    # Hook in component as outlet
    def connect_stimulus_outlet(component)
      outlets = wrap_stimulus_outlets(component)
      @stimulus_outlets_collection = if @stimulus_outlets_collection
        @stimulus_outlets_collection.merge(outlets)
      else
        outlets
      end
    end

    # Create a Stimulus Controller and returns a StimulusController instance
    #   examples:
    #   stimulus_controller("my_controller") => StimulusController that converts to {"controller" => "my-controller"}
    #   stimulus_controller("path/to/controller") => StimulusController that converts to {"controller" => "path--to--controller"}
    #   stimulus_controller() => StimulusController that uses implied controller name
    def stimulus_controller(*args)
      StimulusController.new(*args, implied_controller: implied_controller_path)
    end

    # Create a Stimulus Controller Collection and returns a StimulusControllerCollection instance
    #   examples:
    #   stimulus_controllers(:my_controller) => StimulusControllerCollection with one controller that converts to {"controller" => "my-controller"}
    #   stimulus_controllers(:my_controller, "path/to/another") => StimulusControllerCollection with two controllers that converts to {"controller" => "my-controller path--to--another"}
    def stimulus_controllers(*controllers)
      StimulusControllerCollection.new(controllers.map { |c| stimulus_controller(c) })
    end

    # Create a Stimulus action and returns a StimulusAction instance
    #   examples:
    #   stimulus_action(:my_thing) => StimulusAction that converts to "current_controller#myThing"
    #   stimulus_action(:click, :my_thing) => StimulusAction that converts to "click->current_controller#myThing"
    #   stimulus_action("click->current_controller#myThing") => StimulusAction that converts to "click->current_controller#myThing"
    #   stimulus_action("path/to/current", :my_thing) => StimulusAction that converts to "path--to--current_controller#myThing"
    #   stimulus_action(:click, "path/to/current", :my_thing) => StimulusAction that converts to "click->path--to--current_controller#myThing"
    def stimulus_action(*args)
      StimulusAction.new(*args, implied_controller:)
    end

    # Create a Stimulus Action Collection and returns a StimulusActionCollection instance
    def stimulus_actions(*actions)
      StimulusActionCollection.new(actions.map { |a| stimulus_action(a) })
    end

    # Create a Stimulus Target and returns a StimulusTarget instance
    #   examples:
    #   stimulus_target(:my_target) => StimulusTarget that converts to {"current_controller-target" => "myTarget"}
    #   stimulus_target("path/to/current", :my_target) => StimulusTarget that converts to {"path--to--current-target" => "myTarget"}
    def stimulus_target(*args)
      StimulusTarget.new(*args, implied_controller:)
    end

    # Create a Stimulus Target Collection and returns a StimulusTargetCollection instance
    def stimulus_targets(*targets)
      StimulusTargetCollection.new(targets.map { |t| stimulus_target(t) })
    end

    # Create a Stimulus Outlet and returns a StimulusOutlet instance
    #   examples:
    #   stimulus_outlet(:user_status, ".online-user") => StimulusOutlet that converts to {"current_controller-user-status-outlet" => ".online-user"}
    #   stimulus_outlet("path/to/current", :user_status, ".online-user") => StimulusOutlet that converts to {"path--to--current-user-status-outlet" => ".online-user"}
    #   stimulus_outlet(:user_status) => StimulusOutlet with auto-generated selector
    #   stimulus_outlet(component_instance) => StimulusOutlet from component
    def stimulus_outlet(*args)
      StimulusOutlet.new(*args, implied_controller:, component_id: @id)
    end

    # Create a Stimulus Outlet Collection and returns a StimulusOutletCollection instance
    def stimulus_outlets(*outlets)
      StimulusOutletCollection.new(outlets.map { |o| stimulus_outlet(o) })
    end

    # Create a Stimulus Value and returns a StimulusValue instance
    #   examples:
    #   stimulus_value(:url, "https://example.com") => StimulusValue that converts to {"current_controller-url-value" => "https://example.com"}
    #   stimulus_value("path/to/current", :url, "https://example.com") => StimulusValue that converts to {"path--to--current-url-value" => "https://example.com"}
    def stimulus_value(*args)
      StimulusValue.new(*args, implied_controller:)
    end

    # Create a Stimulus Value Collection and returns a StimulusValueCollection instance
    def stimulus_values(*values)
      StimulusValueCollection.new(values.map { |v| stimulus_value(v) })
    end

    # Create a Stimulus Class and returns a StimulusClass instanceLefty
    #   examples:
    #   stimulus_class(:loading, "spinner active") => StimulusClass that converts to {"current_controller-loading-class" => "spinner active"}
    #   stimulus_class("path/to/current", :loading, ["spinner", "active"]) => StimulusClass that converts to {"path--to--current-loading-class" => "spinner active"}
    def stimulus_class(*args)
      StimulusClass.new(*args, implied_controller:)
    end

    # Create a Stimulus Class Collection and returns a StimulusClassCollection instance
    def stimulus_classes(*classes)
      StimulusClassCollection.new(classes.map { |c| stimulus_class(c) })
    end

    # Getter for a stimulus classes list so can be used in view to set initial state on SSR
    # Returns a String of classes that can be used in a `class` attribute.
    def class_list_for_stimulus_classes(*names)
      class_list_builder.build(@stimulus_classes_collection, stimulus_class_names: names) || ""
    end

    # Build stimulus data attributes using collection splat
    def stimulus_data_attributes
      StimulusDataAttributeBuilder.new(
        controllers: @stimulus_controllers_collection,
        actions: @stimulus_actions_collection,
        targets: @stimulus_targets_collection,
        outlets: @stimulus_outlets_collection,
        values: @stimulus_values_collection,
        classes: @stimulus_classes_collection
      ).build
    end

    # Generate a tag with the given name and options, including stimulus data attributes
    def tag(
      tag_name,
      stimulus_controllers: nil,
      stimulus_targets: nil,
      stimulus_actions: nil,
      stimulus_outlets: nil,
      stimulus_values: nil,
      stimulus_classes: nil,
      stimulus_controller: nil,
      stimulus_target: nil,
      stimulus_action: nil,
      stimulus_outlet: nil,
      stimulus_value: nil,
      stimulus_class: nil,
      **options,
      &block
    )
      stimulus_controllers_collection = wrap_stimulus_controllers(stimulus_controllers || stimulus_controller)
      stimulus_targets_collection = wrap_stimulus_targets(stimulus_targets || [stimulus_target])
      stimulus_actions_collection = wrap_stimulus_actions(stimulus_actions || [stimulus_action])
      stimulus_outlets_collection = wrap_stimulus_outlets(stimulus_outlets || [stimulus_outlet])
      stimulus_values_collection = wrap_stimulus_values(stimulus_values || [stimulus_value])
      stimulus_classes_collection = wrap_stimulus_classes(stimulus_classes || stimulus_class)

      stimulus_data_attributes = StimulusDataAttributeBuilder.new(
        controllers: stimulus_controllers_collection,
        actions: stimulus_actions_collection,
        targets: stimulus_targets_collection,
        outlets: stimulus_outlets_collection,
        values: stimulus_values_collection,
        classes: stimulus_classes_collection
      ).build
      generate_tag(tag_name, stimulus_data_attributes, options, &block)
    end

    private

    def implied_controller
      StimulusController.new(implied_controller: implied_controller_path)
    end

    # Get or create a class list builder instance
    # Automatically detects if Tailwind module is included and TailwindMerge gem is available
    def class_list_builder
      @class_list_builder ||= ClassListBuilder.new(tailwind_merger:)
    end

    # When using the DSL if you dont specify, the first controller is implied
    def implied_controller_path
      raise(StandardError, "No controllers have been specified") unless @implied_controller_path
      @implied_controller_path
    end

    # Wrapper methods to transform raw attributes into stimulus attribute collections
    def wrap_stimulus_controllers(controllers)
      return StimulusControllerCollection.new unless controllers.present?
      stimulus_controllers(*Array.wrap(controllers))
    end

    def wrap_stimulus_actions(actions)
      return StimulusActionCollection.new unless actions.present?
      converted_actions = Array.wrap(actions).map do |action|
        if action.is_a?(Array)
          stimulus_action(*action)
        else
          stimulus_action(action)
        end
      end
      StimulusActionCollection.new(converted_actions)
    end

    def wrap_stimulus_targets(targets)
      return StimulusTargetCollection.new unless targets.present?
      converted_targets = Array.wrap(targets).map do |target|
        if target.is_a?(Array)
          stimulus_target(*target)
        else
          stimulus_target(target)
        end
      end
      StimulusTargetCollection.new(converted_targets)
    end

    def wrap_stimulus_outlets(outlets)
      return StimulusOutletCollection.new unless outlets.present?
      converted_outlets = Array.wrap(outlets).map do |outlet|
        if outlet.is_a?(Array)
          stimulus_outlet(*outlet)
        else
          stimulus_outlet(outlet)
        end
      end
      StimulusOutletCollection.new(converted_outlets)
    end

    def wrap_stimulus_values(values)
      return StimulusValueCollection.new unless values.present?
      converted_values = Array.wrap(values).flat_map do |value|
        if value.is_a?(Hash)
          # Hash format: {name: value, other_name: other_value}
          value.map { |name, val| stimulus_value(name, val) }
        elsif value.is_a?(Array) && value.size == 3
          # Array format: [controller, name, value]
          [stimulus_value(*value)]
        elsif value.is_a?(Array) && value.size == 2
          # Array format: [name, value]
          [stimulus_value(*value)]
        else
          []
        end
      end
      StimulusValueCollection.new(converted_values)
    end

    def wrap_stimulus_classes(named_classes)
      return StimulusClassCollection.new unless named_classes.present?
      converted_classes = if named_classes.is_a?(Hash)
        named_classes.flat_map do |name, classes|
          if classes.is_a?(Hash) && classes[:controller_path]
            # Hash with controller path: {loading: {controller_path: "path", classes: ["spinner"]}}
            [stimulus_class(classes[:controller_path], name, classes[:classes])]
          else
            # Simple hash: {loading: "spinner active"}
            [stimulus_class(name, classes)]
          end
        end
      else
        Array.wrap(named_classes).map do |named_class|
          if named_class.is_a?(Array)
            stimulus_class(*named_class)
          else
            stimulus_class(named_class)
          end
        end
      end
      StimulusClassCollection.new(converted_classes)
    end

    def generate_tag(tag_name, stimulus_data_attributes, options, &block)
      raise NoMethodError, "Not implemented"
    end
  end
end
