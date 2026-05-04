# frozen_string_literal: true

require "active_support"
require "active_support/concern"
require "literal"

require "vident/version"

module Vident
end

require "vident/engine" if defined?(Rails::Engine)
require "vident/error"
require "vident/stable_id"
require "vident/stimulus_null"

require "vident/stimulus/naming"
require "vident/stimulus/null"
require "vident/stimulus/selector"
require "vident/stimulus/controller"
require "vident/stimulus/action"
require "vident/stimulus/target"
require "vident/stimulus/outlet"
require "vident/stimulus/value"
require "vident/stimulus/param"
require "vident/stimulus/class_map"
require "vident/stimulus/collection"
require "vident/types"
require "vident/internals/registry"
require "vident/internals/declaration"
require "vident/internals/declarations"
require "vident/internals/dsl"
require "vident/internals/draft"
require "vident/internals/plan"
require "vident/internals/resolver"
require "vident/internals/attribute_writer"
require "vident/internals/class_list_builder"

require "vident/capabilities/tailwind"
require "vident/capabilities/caching"
require "vident/capabilities/declarable"
require "vident/capabilities/identifiable"
require "vident/capabilities/stimulus_declaring"
require "vident/capabilities/stimulus_parsing"
require "vident/capabilities/stimulus_mutation"
require "vident/capabilities/stimulus_draft"
require "vident/capabilities/stimulus_data_emitting"
require "vident/capabilities/stimulus_attribute_strings"
require "vident/capabilities/class_list_building"
require "vident/capabilities/root_element_rendering"
require "vident/capabilities/child_element_rendering"
require "vident/capabilities/inspectable"

require "vident/tailwind"
require "vident/caching"

require "vident/component"

# Adapter modules (`vident/phlex`, `vident/view_component`) ship in their own
# gems and are loaded by their own entry points (`lib/vident-phlex.rb`,
# `lib/vident-view_component.rb`). Do not require them unconditionally here —
# they only exist when the corresponding adapter gem is installed.
