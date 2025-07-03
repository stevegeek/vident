# frozen_string_literal: true

require "active_support"
require "active_support/concern"
require "literal"

require "vident/version"
require "vident/component"
require "vident/stable_id"
require "vident/attributes/not_typed"
require "vident/root_component"

require "vident/engine" if defined?(Rails)

module Vident; end
