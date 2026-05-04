# frozen_string_literal: true

require "literal"
require_relative "stimulus/selector"
require_relative "stimulus/controller"
require_relative "stimulus/action"
require_relative "stimulus/target"
require_relative "stimulus/outlet"
require_relative "stimulus/value"
require_relative "stimulus/param"
require_relative "stimulus/class_map"

module Vident
  # Canonical Literal type unions for the seven `stimulus_*:` props.
  # The same objects are used internally by `Vident::Capabilities::Declarable`
  # for the built-in props; exposed here so user components can reference
  # them when adding matching props of their own.
  module Types
    extend Literal::Types

    StimulusControllers = _Array(_Union(String, Symbol, ::Vident::Stimulus::Controller))
    StimulusActions = _Array(_Union(String, Symbol, Array, Hash, ::Vident::Stimulus::Action))
    StimulusTargets = _Array(_Union(String, Symbol, Array, ::Vident::Stimulus::Target))
    StimulusOutlets = _Array(_Union(String, Symbol, Array, ::Vident::Stimulus::Outlet))
    StimulusValues = _Union(_Hash(Symbol, _Any), Array, ::Vident::Stimulus::Value)
    StimulusParams = _Union(_Hash(Symbol, _Any), Array, ::Vident::Stimulus::Param)
    StimulusClasses = _Union(_Hash(Symbol, _Any), Array, ::Vident::Stimulus::ClassMap)
  end
end
