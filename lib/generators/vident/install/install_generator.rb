# frozen_string_literal: true

require "rails/generators/base"

module Vident
  module Generators
    class InstallGenerator < ::Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      desc "Install Vident: writes a StableId strategy initializer and wires a per-request seed into ApplicationController."

      def create_initializer
        template "vident.rb", "config/initializers/vident.rb"
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
    end
  end
end
