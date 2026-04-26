# frozen_string_literal: true

require "rails/generators/base"

module Vident
  module Generators
    class InstallGenerator < ::Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      desc "Install Vident: writes a StableId strategy initializer, wires a per-request seed into ApplicationController, and copies the Vident Claude Code skill to .claude/skills/vident/."

      SKILL_SOURCE = File.expand_path("../../../../skills/vident/SKILL.md", __dir__)

      def create_initializer
        template "vident.rb", "config/initializers/vident.rb"
      end

      def create_application_components
        write_application_component("application_phlex_component.rb") if defined?(::Vident::Phlex::HTML)
        write_application_component("application_view_component.rb") if defined?(::Vident::ViewComponent::Base)
      end

      def install_claude_skill
        return unless File.exist?(SKILL_SOURCE)
        destination = ".claude/skills/vident/SKILL.md"
        absolute = File.expand_path(destination, destination_root)
        # Preserve an existing skill file (user may have edited it);
        # `--force` pulls the current SKILL from the installed gem over
        # the top so upgrades can refresh it.
        if File.exist?(absolute) && !options[:force]
          say_status :exist, destination, :blue
        else
          empty_directory(File.dirname(destination))
          copy_file(SKILL_SOURCE, destination, force: true)
        end
      end

      SEED_MARKER = "Vident::StableId.set_current_sequence_generator"

      def patch_application_controller
        controller_path = "app/controllers/application_controller.rb"
        absolute = File.expand_path(controller_path, destination_root)
        return unless File.exist?(absolute)

        # Idempotent: skip if a previous install already patched this controller.
        return if File.read(absolute).include?(SEED_MARKER)

        hook = <<~RUBY.indent(2)
          before_action do
            Vident::StableId.set_current_sequence_generator(seed: request.fullpath)
          end
          after_action do
            Vident::StableId.clear_current_sequence_generator
          end
        RUBY

        inject_into_class controller_path, "ApplicationController", "\n#{hook}"
      end

      private

      # Mirror the skill file's preserve-on-existing semantics: re-running
      # the install generator should not clobber a base class the user has
      # extended. `--force` opts back into overwriting.
      def write_application_component(filename)
        destination = "app/components/#{filename}"
        absolute = File.expand_path(destination, destination_root)
        if File.exist?(absolute) && !options[:force]
          say_status :exist, destination, :blue
        else
          template "#{filename}.tt", destination
        end
      end
    end
  end
end
