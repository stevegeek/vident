# frozen_string_literal: true

require "rails/generators/named_base"

module Vident
  module Phlex
    module Generators
      class ComponentGenerator < ::Rails::Generators::NamedBase
        source_root File.expand_path("templates", __dir__)

        desc "Scaffold a Vident Phlex component (.rb), its Stimulus controller sidecar, and a unit test."

        class_option :skip_stimulus, type: :boolean, default: false,
          desc: "Omit the stimulus DSL block and the JS controller sidecar"
        class_option :skip_controller, type: :boolean, default: false,
          desc: "Omit the JS controller sidecar (keeps the stimulus DSL block)"
        class_option :skip_test, type: :boolean, default: false,
          desc: "Skip generating a unit test"
        class_option :typescript, type: :boolean, default: false, aliases: "-t",
          desc: "Emit a TypeScript controller (.ts) instead of JavaScript (.js)"
        class_option :parent, type: :string, default: "ApplicationPhlexComponent",
          desc: "Parent class for the component"

        def create_component_file
          template "component.rb.tt", File.join("app/components", class_path, "#{file_name}_component.rb")
        end

        def create_controller_file
          return if options[:skip_stimulus] || options[:skip_controller]
          ext = options[:typescript] ? "ts" : "js"
          template "controller.#{ext}.tt", File.join("app/components", class_path, "#{file_name}_component_controller.#{ext}")
        end

        def create_test_file
          return if options[:skip_test]
          template "component_test.rb.tt", File.join("test/components", class_path, "#{file_name}_component_test.rb")
        end

        private

        # Allow `g vident:phlex:component TaskCardComponent` to produce the
        # same files as `g ... TaskCard` rather than `TaskCardComponentComponent`.
        # Matches ViewComponent's own generator behaviour.
        def class_name
          super.sub(/Component\z/, "")
        end

        def file_name
          super.sub(/_component\z/, "")
        end

        def component_class_name
          "#{class_name}Component"
        end

        def parent_class
          options[:parent]
        end

        def stimulus_block?
          !options[:skip_stimulus]
        end
      end
    end
  end
end
