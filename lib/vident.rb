# frozen_string_literal: true

require_relative "vident/version"
require_relative "vident/railtie"

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
require_relative "vident/root_component/using_better_html"
require_relative "vident/root_component/using_phlex_html"
require_relative "vident/root_component/using_view_component"
require_relative "vident/base"
require_relative "vident/component"
require_relative "vident/typed_component"
require_relative "vident/caching/cache_key"

require_relative "vident/testing/attributes_tester"
require_relative "vident/testing/auto_test"

# TODO: what if not using view_component?
require_relative "vident/test_case"
