# Configure Rails Environment
ENV["RAILS_ENV"] = "test"
ENV["ZEITWERK_DISABLED"] = "1" # Disable Zeitwerk autoloading to avoid naming issues

# Add the lib directory to the load path
$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

# Load and setup bundler
require "bundler"
Bundler.setup

# Load required dependencies
require "active_support"
require "active_support/concern"
require "active_support/core_ext"
require "active_support/core_ext/module/delegation"

# Require these files directly since we're not using Zeitwerk
require "vident/version"
require "vident/base"
require "vident/stable_id"
require "vident/attributes/not_typed"
require "vident/component"
require "vident/root_component"

# Determine which dummy app to use based on the test file path
# This allows test files in subdirectories to load the correct dummy app
# Get the current file that required this test_helper
# If we can't determine it, fall back to the main vident dummy app
caller_file = caller.first.to_s.split(":").first
caller_dir = caller_file ? File.dirname(caller_file) : nil

# Extract the gem name from the path to determine which dummy app to use
gem_name = if caller_dir
  parts = caller_dir.split("/")
  # Look for test/gem-name pattern
  test_index = parts.index("test")
  test_index && test_index < parts.length - 1 ? parts[test_index + 1] : "vident"
else
  "vident"
end

# Set up a minimal test environment
require "minitest/autorun"

# Load fixtures from the engine if needed
if ActiveSupport::TestCase.respond_to?(:fixture_path=)
  ActiveSupport::TestCase.fixture_path = File.expand_path("fixtures", __dir__)
  ActionDispatch::IntegrationTest.fixture_path = ActiveSupport::TestCase.fixture_path
  ActiveSupport::TestCase.file_fixture_path = ActiveSupport::TestCase.fixture_path + "/files"
  ActiveSupport::TestCase.fixtures :all
end