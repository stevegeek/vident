# Entry point for vident-typed-minitest
require 'vident'
require 'vident/typed/minitest/version'
require 'vident/typed/minitest/attributes_tester'
require 'vident/typed/minitest/auto_test'
require 'vident/typed/minitest/test_case'
require 'vident/typed/minitest/engine' if defined?(Rails)
