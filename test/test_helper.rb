# Configure SimpleCov for test coverage
require 'simplecov'
SimpleCov.start do
  add_filter '/test/'
  add_filter '/vendor/'
  add_filter '/tmp/'
  add_filter 'version.rb'
  
  add_group 'Core', 'lib/vident'
  add_group 'ViewComponent', 'lib/vident/view_component'
  add_group 'Phlex', 'lib/vident/phlex'
  add_group 'Stimulus', 'lib/vident/stimulus'
end

# Configure Rails Environment
ENV["RAILS_ENV"] = "test"

require_relative "../test/dummy/config/environment"
ActiveRecord::Migrator.migrations_paths = [File.expand_path("../test/dummy/db/migrate", __dir__)]
require "rails/test_help"

# Load fixtures from the engine
if ActiveSupport::TestCase.respond_to?(:fixture_paths=)
  ActiveSupport::TestCase.fixture_paths = [File.expand_path("fixtures", __dir__)]
  ActionDispatch::IntegrationTest.fixture_paths = ActiveSupport::TestCase.fixture_paths
  ActiveSupport::TestCase.file_fixture_path = File.expand_path("fixtures", __dir__) + "/files"
  ActiveSupport::TestCase.fixtures :all
end
