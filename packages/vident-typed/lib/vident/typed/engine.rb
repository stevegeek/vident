module Vident
  module Typed
    class Engine < ::Rails::Engine
      lib_path = File.expand_path("../../../../lib/", __FILE__)
      config.autoload_paths << lib_path
      config.eager_load_paths << lib_path

      config.before_initialize do
        Rails.autoloaders.each do |autoloader|
          autoloader.inflector.inflect(
            "version" => "VERSION"
          )
        end
      end
    end
  end
end
