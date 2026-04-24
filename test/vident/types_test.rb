# frozen_string_literal: true

require "test_helper"
require "vident"

module Vident
  class TypesTest < Minitest::Test
    def test_stimulus_controllers_accepts_strings_and_symbols
      klass = Class.new(::Vident::Phlex::HTML) do
        define_singleton_method(:name) { "ButtonComponent" }
        prop :extra_controllers, ::Vident::Types::StimulusControllers, default: -> { [] }
      end
      klass.new(extra_controllers: ["tooltip"])
      klass.new(extra_controllers: [:tooltip])
      klass.new(extra_controllers: [::Vident::Stimulus::Controller.new(path: "a", name: "a")])
    end

    def test_stimulus_controllers_rejects_integers
      klass = Class.new(::Vident::Phlex::HTML) do
        define_singleton_method(:name) { "ButtonComponent" }
        prop :extra_controllers, ::Vident::Types::StimulusControllers, default: -> { [] }
      end
      assert_raises(Literal::TypeError) { klass.new(extra_controllers: [42]) }
    end

    def test_stimulus_values_accepts_hash_array_or_value_instance
      klass = Class.new(::Vident::Phlex::HTML) do
        define_singleton_method(:name) { "CardComponent" }
        prop :extra_values, ::Vident::Types::StimulusValues, default: -> { {} }
      end
      klass.new(extra_values: {count: 1})
      klass.new(extra_values: [[:count, 1]])
    end

    def test_all_expected_aliases_exist
      %i[
        StimulusControllers StimulusActions StimulusTargets StimulusOutlets
        StimulusValues StimulusParams StimulusClasses
      ].each do |name|
        assert ::Vident::Types.const_defined?(name), "expected ::Vident::Types::#{name} to exist"
      end
    end

    def test_types_are_reused_by_built_in_props
      # Built-in stimulus_* props on every Vident component reference the same
      # Literal type objects that ::Vident::Types exposes.
      builder = Class.new(::Vident::Phlex::HTML) do
        define_singleton_method(:name) { "TestComponent" }
      end
      prop = builder.literal_properties.properties_index[:stimulus_values]
      assert_same ::Vident::Types::StimulusValues, prop.type
    end
  end
end
