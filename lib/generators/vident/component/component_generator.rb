# frozen_string_literal: true

require "rails/generators/named_base"

module Vident
  module Generators
    class ComponentGenerator < ::Rails::Generators::NamedBase
      desc "Scaffold a Vident component. Dispatches to vident:phlex:component or vident:view_component:component based on which engine gem is loaded. Pass --engine to disambiguate when both are present."

      class_option :engine, type: :string, default: nil,
        desc: "Which engine to scaffold for: phlex or view_component"
      class_option :skip_stimulus, type: :boolean, default: false
      class_option :skip_controller, type: :boolean, default: false
      class_option :skip_test, type: :boolean, default: false
      class_option :typescript, type: :boolean, default: false, aliases: "-t"
      class_option :parent, type: :string, default: nil

      def dispatch
        target = resolve_target_generator
        invoke target, [name], forwarded_options
      end

      private

      def resolve_target_generator
        engine = options[:engine]
        if engine.nil?
          available = available_engines
          if available.empty?
            raise ::Thor::Error,
              "No Vident engine gem detected. Add `vident-phlex` or `vident-view_component` to your Gemfile."
          elsif available.size == 1
            generator_for(available.first)
          else
            raise ::Thor::Error,
              "Both vident-phlex and vident-view_component are loaded. Pass --engine=phlex or --engine=view_component."
          end
        else
          unless %w[phlex view_component].include?(engine)
            raise ::Thor::Error, "Unknown engine '#{engine}'. Use --engine=phlex or --engine=view_component."
          end
          generator_for(engine.to_sym)
        end
      end

      def available_engines
        engines = []
        engines << :phlex if defined?(::Vident::Phlex::HTML)
        engines << :view_component if defined?(::Vident::ViewComponent::Base)
        engines
      end

      def generator_for(engine)
        case engine
        when :phlex then "vident:phlex:component"
        when :view_component then "vident:view_component:component"
        end
      end

      def forwarded_options
        options.to_h.except("engine").transform_keys(&:to_s).reject { |_, v| v.nil? }
      end
    end
  end
end
