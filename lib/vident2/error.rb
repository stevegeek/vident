# frozen_string_literal: true

module Vident2
  # Root of the Vident2 error hierarchy. Every gem-raised exception
  # inherits from this; consumers can rescue by category.
  class Error < StandardError; end

  # Raised at class-definition time when a `stimulus do` block is
  # structurally incompatible with the class (e.g. a `no_stimulus_controller`
  # class emitting DSL entries). Carries a caller location pointing at
  # the offending `stimulus do` call.
  class DeclarationError < Error; end

  # Raised when a value-class parser cannot make sense of its arguments.
  # Subclass of DeclarationError because most parse failures originate
  # from DSL input recorded at class load.
  class ParseError < DeclarationError; end

  # Raised when a proc evaluated during render resolution fails or
  # returns an unusable shape.
  class RenderError < Error; end

  # Raised when a mutator (e.g. `add_stimulus_actions`) is invoked on a
  # sealed Draft.
  class StateError < Error; end

  # Raised for misconfiguration at the gem or host level (e.g. unknown
  # StableId strategy).
  class ConfigurationError < Error; end
end
