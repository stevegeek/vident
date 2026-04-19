ENV["RAILS_ENV"] = "test"

if ENV["COVERAGE"]
  require "simplecov"
  SimpleCov.command_name "Vident"
  SimpleCov.root File.expand_path("..", __dir__)
  SimpleCov.start do
    add_filter "/test/"
    add_filter "/tmp/"
    add_filter "/bin/"
    add_filter "/lib/vident/engine.rb"
  end
end

require_relative "../test/dummy/config/environment"
ActiveRecord::Migrator.migrations_paths = [File.expand_path("../test/dummy/db/migrate", __dir__)]
require "rails/test_help"
require "capybara/rails"

Vident::StableId.strategy = Vident::StableId::RANDOM_FALLBACK

# Load fixtures from the engine
if ActiveSupport::TestCase.respond_to?(:fixture_paths=)
  ActiveSupport::TestCase.fixture_paths = [File.expand_path("fixtures", __dir__)]
  ActionDispatch::IntegrationTest.fixture_paths = ActiveSupport::TestCase.fixture_paths
  ActiveSupport::TestCase.file_fixture_path = File.expand_path("fixtures", __dir__) + "/files"
  ActiveSupport::TestCase.fixtures :all
end
