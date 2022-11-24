# frozen_string_literal: true

require_relative "vident/version"

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

require_relative "vident/stable_id"
require_relative "vident/root_component/base"
require_relative "vident/root_component/phlex_html"
require_relative "vident/root_component/view_component"
require_relative "vident/base"
require_relative "vident/component"
require_relative "vident/typed_component"
