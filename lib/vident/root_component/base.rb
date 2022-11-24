# frozen_string_literal: true

module Vident
  module RootComponent
    module Base
      def initialize(
        controllers: nil,
        actions: nil,
        targets: nil,
        named_classes: nil, # https://stimulus.hotwired.dev/reference/css-classes
        data_maps: nil,
        element_tag: nil,
        id: nil,
        html_options: nil
      )
        @element_tag = element_tag
        @html_options = html_options
        @id = id
        @controllers = Array.wrap(controllers)
        @actions = actions
        @targets = targets
        @named_classes = named_classes
        @data_map_kvs = {}
        @data_maps = data_maps
      end

      # The view component's helpers for setting stimulus data-* attributes on this component.

      # Create a tag for a target with a block containing content
      def target_tag(tag_name, targets, **options, &block)
        parsed = parse_targets(Array.wrap(targets))
        options[:data] ||= {}
        options[:data].merge!(build_target_data_attributes(parsed))
        send(tag_name, options, &block)
      end

      # TODO: rename
      # Create a Stimulus action string, and returns it
      #   examples:
      #   action(:my_thing) => "current_controller#myThing"
      #   action(:click, :my_thing) => "click->current_controller#myThing"
      #   action("click->current_controller#myThing") => "click->current_controller#myThing"
      #   action("path/to/current", :my_thing) => "path--to--current_controller#myThing"
      #   action(:click, "path/to/current", :my_thing) => "click->path--to--current_controller#myThing"
      def action(*args)
        part1, part2, part3 = args
        (args.size == 1) ? parse_action_arg(part1) : parse_multiple_action_args(part1, part2, part3)
      end

      # TODO: rename & make stimulus Target class instance and returns it, which can convert to String
      # Create a Stimulus Target and returns it
      #   examples:
      #   target(:my_target) => {controller: 'current_controller' name: 'myTarget'}
      #   target("path/to/current", :my_target) => {controller: 'path--to--current_controller', name: 'myTarget'}
      def target(name, part2 = nil)
        if part2.nil?
          {controller: implied_controller_name, name: js_name(name)}
        else
          {controller: stimulize_path(name), name: js_name(part2)}
        end
      end

      def target_data_attribute(name)
        build_target_data_attributes([target(name)])
      end

      # Getter for a named classes list so can be used in view to set initial state on SSR
      # Returns a String of classes that can be used in a `class` attribute.
      def named_classes(*names)
        names.map { |name| convert_classes_list_to_string(@named_classes[name]) }.join(" ")
      end

      # Helpers for generating the Stimulus data-* attributes directly

      # Return the HTML `data-controller` attribute
      def with_controllers
        "data-controller='#{controller_list}'".html_safe
      end

      # Return the HTML `data-target` attribute
      def as_targets(*targets)
        build_target_data_attributes(parse_targets(targets))
          .map { |dt, n| "data-#{dt}=\"#{n}\"" }
          .join(" ")
          .html_safe
      end
      alias_method :as_target, :as_targets

      # Return the HTML `data-action` attribute to add these actions
      def with_actions(*actions)
        "data-action='#{parse_actions(actions).join(" ")}'".html_safe
      end
      alias_method :with_action, :with_actions

      private

      # An implicit Stimulus controller name is built from the implicit controller path
      def implied_controller_name
        stimulize_path(implied_controller_path)
      end

      # When using the DSL if you dont specify, the first controller is implied
      def implied_controller_path
        @controllers&.first || raise(StandardError, "No controllers have been specified")
      end

      # A complete list of Stimulus controllers for this component
      def controller_list
        @controllers&.map { |c| stimulize_path(c) }&.join(" ")
      end

      # Complete list of actions ready to be use in the data-action attribute
      def action_list
        return nil unless @actions&.size&.positive?
        parse_actions(@actions).join(" ")
      end

      # Complete list of targets ready to be use in the data attributes
      def target_list
        return {} unless @targets&.size&.positive?
        build_target_data_attributes(parse_targets(@targets))
      end

      def named_classes_list
        return {} unless @named_classes&.size&.positive?
        build_named_classes_data_attributes(@named_classes)
      end

      # stimulus "data-*" attributes map for this component
      def tag_data_attributes
        {controller: controller_list, action: action_list}
          .merge!(target_list)
          .merge!(named_classes_list)
          .merge!(data_map_attributes)
          .compact_blank!
      end

      # Actions can be specified as a symbol, in which case they imply an action on the primary
      # controller, or as a string in which case it implies an action that is already fully qualified
      # stimulus action.
      # 1 Symbol: :my_action => "my_controller#myAction"
      # 1 String: "my_controller#myAction"
      # 2 Symbols: [:click, :my_action] => "click->my_controller#myAction"
      # 1 String, 1 Symbol: ["path/to/controller", :my_action] => "path--to--controller#myAction"
      # 1 Symbol, 1 String, 1 Symbol: [:hover, "path/to/controller", :my_action] => "hover->path--to--controller#myAction"

      def parse_action_arg(part1)
        if part1.is_a?(Symbol)
          # 1 symbol arg, name of method on this controller
          "#{implied_controller_name}##{js_name(part1)}"
        elsif part1.is_a?(String)
          # 1 string arg, fully qualified action
          part1
        end
      end

      def parse_multiple_action_args(part1, part2, part3)
        if part3.nil? && part1.is_a?(Symbol)
          # 2 symbol args = event + action
          "#{part1}->#{implied_controller_name}##{js_name(part2)}"
        elsif part3.nil?
          # 1 string arg, 1 symbol = controller + action
          "#{stimulize_path(part1)}##{js_name(part2)}"
        else
          # 1 symbol, 1 string, 1 symbol = as above but with event
          "#{part1}->#{stimulize_path(part2)}##{js_name(part3)}"
        end
      end

      # Parse actions, targets and attributes that are passed in as symbols or strings

      def parse_targets(targets)
        targets.map { |n| parse_target(n) }
      end

      def parse_target(raw_target)
        return raw_target if raw_target.is_a?(String)
        return raw_target if raw_target.is_a?(Hash)
        target(raw_target)
      end

      def build_target_data_attributes(targets)
        targets.map { |t| ["#{t[:controller]}-target", t[:name]] }.to_h
      end

      def parse_actions(actions)
        actions.map! { |a| a.is_a?(String) ? a : action(*a) }
      end

      def parse_attributes(attrs, controller = nil)
        attrs.transform_keys { |k| "#{controller || implied_controller_name}-#{k}" }
      end

      def data_map_attributes
        return {} unless @data_maps
        @data_maps.each_with_object({}) do |m, obj|
          if m.is_a?(Hash)
            obj.merge!(parse_attributes(m))
          elsif m.is_a?(Array)
            controller_path = m.first
            data = m.last
            obj.merge!(parse_attributes(data, stimulize_path(controller_path)))
          end
        end
      end

      def parse_named_classes_hash(named_classes)
        named_classes.map do |name, classes|
          logical_name = name.to_s.dasherize
          classes_str = convert_classes_list_to_string(classes)
          if classes.is_a?(Hash)
            {controller: stimulize_path(classes[:controller_path]), name: logical_name, classes: classes_str}
          else
            {controller: implied_controller_name, name: logical_name, classes: classes_str}
          end
        end
      end

      def build_named_classes_data_attributes(named_classes)
        parse_named_classes_hash(named_classes)
          .map { |c| ["#{c[:controller]}-#{c[:name]}-class", c[:classes]] }
          .to_h
      end

      def convert_classes_list_to_string(classes)
        return "" if classes.nil?
        return classes if classes.is_a?(String)
        return classes.join(" ") if classes.is_a?(Array)
        classes[:classes].is_a?(Array) ? classes[:classes].join(" ") : classes[:classes]
      end

      # Convert a file path to a stimulus controller name
      def stimulize_path(path)
        path.split("/").map { |p| p.to_s.dasherize }.join("--")
      end

      # Convert a Ruby 'snake case' string to a JavaScript camel case strings
      def js_name(name)
        name.to_s.camelize(:lower)
      end
    end
  end
end
