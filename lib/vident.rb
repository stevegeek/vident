# frozen_string_literal: true

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


require "active_support"
require "active_support/concern"
require "literal"

require "vident/version"
require "vident/tailwind"

require "vident/stimulus_attribute_base"
require "vident/stimulus_controller"
require "vident/stimulus_action"
require "vident/stimulus_target"
require "vident/stimulus_outlet"
require "vident/stimulus_value"
require "vident/stimulus_class"

require "vident/stimulus_collection_base"
require "vident/stimulus_controller_collection"
require "vident/stimulus_action_collection"
require "vident/stimulus_target_collection"
require "vident/stimulus_outlet_collection"
require "vident/stimulus_value_collection"
require "vident/stimulus_class_collection"


require "vident/stimulus_attributes"
require "vident/stimulus_data_attribute_builder"

require "vident/tag_helper"
require "vident/stable_id"
require "vident/class_list_builder"

require "vident/stimulus_component"
require "vident/component_class_lists"
require "vident/component_attribute_resolver"

require "vident/component"

require "vident/engine" if defined?(Rails)

module Vident; end
