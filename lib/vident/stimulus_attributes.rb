# frozen_string_literal: true

module Vident
  module StimulusAttributes
    # Parse inputs to create a StimulusController instance representing a Stimulus controller attribute
    #   examples:
    #   stimulus_controller("my_controller") => StimulusController that converts to {"controller" => "my-controller"}
    #   stimulus_controller("path/to/controller") => StimulusController that converts to {"controller" => "path--to--controller"}
    #   stimulus_controller() => StimulusController that uses implied controller name
    def stimulus_controller(*args)
      return args.first if args.length == 1 && args.first.is_a?(StimulusController)
      StimulusController.new(*args, implied_controller: implied_controller_path)
    end

    # Parse inputs to create a StimulusControllerCollection instance representing multiple Stimulus controllers
    #   examples:
    #   stimulus_controllers(:my_controller) => StimulusControllerCollection with one controller that converts to {"controller" => "my-controller"}
    #   stimulus_controllers(:my_controller, "path/to/another") => StimulusControllerCollection with two controllers that converts to {"controller" => "my-controller path--to--another"}
    def stimulus_controllers(*controllers)
      return StimulusControllerCollection.new if controllers.empty? || controllers.all?(&:blank?)
      
      converted_controllers = controllers.map do |controller|
        controller.is_a?(Array) ? stimulus_controller(*controller) : stimulus_controller(controller)
      end
      StimulusControllerCollection.new(converted_controllers)
    end

    # Parse inputs to create a StimulusAction instance representing a Stimulus action attribute
    #   examples:
    #   stimulus_action(:my_thing) => StimulusAction that converts to "current_controller#myThing"
    #   stimulus_action(:click, :my_thing) => StimulusAction that converts to "click->current_controller#myThing"
    #   stimulus_action("click->current_controller#myThing") => StimulusAction that converts to "click->current_controller#myThing"
    #   stimulus_action("path/to/current", :my_thing) => StimulusAction that converts to "path--to--current_controller#myThing"
    #   stimulus_action(:click, "path/to/current", :my_thing) => StimulusAction that converts to "click->path--to--current_controller#myThing"
    def stimulus_action(*args)
      return args.first if args.length == 1 && args.first.is_a?(StimulusAction)
      StimulusAction.new(*args, implied_controller:)
    end

    # Parse inputs to create a StimulusActionCollection instance representing multiple Stimulus actions
    def stimulus_actions(*actions)
      return StimulusActionCollection.new if actions.empty? || actions.all?(&:blank?)
      
      converted_actions = actions.map do |action|
        action.is_a?(Array) ? stimulus_action(*action) : stimulus_action(action)
      end
      StimulusActionCollection.new(converted_actions)
    end

    # Parse inputs to create a StimulusTarget instance representing a Stimulus target attribute
    #   examples:
    #   stimulus_target(:my_target) => StimulusTarget that converts to {"current_controller-target" => "myTarget"}
    #   stimulus_target("path/to/current", :my_target) => StimulusTarget that converts to {"path--to--current-target" => "myTarget"}
    def stimulus_target(*args)
      return args.first if args.length == 1 && args.first.is_a?(StimulusTarget)
      StimulusTarget.new(*args, implied_controller:)
    end

    # Parse inputs to create a StimulusTargetCollection instance representing multiple Stimulus targets
    def stimulus_targets(*targets)
      return StimulusTargetCollection.new if targets.empty? || targets.all?(&:blank?)
      
      converted_targets = targets.map do |target|
        target.is_a?(Array) ? stimulus_target(*target) : stimulus_target(target)
      end
      StimulusTargetCollection.new(converted_targets)
    end

    # Parse inputs to create a StimulusOutlet instance representing a Stimulus outlet attribute
    #   examples:
    #   stimulus_outlet(:user_status, ".online-user") => StimulusOutlet that converts to {"current_controller-user-status-outlet" => ".online-user"}
    #   stimulus_outlet("path/to/current", :user_status, ".online-user") => StimulusOutlet that converts to {"path--to--current-user-status-outlet" => ".online-user"}
    #   stimulus_outlet(:user_status) => StimulusOutlet with auto-generated selector
    #   stimulus_outlet(component_instance) => StimulusOutlet from component
    def stimulus_outlet(*args)
      return args.first if args.length == 1 && args.first.is_a?(StimulusOutlet)
      StimulusOutlet.new(*args, implied_controller:, component_id: @id)
    end

    # Parse inputs to create a StimulusOutletCollection instance representing multiple Stimulus outlets
    def stimulus_outlets(*outlets)
      return StimulusOutletCollection.new if outlets.empty? || outlets.all?(&:blank?)
      
      converted_outlets = outlets.map do |outlet|
        outlet.is_a?(Array) ? stimulus_outlet(*outlet) : stimulus_outlet(outlet)
      end
      StimulusOutletCollection.new(converted_outlets)
    end

    # Parse inputs to create a StimulusValue instance representing a Stimulus value attribute
    #   examples:
    #   stimulus_value(:url, "https://example.com") => StimulusValue that converts to {"current_controller-url-value" => "https://example.com"}
    #   stimulus_value("path/to/current", :url, "https://example.com") => StimulusValue that converts to {"path--to--current-url-value" => "https://example.com"}
    def stimulus_value(*args)
      return args.first if args.length == 1 && args.first.is_a?(StimulusValue)
      StimulusValue.new(*args, implied_controller:)
    end

    # Parse inputs to create a StimulusValueCollection instance representing multiple Stimulus values
    def stimulus_values(*values)
      return StimulusValueCollection.new if values.empty? || values.all?(&:blank?)
      
      converted_values = []
      
      values.each do |value|
        if value.is_a?(Hash)
          # Hash format: {name: value, other_name: other_value} - expands to multiple values
          value.each { |name, val| converted_values << stimulus_value(name, val) }
        elsif value.is_a?(Array)
          # Array format: [controller, name, value] or [name, value] - splat into stimulus_value
          converted_values << stimulus_value(*value)
        else
          converted_values << stimulus_value(value)
        end
      end
      
      StimulusValueCollection.new(converted_values)
    end

    # Parse inputs to create a StimulusClass instance representing a Stimulus class attribute
    #   examples:
    #   stimulus_class(:loading, "spinner active") => StimulusClass that converts to {"current_controller-loading-class" => "spinner active"}
    #   stimulus_class("path/to/current", :loading, ["spinner", "active"]) => StimulusClass that converts to {"path--to--current-loading-class" => "spinner active"}
    def stimulus_class(*args)
      return args.first if args.length == 1 && args.first.is_a?(StimulusClass)
      StimulusClass.new(*args, implied_controller:)
    end

    # Parse inputs to create a StimulusClassCollection instance representing multiple Stimulus classes
    def stimulus_classes(*classes)
      return StimulusClassCollection.new if classes.empty? || classes.all?(&:blank?)
      
      converted_classes = []
      
      classes.each do |cls|
        if cls.is_a?(Hash)
          # Hash format: {loading: "spinner active", error: "text-red-500"} - expands to multiple classes
          cls.each { |name, class_list| converted_classes << stimulus_class(name, class_list) }
        elsif cls.is_a?(Array)
          # Array format: [controller, name, classes] or [name, classes] - splat into stimulus_class
          converted_classes << stimulus_class(*cls)
        else
          converted_classes << stimulus_class(cls)
        end
      end
      
      StimulusClassCollection.new(converted_classes)
    end

    # Methods to add to the stimulus collections

    def add_stimulus_controllers(controllers)
      s_controllers = stimulus_controllers(*Array.wrap(controllers))
      @stimulus_controllers_collection = if @stimulus_controllers_collection
        @stimulus_controllers_collection.merge(s_controllers)
      else
        s_controllers
      end
    end

    def add_stimulus_actions(actions)
      s_actions = stimulus_actions(*Array.wrap(actions))
      @stimulus_actions_collection = if @stimulus_actions_collection
        @stimulus_actions_collection.merge(s_actions)
      else
        s_actions
      end
    end

    def add_stimulus_targets(targets)
      s_targets = stimulus_targets(*Array.wrap(targets))
      @stimulus_targets_collection = if @stimulus_targets_collection
        @stimulus_targets_collection.merge(s_targets)
      else
        s_targets
      end
    end

    def add_stimulus_outlets(outlets)
      s_outlets = stimulus_outlets(*Array.wrap(outlets))
      @stimulus_outlets_collection = if @stimulus_outlets_collection
        @stimulus_outlets_collection.merge(s_outlets)
      else
        s_outlets
      end
    end

    def add_stimulus_values(values)
      s_values = stimulus_values(values)
      @stimulus_values_collection = if @stimulus_values_collection
        @stimulus_values_collection.merge(s_values)
      else
        s_values
      end
    end

    def add_stimulus_classes(named_classes)
      classes = stimulus_classes(named_classes)
      @stimulus_classes_collection = if @stimulus_classes_collection
        @stimulus_classes_collection.merge(classes)
      else
        classes
      end
    end

    private

    def implied_controller
      StimulusController.new(implied_controller: implied_controller_path)
    end

    # When using the DSL if you dont specify, the first controller is implied
    def implied_controller_path
      return @implied_controller_path if defined?(@implied_controller_path)
      path = Array.wrap(@stimulus_controllers).first
      raise(StandardError, "No controllers have been specified") unless path
      @implied_controller_path = path
    end
  end
end
