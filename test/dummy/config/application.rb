require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)
require "vident"

module Dummy
  class Application < Rails::Application
    config.autoload_paths << "#{root}/app"
    config.load_defaults Rails::VERSION::STRING.to_f

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    config.importmap.cache_sweepers.append(Rails.root.join("app/components"), Rails.root.join("app/views"))
    config.assets.paths.append("app/components", "app/views")
  end
end
