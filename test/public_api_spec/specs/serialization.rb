# frozen_string_literal: true

module Vident
  module PublicApiSpec
    # Covers: how values and params serialize into their `data-*` attribute
    # strings. This is the JS-side JSON.parse boundary — regressions here
    # silently feed wrong types to Stimulus's value parsers.
    #
    # Rules (stimulus_attribute_base.rb:56-61):
    #   - Array, Hash → value.to_json
    #   - everything else → value.to_s
    # Plus two sentinels:
    #   - nil → attribute omitted entirely (nil-drop rule)
    #   - Vident::StimulusNull → attribute present, literal value "null"
    module Serialization
      # ---- primitive types ------------------------------------------------

      def test_value_string
        klass = define_component(name: "CardComponent") do
          stimulus { values label: "hello world" }
        end
        assert_includes render(klass.new), 'data-card-component-label-value="hello world"'
      end

      def test_value_integer
        klass = define_component(name: "CardComponent") do
          stimulus { values count: 42 }
        end
        assert_includes render(klass.new), 'data-card-component-count-value="42"'
      end

      def test_value_float
        klass = define_component(name: "CardComponent") do
          stimulus { values ratio: 3.14 }
        end
        assert_includes render(klass.new), 'data-card-component-ratio-value="3.14"'
      end

      def test_value_boolean_true
        klass = define_component(name: "CardComponent") do
          stimulus { values open: true }
        end
        assert_includes render(klass.new), 'data-card-component-open-value="true"'
      end

      def test_value_boolean_false_does_not_drop
        # SPEC-NOTE: false is NOT a nil-drop trigger. The filter_map refactor
        # in the past broke this; current behaviour preserves false. Stimulus
        # parses "false" as Boolean false.
        klass = define_component(name: "CardComponent") do
          stimulus { values open: false }
        end
        assert_includes render(klass.new), 'data-card-component-open-value="false"'
      end

      # ---- Array / Hash → JSON -------------------------------------------

      def test_value_array_serializes_as_json
        klass = define_component(name: "CardComponent") do
          stimulus { values tags: [1, 2, 3] }
        end
        assert_includes render(klass.new), 'data-card-component-tags-value="[1,2,3]"'
      end

      def test_value_mixed_array_serializes_as_json
        klass = define_component(name: "CardComponent") do
          stimulus { values items: ["a", 1, true] }
        end
        assert_includes render(klass.new),
          %q{data-card-component-items-value="["a",1,true]"}
      end

      def test_value_hash_serializes_as_json
        klass = define_component(name: "CardComponent") do
          stimulus { values cfg: {a: 1, b: "x"} }
        end
        assert_includes render(klass.new),
          %q{data-card-component-cfg-value="{"a":1,"b":"x"}"}
      end

      def test_value_nested_hash_serializes_as_json
        klass = define_component(name: "CardComponent") do
          stimulus { values cfg: {outer: {inner: [1, 2]}} }
        end
        assert_includes render(klass.new),
          %q{data-card-component-cfg-value="{"outer":{"inner":[1,2]}}"}
      end

      # ---- StimulusNull sentinel -----------------------------------------

      def test_stimulus_null_serializes_to_literal_null
        klass = define_component(name: "CardComponent") do
          stimulus { values config: ::Vident::StimulusNull }
        end
        assert_includes render(klass.new), 'data-card-component-config-value="null"'
      end

      def test_stimulus_null_from_proc_serializes_to_literal_null
        klass = define_component(name: "CardComponent") do
          stimulus { values cfg: -> { ::Vident::StimulusNull } }
        end
        assert_includes render(klass.new), 'data-card-component-cfg-value="null"'
      end

      def test_stimulus_null_distinct_from_nil_drop
        # Locks the distinction: nil drops the attribute; StimulusNull emits it
        # with value "null". Both must be exercised to ensure Vident 2.0
        # doesn't collapse them.
        nil_klass = define_component(name: "CardComponent") do
          stimulus { values x: nil }
        end
        null_klass = define_component(name: "CardComponent") do
          stimulus { values x: ::Vident::StimulusNull }
        end
        refute_match(/x-value/, render(nil_klass.new))
        assert_includes render(null_klass.new), 'data-card-component-x-value="null"'
      end

      # ---- nil-drop rule --------------------------------------------------

      def test_value_proc_returning_nil_drops
        klass = define_component(name: "CardComponent") do
          stimulus { values maybe: -> { nil } }
        end
        refute_match(/maybe-value/, render(klass.new))
      end

      def test_value_static_nil_drops
        klass = define_component(name: "CardComponent") do
          stimulus { values missing: nil }
        end
        refute_match(/missing-value/, render(klass.new))
      end

      def test_value_conditional_proc_drops_on_nil_branch
        klass = define_component(name: "CardComponent") do
          prop :flag, _Boolean, default: false
          stimulus { values dynamic: -> { @flag ? "on" : nil } }
        end
        refute_match(/dynamic-value/, render(klass.new(flag: false)))
        assert_includes render(klass.new(flag: true)),
          'data-card-component-dynamic-value="on"'
      end

      # ---- params use the same serializer --------------------------------

      def test_param_array_serializes_as_json
        klass = define_component(name: "ButtonComponent") do
          stimulus { params ids: [1, 2, 3] }
        end
        assert_includes render(klass.new),
          'data-button-component-ids-param="[1,2,3]"'
      end

      def test_param_hash_serializes_as_json
        klass = define_component(name: "ButtonComponent") do
          stimulus { params cfg: {k: "v"} }
        end
        assert_includes render(klass.new),
          %q{data-button-component-cfg-param="{"k":"v"}"}
      end

      def test_param_stimulus_null
        klass = define_component(name: "ButtonComponent") do
          stimulus { params x: ::Vident::StimulusNull }
        end
        assert_includes render(klass.new),
          'data-button-component-x-param="null"'
      end

      def test_param_nil_drops
        klass = define_component(name: "ButtonComponent") do
          stimulus { params maybe: nil }
        end
        refute_match(/maybe-param/, render(klass.new))
      end
    end
  end
end
