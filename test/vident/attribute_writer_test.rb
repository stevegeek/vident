# frozen_string_literal: true

require "test_helper"
require "vident"

module Vident
  # AttributeWriter is a stateless Plan -> Hash{Symbol => String} fold.
  # Its contract: one output key per kind's `to_data_hash`, Symbol keys
  # throughout, empty plan -> empty hash.
  class AttributeWriterTest < Minitest::Test
    def setup
      @controller = ::Vident::Stimulus::Controller.new(
        path: "button_component", name: "button-component"
      )
    end

    def plan_with(**collections)
      empty = ::Vident::Internals::Registry.names.to_h { |n| [n, [].freeze] }
      ::Vident::Internals::Plan.new(**empty.merge(collections))
    end

    # ---- Empty plan -----------------------------------------------------

    def test_empty_plan_returns_empty_hash
      assert_equal({}, ::Vident::Internals::AttributeWriter.call(plan_with))
    end

    # ---- Controllers ----------------------------------------------------

    def test_controllers_space_joined_under_controller_key
      c2 = ::Vident::Stimulus::Controller.new(path: "tooltip", name: "tooltip")
      plan = plan_with(controllers: [@controller, c2])
      assert_equal({controller: "button-component tooltip"},
        ::Vident::Internals::AttributeWriter.call(plan))
    end

    def test_single_controller_emits_just_the_name
      plan = plan_with(controllers: [@controller])
      assert_equal({controller: "button-component"},
        ::Vident::Internals::AttributeWriter.call(plan))
    end

    # ---- Actions --------------------------------------------------------

    def test_actions_space_joined_under_action_key
      a1 = ::Vident::Stimulus::Action.parse(:click, implied: @controller)
      a2 = ::Vident::Stimulus::Action.parse(:submit, implied: @controller)
      plan = plan_with(actions: [a1, a2])
      assert_equal({action: "button-component#click button-component#submit"},
        ::Vident::Internals::AttributeWriter.call(plan))
    end

    # ---- Targets (grouped by controller) --------------------------------

    def test_targets_grouped_by_controller
      t1 = ::Vident::Stimulus::Target.parse(:input, implied: @controller)
      t2 = ::Vident::Stimulus::Target.parse(:output, implied: @controller)
      plan = plan_with(targets: [t1, t2])
      hash = ::Vident::Internals::AttributeWriter.call(plan)
      assert_equal({"button-component-target": "input output"}, hash)
    end

    def test_targets_across_controllers_get_separate_keys
      c2 = ::Vident::Stimulus::Controller.new(path: "admin", name: "admin")
      t1 = ::Vident::Stimulus::Target.parse(:input, implied: @controller)
      t2 = ::Vident::Stimulus::Target.parse(:row, implied: c2)
      plan = plan_with(targets: [t1, t2])
      hash = ::Vident::Internals::AttributeWriter.call(plan)
      assert_equal "input", hash[:"button-component-target"]
      assert_equal "row", hash[:"admin-target"]
    end

    # ---- Values ---------------------------------------------------------

    def test_values_emit_one_key_per_entry
      v1 = ::Vident::Stimulus::Value.parse(:title, "Hi", implied: @controller)
      v2 = ::Vident::Stimulus::Value.parse(:count, 7, implied: @controller)
      plan = plan_with(values: [v1, v2])
      hash = ::Vident::Internals::AttributeWriter.call(plan)
      assert_equal "Hi", hash[:"button-component-title-value"]
      assert_equal "7", hash[:"button-component-count-value"]
    end

    # ---- Params ---------------------------------------------------------

    def test_params_emit_one_key_per_entry
      p1 = ::Vident::Stimulus::Param.parse(:kind, "promote", implied: @controller)
      plan = plan_with(params: [p1])
      assert_equal({"button-component-kind-param": "promote"},
        ::Vident::Internals::AttributeWriter.call(plan))
    end

    # ---- ClassMaps ------------------------------------------------------

    def test_class_maps_emit_one_key_per_entry
      cm = ::Vident::Stimulus::ClassMap.parse(:loading, "opacity-50", implied: @controller)
      plan = plan_with(class_maps: [cm])
      assert_equal({"button-component-loading-class": "opacity-50"},
        ::Vident::Internals::AttributeWriter.call(plan))
    end

    # ---- Outlets --------------------------------------------------------

    def test_outlets_emit_one_key_per_entry
      o = ::Vident::Stimulus::Outlet.parse(:modal, Vident::Selector(".modal"), implied: @controller)
      plan = plan_with(outlets: [o])
      hash = ::Vident::Internals::AttributeWriter.call(plan)
      assert_equal ".modal", hash[:"button-component-modal-outlet"]
    end

    # ---- Cross-kind merge: one call produces one combined Hash ----------

    def test_all_kinds_together_in_one_call
      a = ::Vident::Stimulus::Action.parse(:click, implied: @controller)
      t = ::Vident::Stimulus::Target.parse(:input, implied: @controller)
      v = ::Vident::Stimulus::Value.parse(:count, 1, implied: @controller)
      plan = plan_with(
        controllers: [@controller],
        actions: [a],
        targets: [t],
        values: [v]
      )
      hash = ::Vident::Internals::AttributeWriter.call(plan)
      assert_equal "button-component", hash[:controller]
      assert_equal "button-component#click", hash[:action]
      assert_equal "input", hash[:"button-component-target"]
      assert_equal "1", hash[:"button-component-count-value"]
    end

    # ---- Keys are Symbols -----------------------------------------------

    def test_returned_keys_are_symbols
      a = ::Vident::Stimulus::Action.parse(:click, implied: @controller)
      t = ::Vident::Stimulus::Target.parse(:input, implied: @controller)
      plan = plan_with(controllers: [@controller], actions: [a], targets: [t])
      hash = ::Vident::Internals::AttributeWriter.call(plan)
      hash.each_key { |k| assert_kind_of Symbol, k }
    end

    # ---- Null sentinel values survive through the writer ----------------

    def test_stimulus_null_value_renders_as_literal_null
      v = ::Vident::Stimulus::Value.parse(:cfg, ::Vident::Stimulus::Null, implied: @controller)
      plan = plan_with(values: [v])
      hash = ::Vident::Internals::AttributeWriter.call(plan)
      assert_equal "null", hash[:"button-component-cfg-value"]
    end
  end
end
