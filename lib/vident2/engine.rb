# frozen_string_literal: true

module Vident2
  # Rails engine hook for Vident2. Mirrors `Vident::Engine`'s autoload
  # setup (both live under `lib/`) and registers the V2-specific
  # acronym inflections Zeitwerk needs to load `Vident2::Internals::DSL`
  # and `Vident2::Phlex::HTML` from their respective files.
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
