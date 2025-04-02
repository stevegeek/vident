# frozen_string_literal: true

module Vident
  module Typed
    module Minitest
      class AttributesTester
        def initialize(test_configurations)
          @test_configurations = test_configurations
        end

        # Generates attribute hashes for all permutations of the given valid values.
        def valid_configurations
          # Expands any auto generated values and returns all attributes and their values
          test_attrs = prepare_attributes_to_test

          # The first permutation is the initial state
          initial_state = prepare_initial_test_state(test_attrs)

          # Create remaining permutations
          test_attrs.flat_map do |attr_name, values|
            values.map { |v| initial_state.merge(attr_name => v) }
          end
        end

        # Generates attribute hashes for all permutations of the given invalid values.
        def invalid_configurations
          return [] unless invalid_configured?

          # prepare a valid initial state, then add any attrs that have :invalid
          initial_state = prepare_initial_test_state(prepare_attributes_to_test)

          # Merge in the invalid permutations
          test_configurations.inject([]) do |memo, attr|
            key, opts = attr
            next memo += nil if opts == :strict_boolean
            if opts.is_a?(Hash)
              values = if opts[:invalid].nil? && opts[:valid].is_a?(Hash)
                # If no invalid key specified we generate based on whats valid
                config = invalid_attribute_test_values_for(opts[:valid][:type], opts[:valid])
                (config&.fetch(:invalid, []) || []) + (config&.fetch(:converts, []) || [])
              elsif opts[:invalid].is_a?(Array)
                opts[:invalid]
              end

              memo += values.map { |i| initial_state.merge(key => i) } if values
            end
            memo
          end
        end

        private

        attr_reader :test_configurations

        def invalid_configured?
          test_configurations.values.any? { |v| v.respond_to?(:key?) && v.key?(:invalid) }
        end

        def prepare_attributes_to_test
          test_configurations.transform_values do |attr_config|
            next [true, false, nil] if attr_config == :boolean
            next [true, false] if attr_config == :strict_boolean
            valid = attr_config[:valid]
            raise "Ensure :valid attributes configuration is provided" unless valid
            next valid if valid.is_a?(Array)
            attribute_test_values_for(valid)
          end
        end

        def prepare_initial_test_state(test_attrs)
          initial_state = {}
          test_attrs.each { |attr_name, values| initial_state[attr_name] = values.first }
          initial_state
        end

        def attribute_test_values_for(options)
          type = parse_type(options[:type])
          return options[:in] if options[:in]
          values =
            case type
            when :string, "String"
              s = (1..8).map { |l| ::Faker::String.random(length: l) }
              s.prepend "test string"
              s = s.select(&:present?)
              s << "" if options[:allow_blank]
              s
            when :boolean
              [false, true]
            when :float, "Float"
              (1..3).map { Faker::Number.positive } + (1..3).map { Faker::Number.negative }
            when :numeric, "Numeric"
              (1..3).map { Faker::Number.positive } + [1, 5]
            when :integer, "Integer"
              min = options[:min] || -10_000
              max = options[:max] || 10_000
              (1..3).map { Kernel.rand(min..max) }
            when :array, "Array"
              a =
                if options[:sub_type] == Numeric
                  [[1, 2, 3], [0.3, 2, 0.002]]
                elsif options[:sub_type]
                  [[options[:sub_type].new]]
                else
                  [%i[a b c], [1, 2, 3], %w[a b]]
                end
              a << [] if options[:allow_blank]
              a
            when :any
              [false, 1245, {}, :df, "hi"]
            when :hash, "Hash"
              a = [{a: 1}]
              a << {} if options[:allow_blank]
              a
            when :symbol, "Symbol"
              %i[a b c]
            else
              raise StandardError, "Attribute type not understood (#{type})"
            end

          if options[:allow_nil] || !options[:default].nil? || (options[:allow_blank] && options[:allow_nil].nil?)
            values << nil
          end
          values
        end

        def invalid_attribute_test_values_for(type, options)
          values = case parse_type(type)
          when :string, "String"
            # All values are also convertable to string
            string_values(options)
          when :boolean
            # All values are also convertable to boolean with !!
            boolean_values
          when :float, "Float"
            # Not all values are convertable to float
            float_values
          when :numeric, "Numeric"
            numeric_values
          when :integer, "Integer"
            # Not all values are convertable to integer
            integer_values
          when :array, "Array"
            # Not all values are convertable to array
            array_values(options)
          when :any
            # There are no invalid values
            any_values
          when :hash, "Hash"
            hash_values(options)
          when :symbol, "Symbol"
            symbol_values
          else
            raise StandardError, "Attribute type not understood (#{type})"
          end

          if options[:default].nil? && (!options[:allow_nil] || (!options[:allow_blank] && options[:allow_nil] != true))
            values[:invalid] << nil
          end
          values
        end

        def parse_type(type)
          type.is_a?(Symbol) ? type : type.name
        end

        def string_values(options)
          a = {converts: [false, 1245, 1.0, {}, :df, []], invalid: []}
          a[:invalid] << "" if options[:allow_blank] == false
          a
        end

        def boolean_values
          {converts: ["sdf", 234, 3.5, {}, :sdf, []], invalid: []}
        end

        def float_values
          {converts: [234, "12.2"], invalid: ["sdf", 234, {}, :sdf, [], false]}
        end

        def numeric_values
          {converts: ["12.2"], invalid: ["sdf", {}, :sdf, [], false]}
        end

        def integer_values
          {converts: [234.0, "123", "sdf"], invalid: [{}, :sdf, [], false]}
        end

        def array_values(options)
          a = if options[:sub_type]
            {converts: [{}, [{}]], invalid: ["sdf", [123], [Class.new]]}
          else
            {converts: [{}], invalid: ["sdf", 234, 3.5, :sdf, false]}
          end
          a[:invalid] << [] if options[:allow_blank] == false
          a
        end

        def any_values
          {converts: [], invalid: []}
        end

        def hash_values(options)
          a = {converts: [[], [[:a, 1], [:b, 2]]], invalid: [:sdf, false, "boo", 123]}
          a[:invalid] << {} if options[:allow_blank] == false
          a
        end

        def symbol_values
          {converts: ["foo"], invalid: [{}, false, [], 123]}
        end
      end
    end
  end
end
