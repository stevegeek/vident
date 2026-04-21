# frozen_string_literal: true

module Vident
  module PublicApiSpec
    # Covers: instance `stimulus_<kind>(*)` singular + plural parser methods
    # on every component (14 total). These are documented public API — users
    # splat their `#to_h` into tag options via `data: {**comp.stimulus_target(:x)}`.
    # V1 returned String-keyed Hashes and V1-namespaced classes; V2 unifies on
    # Symbol keys and Vident-namespaced classes. Tests below assert V1 shape
    # and skip on V2 — v2_instance_parsers.rb asserts the unified V2 shape.
    module InstanceParsers
      # ---- singular: returns a typed Value (V1 types) ------------------

      # ---- plural collection shapes (V1) -------------------------------

      # Action and Controller collections already used Symbol keys in V1 —
      # these tests pass on BOTH adapters.
      def test_stimulus_actions_collection_to_h_uses_symbol_key
        klass = define_component(name: "ButtonComponent")
        assert_equal({action: "button-component#click button-component#hover"},
          klass.new.stimulus_actions(:click, :hover).to_h)
      end

      def test_stimulus_controllers_collection_to_h_uses_symbol_key
        klass = define_component(name: "ButtonComponent")
        assert_equal({controller: "my-ctrl other"},
          klass.new.stimulus_controllers("my_ctrl", "other").to_h)
      end

      # ---- pass-through semantics --------------------------------------

      def test_singular_pass_through_pre_built_value
        klass = define_component(name: "FormComponent")
        comp = klass.new
        value = comp.stimulus_target(:input)
        assert_same value, comp.stimulus_target(value)
      end

      def test_plural_pass_through_pre_built_collection
        klass = define_component(name: "FormComponent")
        comp = klass.new
        coll = comp.stimulus_targets(:a, :b)
        assert_same coll, comp.stimulus_targets(coll)
      end
    end
  end
end
