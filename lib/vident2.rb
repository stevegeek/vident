# frozen_string_literal: true

require "active_support"
require "active_support/concern"
require "literal"

require "vident2/version"

# Vident 2.0 — synthesis rearchitecture per doc/reviews/wave-4-synthesis.md.
# Built side-by-side with Vident 1.x during development; renamed to Vident
# at release. Nothing here is public yet — every constant may churn until
# 2.0.0.
module Vident2
end

# Vident2 currently borrows Vident::StableId for id sequencing — see
# #id in component.rb. A clean-room Vident2::StableId will land if we
# need to diverge the API; otherwise the rename collapses the reference.
require "vident"

# Stimulus value classes (public) + internal registry. These are the
# typed building blocks the DSL / Resolver / Draft will assemble in
# later phases; loading them now is side-effect-free (pure value classes).
require "vident2/engine" if defined?(Rails::Engine)
require "vident2/error"
require "vident2/stimulus/naming"
require "vident2/stimulus/null"
require "vident2/stimulus/controller"
require "vident2/stimulus/action"
require "vident2/stimulus/target"
require "vident2/stimulus/outlet"
require "vident2/stimulus/value"
require "vident2/stimulus/param"
require "vident2/stimulus/class_map"
require "vident2/stimulus/collection"
require "vident2/internals/registry"
require "vident2/internals/declaration"
require "vident2/internals/declarations"
require "vident2/internals/dsl"
require "vident2/internals/draft"
require "vident2/internals/plan"
require "vident2/internals/resolver"
require "vident2/internals/attribute_writer"
require "vident2/internals/class_list_builder"

require "vident2/tailwind"
require "vident2/caching"

require "vident2/component"

require "vident2/phlex"
require "vident2/view_component"
