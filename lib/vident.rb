# frozen_string_literal: true

require "vident/version"
require "vident/engine"

module Vident
  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration) if block_given?
      configuration
    end
  end

  class Configuration
    attr_accessor :include_i18n_helpers

    def initialize
      @include_i18n_helpers = true
    end
  end
end
