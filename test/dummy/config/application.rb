require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Dummy
  class Application < Rails::Application
    config.autoload_paths << "#{root}/app/components"
    config.autoload_paths << "#{root}/app/views"
    config.autoload_paths << "#{root}/app/views/layouts"
    config.autoload_paths << "#{root}/app/views/components"

    config.load_defaults Rails::VERSION::STRING.to_f

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    config.importmap.cache_sweepers.append(Rails.root.join("app/components"), Rails.root.join("app/views/layouts"), Rails.root.join("app/views/components"))

    # Add the paths to the components sidecar assets to the asset pipeline. The paths are those to which the
    # components are 'rooted' in the application. E.g if a component `Foo::MyComponent` is defined in
    # "app/components/foo/my_component", then the path to the assets for that component to specify
    # for sprockets here is "app/components/". The paths are typically as follows:
    config.assets.paths.append("app/components/", "app/views/components", "app/views/layouts")
  end
end
