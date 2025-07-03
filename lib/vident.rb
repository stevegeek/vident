# frozen_string_literal: true

require "active_support"
require "active_support/concern"
require "literal"

require "vident/version"
require "vident/tailwind"
require "vident/component"
require "vident/stable_id"
require "vident/stimulus_attribute"
require "vident/stimulus_action"
require "vident/stimulus_target"
require "vident/stimulus_outlet"
require "vident/stimulus_value"
require "vident/stimulus_class"
require "vident/stimulus_controller"
require "vident/root_component"

require "vident/engine" if defined?(Rails)

module Vident; end
