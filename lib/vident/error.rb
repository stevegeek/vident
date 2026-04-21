# frozen_string_literal: true

module Vident
  # Base for all gem-raised exceptions; consumers can rescue by category.
  class Error < StandardError; end

  class DeclarationError < Error; end
  class ParseError < Error; end
  class RenderError < Error; end
  class StateError < Error; end
  class ConfigurationError < Error; end
end
