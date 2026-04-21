# frozen_string_literal: true

module Vident
  # Registers acronym inflections Zeitwerk needs to load `Vident::Internals::DSL`
  # and `Vident::Phlex::HTML` from their respective files.
  class Engine < ::Rails::Engine
    config.before_initialize do
      Rails.autoloaders.each do |autoloader|
        autoloader.inflector.inflect(
          "dsl" => "DSL",
          "html" => "HTML"
        )
      end
    end
  end
end
