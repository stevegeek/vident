# frozen_string_literal: true

require "test_helper"
require "vident"

module Vident
  class DSLTest < Minitest::Test
    # Factory for a fresh anonymous component class per test, so mutating
    # class state (stimulus do, no_stimulus_controller) doesn't leak.
    def make_component(&block)
      Class.new do
        include ::Vident::Component
        class_eval(&block) if block
      end
    end

    # ---- Empty baseline ------------------------------------------------

    def test_fresh_component_has_empty_declarations
      cls = make_component
      assert_equal ::Vident::Internals::Declarations.empty, cls.declarations
    end

    def test_empty_declarations_any_is_false
      cls = make_component
      refute cls.declarations.any?
    end

    def test_empty_declarations_all_fields_empty
      d = ::Vident::Internals::Declarations.empty
      %i[controllers actions targets outlets values params class_maps values_from_props].each do |field|
        assert_empty d.public_send(field), "#{field} should be empty"
      end
    end

    def test_declarations_are_frozen
      cls = make_component { stimulus { action :click } }
      assert_predicate cls.declarations, :frozen?
    end

    def test_declarations_fields_are_frozen_arrays
      cls = make_component {
        stimulus {
          action :click
          value :x, static: 1
        }
      }
      assert_predicate cls.declarations.actions, :frozen?
      assert_predicate cls.declarations.values, :frozen?
    end

    # ---- actions -------------------------------------------------------

    def test_actions_plural_records_one_entry_per_symbol
      cls = make_component { stimulus { actions :click, :submit } }
      assert_equal 2, cls.declarations.actions.size
      assert_equal [:click], cls.declarations.actions[0].args
      assert_equal [:submit], cls.declarations.actions[1].args
    end

    def test_action_singular_records_one_entry
      cls = make_component { stimulus { action :click } }
      assert_equal 1, cls.declarations.actions.size
      assert_equal [:click], cls.declarations.actions[0].args
    end

    def test_action_with_multiple_args_records_tuple
      cls = make_component { stimulus { action :click, :handle_click } }
      assert_equal [[:click, :handle_click]], cls.declarations.actions.map(&:args)
    end

    def test_action_with_hash_descriptor
      cls = make_component do
        stimulus { action({event: :submit, method: :handle_submit}) }
      end
      first = cls.declarations.actions.first
      assert_equal({event: :submit, method: :handle_submit}, first.args.first)
    end

    # ---- targets -------------------------------------------------------

    def test_targets_plural_records_one_entry_per_symbol
      cls = make_component { stimulus { targets :input, :output } }
      assert_equal 2, cls.declarations.targets.size
      assert_equal [:input], cls.declarations.targets[0].args
      assert_equal [:output], cls.declarations.targets[1].args
    end

    def test_target_singular_records_one_entry
      cls = make_component { stimulus { target :submit_button } }
      assert_equal 1, cls.declarations.targets.size
      assert_equal [:submit_button], cls.declarations.targets[0].args
    end

    # ---- values --------------------------------------------------------

    def test_values_plural_records_one_entry_per_pair
      cls = make_component { stimulus { values url: "https://x", count: 3 } }
      assert_equal 2, cls.declarations.values.size
      assert_equal [:url, :count], cls.declarations.values.map(&:first)
    end

    def test_value_singular_static_form
      cls = make_component { stimulus { value :count, static: 0 } }
      entry = cls.declarations.values.first
      assert_equal :count, entry.first
      assert_equal({static: 0}, entry.last.meta)
    end

    def test_value_singular_from_prop_form
      cls = make_component { stimulus { value :clicked_count, from_prop: true } }
      entry = cls.declarations.values.first
      assert_equal :clicked_count, entry.first
      assert_equal({from_prop: true}, entry.last.meta)
    end

    def test_value_singular_proc_form
      proc_val = -> { api_items_path }
      cls = make_component { stimulus { value :api_url, proc_val } }
      entry = cls.declarations.values.first
      assert_equal :api_url, entry.first
      assert_equal [proc_val], entry.last.args
    end

    def test_value_singular_literal_value_form
      cls = make_component { stimulus { value :url, "https://example.com" } }
      entry = cls.declarations.values.first
      assert_equal [:url, "https://example.com"], [entry.first, entry.last.args.first]
    end

    # ---- params --------------------------------------------------------

    def test_params_plural_records_one_entry_per_pair
      cls = make_component { stimulus { params item_id: 42, role: "admin" } }
      assert_equal 2, cls.declarations.params.size
    end

    def test_param_singular
      cls = make_component { stimulus { param :item_id, 42 } }
      entry = cls.declarations.params.first
      assert_equal :item_id, entry.first
      assert_equal [42], entry.last.args
    end

    # ---- classes (class_maps) -----------------------------------------

    def test_classes_plural_records_one_entry_per_pair
      cls = make_component do
        stimulus { classes loading: "opacity-50", active: "bg-blue" }
      end
      assert_equal 2, cls.declarations.class_maps.size
      assert_equal [:loading, :active], cls.declarations.class_maps.map(&:first)
    end

    def test_classes_accepts_proc_values
      dynamic = -> { "size-lg" }
      cls = make_component { stimulus { classes size: dynamic } }
      entry = cls.declarations.class_maps.first
      assert_equal [dynamic], entry.last.args
    end

    def test_class_map_singular
      cls = make_component { stimulus { class_map :loading, "opacity-50" } }
      entry = cls.declarations.class_maps.first
      assert_equal :loading, entry.first
      assert_equal ["opacity-50"], entry.last.args
    end

    # ---- outlets -------------------------------------------------------

    def test_outlets_kwargs_form
      cls = make_component { stimulus { outlets menu: ".js-menu", nav: ".nav" } }
      assert_equal 2, cls.declarations.outlets.size
    end

    def test_outlets_positional_hash_form
      cls = make_component do
        stimulus { outlets({"admin--users" => ".sel"}) }
      end
      assert_equal 1, cls.declarations.outlets.size
      assert_equal "admin--users", cls.declarations.outlets.first.first
    end

    def test_outlets_positional_plus_kwargs
      cls = make_component do
        stimulus { outlets({"admin--users" => ".a"}, menu: ".m") }
      end
      keys = cls.declarations.outlets.map(&:first)
      assert_includes keys, "admin--users"
      assert_includes keys, :menu
    end

    def test_outlets_non_hash_positional_raises
      assert_raises(ArgumentError) do
        make_component { stimulus { outlets :not_a_hash } }
      end
    end

    def test_outlet_singular
      cls = make_component { stimulus { outlet :menu, ".js-menu" } }
      entry = cls.declarations.outlets.first
      assert_equal :menu, entry.first
      assert_equal [".js-menu"], entry.last.args
    end

    def test_outlet_proc_value_preserved_in_declarations
      outlet_proc = -> { ".dyn-#{id}" }
      cls = make_component { stimulus { outlets modal: outlet_proc } }
      entry = cls.declarations.outlets.first
      assert_equal [outlet_proc], entry.last.args
      assert_respond_to entry.last.args.first, :call
    end

    def test_outlet_proc_singular_preserved
      outlet_proc = -> { ".modal" }
      cls = make_component { stimulus { outlet :modal, outlet_proc } }
      entry = cls.declarations.outlets.first
      assert_equal [outlet_proc], entry.last.args
    end

    # ---- controllers ---------------------------------------------------

    def test_controllers_plural
      cls = make_component { stimulus { controllers "admin/users" } }
      assert_equal 1, cls.declarations.controllers.size
      assert_equal ["admin/users"], cls.declarations.controllers[0].args
    end

    def test_controller_singular_with_alias
      cls = make_component { stimulus { controller "admin/users", as: :admin } }
      entry = cls.declarations.controllers.first
      assert_equal ["admin/users"], entry.args
      assert_equal({as: :admin}, entry.meta)
    end

    def test_controllers_plural_multiple
      cls = make_component { stimulus { controllers "a/b", "c/d" } }
      assert_equal 2, cls.declarations.controllers.size
    end

    # ---- values_from_props --------------------------------------------

    def test_values_from_props_single
      cls = make_component { stimulus { values_from_props :foo } }
      assert_equal [:foo], cls.declarations.values_from_props
    end

    def test_values_from_props_multiple
      cls = make_component { stimulus { values_from_props :foo, :bar } }
      assert_equal [:foo, :bar], cls.declarations.values_from_props
    end

    def test_values_from_props_accumulates_across_blocks
      cls = make_component do
        stimulus { values_from_props :foo }
        stimulus { values_from_props :bar }
      end
      assert_equal [:foo, :bar], cls.declarations.values_from_props
    end

    def test_values_from_props_dedupes
      cls = make_component do
        stimulus { values_from_props :foo }
        stimulus { values_from_props :foo, :bar }
      end
      assert_equal [:foo, :bar], cls.declarations.values_from_props
    end

    # ---- multi-block merging ------------------------------------------

    def test_multiple_stimulus_blocks_append_positional
      cls = make_component do
        stimulus { action :click }
        stimulus { action :submit }
      end
      assert_equal 2, cls.declarations.actions.size
    end

    def test_multiple_stimulus_blocks_append_targets
      cls = make_component do
        stimulus { target :a }
        stimulus { target :b }
      end
      assert_equal 2, cls.declarations.targets.size
    end

    def test_multiple_stimulus_blocks_last_write_wins_values
      cls = make_component do
        stimulus { value :count, static: 0 }
        stimulus { value :count, static: 99 }
      end
      assert_equal 1, cls.declarations.values.size
      assert_equal({static: 99}, cls.declarations.values.first.last.meta)
    end

    def test_multiple_stimulus_blocks_last_write_wins_outlets
      cls = make_component do
        stimulus { outlets menu: ".m1" }
        stimulus { outlets menu: ".m2" }
      end
      assert_equal 1, cls.declarations.outlets.size
      assert_equal [".m2"], cls.declarations.outlets.first.last.args
    end

    def test_multiple_stimulus_blocks_preserve_disjoint_keyed
      cls = make_component do
        stimulus { values a: 1 }
        stimulus { values b: 2 }
      end
      keys = cls.declarations.values.map(&:first)
      assert_equal [:a, :b], keys
    end

    # ---- parent -> subclass inheritance -------------------------------

    def test_subclass_sees_parent_declarations_without_stimulus_call
      parent = make_component { stimulus { action :parent_click } }
      child = Class.new(parent)
      assert_equal 1, child.declarations.actions.size
      assert_equal [:parent_click], child.declarations.actions[0].args
    end

    def test_subclass_with_own_stimulus_block_merges_atop_parent
      parent = make_component { stimulus { action :parent_click } }
      child = Class.new(parent) { stimulus { action :child_click } }
      assert_equal 2, child.declarations.actions.size
      assert_equal [:parent_click], child.declarations.actions[0].args
      assert_equal [:child_click], child.declarations.actions[1].args
    end

    def test_subclass_does_not_mutate_parent_declarations
      parent = make_component { stimulus { action :parent_click } }
      _child = Class.new(parent) { stimulus { action :child_click } }
      assert_equal 1, parent.declarations.actions.size
    end

    def test_grandchild_inherits_through_chain
      parent = make_component { stimulus { action :a } }
      child = Class.new(parent) { stimulus { action :b } }
      grandchild = Class.new(child) { stimulus { action :c } }
      assert_equal %i[a b c], grandchild.declarations.actions.map { _1.args.first }
    end

    def test_subclass_last_write_wins_on_keyed_values
      parent = make_component { stimulus { value :count, static: 0 } }
      child = Class.new(parent) { stimulus { value :count, static: 99 } }
      assert_equal 1, child.declarations.values.size
      assert_equal({static: 99}, child.declarations.values.first.last.meta)
    end

    def test_subclass_values_from_props_merges_without_duplicates
      parent = make_component { stimulus { values_from_props :foo } }
      child = Class.new(parent) { stimulus { values_from_props :foo, :bar } }
      assert_equal [:foo, :bar], child.declarations.values_from_props
    end

    def test_subclass_with_no_own_block_inherits_targets_and_values
      parent = make_component do
        stimulus do
          target :x
          value :n, static: 1
        end
      end
      child = Class.new(parent)
      assert_equal 1, child.declarations.targets.size
      assert_equal 1, child.declarations.values.size
    end

    # ---- no_stimulus_controller predicate -----------------------------

    def test_default_stimulus_controller_predicate_is_true
      cls = make_component
      assert cls.stimulus_controller?
    end

    def test_no_stimulus_controller_flips_predicate
      cls = make_component { no_stimulus_controller }
      refute cls.stimulus_controller?
    end

    def test_no_stimulus_controller_inherits_to_subclass
      parent = make_component { no_stimulus_controller }
      child = Class.new(parent)
      refute child.stimulus_controller?
    end

    def test_subclass_can_still_have_predicate_true_if_parent_allows
      parent = make_component
      child = Class.new(parent)
      assert child.stimulus_controller?
    end

    # ---- no_stimulus_controller + DSL => DeclarationError -------------

    def test_no_stimulus_controller_with_action_raises_declaration_error
      assert_raises(::Vident::DeclarationError) do
        make_component do
          no_stimulus_controller
          stimulus { action :click }
        end
      end
    end

    def test_no_stimulus_controller_with_target_raises
      assert_raises(::Vident::DeclarationError) do
        make_component do
          no_stimulus_controller
          stimulus { target :x }
        end
      end
    end

    def test_no_stimulus_controller_with_value_raises
      assert_raises(::Vident::DeclarationError) do
        make_component do
          no_stimulus_controller
          stimulus { value :n, static: 1 }
        end
      end
    end

    def test_no_stimulus_controller_with_outlet_raises
      assert_raises(::Vident::DeclarationError) do
        make_component do
          no_stimulus_controller
          stimulus { outlet :menu, ".x" }
        end
      end
    end

    def test_no_stimulus_controller_with_empty_block_does_not_raise
      cls = make_component do
        no_stimulus_controller
        stimulus {}
      end
      refute cls.stimulus_controller?
    end

    def test_declaration_error_message_names_the_class
      err = assert_raises(::Vident::DeclarationError) do
        make_component do
          no_stimulus_controller
          stimulus { action :click }
        end
      end
      # Anonymous class name is nil, so the message says "anonymous component".
      assert_match(/no_stimulus_controller/, err.message)
    end

    def test_declaration_error_message_includes_caller_location
      err = assert_raises(::Vident::DeclarationError) do
        make_component do
          no_stimulus_controller
          stimulus { action :click }
        end
      end
      assert_match(/dsl_test\.rb:/, err.message)
    end

    def test_no_stimulus_controller_after_stimulus_with_entries_raises
      err = assert_raises(::Vident::DeclarationError) do
        make_component do
          stimulus { action :click }
          no_stimulus_controller
        end
      end
      assert_match(/no_stimulus_controller/, err.message)
    end

    def test_no_stimulus_controller_after_empty_stimulus_block_allowed
      cls = make_component do
        stimulus {}
        no_stimulus_controller
      end
      refute cls.stimulus_controller?
    end

    def test_declaration_error_inherits_vident2_error
      assert_operator ::Vident::DeclarationError, :<, ::Vident::Error
    end

    def test_parse_error_inherits_error_not_declaration_error
      assert_operator ::Vident::ParseError, :<, ::Vident::Error
      refute_operator ::Vident::ParseError, :<, ::Vident::DeclarationError
    end

    def test_all_error_classes_exist
      [
        ::Vident::Error,
        ::Vident::DeclarationError,
        ::Vident::ParseError,
        ::Vident::RenderError,
        ::Vident::StateError,
        ::Vident::ConfigurationError
      ].each { |klass| assert klass < StandardError, "#{klass} should descend StandardError" }
    end

    # ---- Declarations record semantics --------------------------------

    def test_declarations_empty_singleton
      assert_same ::Vident::Internals::Declarations.empty,
        ::Vident::Internals::Declarations.empty
    end

    def test_declarations_merge_concatenates_positional
      a = ::Vident::Internals::Declarations.empty
      b = ::Vident::Internals::Declarations.new(
        controllers: [].freeze,
        actions: [::Vident::Internals::Declaration.of(:x)].freeze,
        targets: [].freeze,
        outlets: [].freeze,
        values: [].freeze,
        params: [].freeze,
        class_maps: [].freeze,
        values_from_props: [].freeze
      )
      merged = a.merge(b)
      assert_equal 1, merged.actions.size
    end

    def test_declarations_merge_last_write_wins_keyed
      d1 = ::Vident::Internals::Declaration.of("v1")
      d2 = ::Vident::Internals::Declaration.of("v2")
      a = ::Vident::Internals::Declarations.new(
        controllers: [].freeze, actions: [].freeze, targets: [].freeze,
        outlets: [].freeze,
        values: [[:count, d1]].freeze,
        params: [].freeze, class_maps: [].freeze, values_from_props: [].freeze
      )
      b = ::Vident::Internals::Declarations.new(
        controllers: [].freeze, actions: [].freeze, targets: [].freeze,
        outlets: [].freeze,
        values: [[:count, d2]].freeze,
        params: [].freeze, class_maps: [].freeze, values_from_props: [].freeze
      )
      merged = a.merge(b)
      assert_equal 1, merged.values.size
      assert_equal d2, merged.values.first.last
    end

    def test_declarations_any_true_when_populated
      cls = make_component { stimulus { action :click } }
      assert cls.declarations.any?
    end

    # ---- DSL returns self for chaining --------------------------------

    def test_dsl_methods_return_self_for_chaining
      dsl = ::Vident::Internals::DSL.new
      assert_same dsl, dsl.value(:n, static: 1)
      assert_same dsl, dsl.param(:p, 1)
      assert_same dsl, dsl.outlet(:o, ".x")
      assert_same dsl, dsl.controller("foo")
      assert_same dsl, dsl.actions(:a)
      assert_same dsl, dsl.targets(:t)
      assert_same dsl, dsl.values(n: 1)
      assert_same dsl, dsl.params(p: 1)
      assert_same dsl, dsl.classes(c: "x")
      assert_same dsl, dsl.outlets(o: ".x")
      assert_same dsl, dsl.values_from_props(:x)
    end

    def test_action_and_target_return_fluent_builders
      dsl = ::Vident::Internals::DSL.new
      assert_kind_of ::Vident::Internals::ActionBuilder, dsl.action(:click)
      assert_kind_of ::Vident::Internals::TargetBuilder, dsl.target(:x)
    end

    # ---- fluent ActionBuilder -----------------------------------------

    def test_action_without_chain_passes_raw_args
      dsl = ::Vident::Internals::DSL.new
      dsl.action(:click)
      decl = dsl.to_declarations.actions.first
      assert_equal [:click], decl.args
    end

    def test_action_on_sets_event
      dsl = ::Vident::Internals::DSL.new
      dsl.action(:submit).on(:form)
      decl = dsl.to_declarations.actions.first
      assert_equal [{method: :submit, event: :form}], decl.args
    end

    def test_action_modifier_accumulates
      dsl = ::Vident::Internals::DSL.new
      dsl.action(:save).modifier(:prevent, :stop).modifier(:once)
      descriptor = dsl.to_declarations.actions.first.args.first
      assert_equal [:prevent, :stop, :once], descriptor[:options]
    end

    def test_action_keyboard_and_window
      dsl = ::Vident::Internals::DSL.new
      dsl.action(:handle_escape).on(:keydown).keyboard("esc").window.modifier(:prevent)
      descriptor = dsl.to_declarations.actions.first.args.first
      assert_equal :keydown, descriptor[:event]
      assert_equal :handle_escape, descriptor[:method]
      assert_equal "esc", descriptor[:keyboard]
      assert_equal true, descriptor[:window]
      assert_equal [:prevent], descriptor[:options]
    end

    def test_action_call_method_override
      dsl = ::Vident::Internals::DSL.new
      dsl.action(:submit).on(:form).call_method(:handle_submit)
      descriptor = dsl.to_declarations.actions.first.args.first
      assert_equal :form, descriptor[:event]
      assert_equal :handle_submit, descriptor[:method]
    end

    def test_action_when_captures_proc
      dsl = ::Vident::Internals::DSL.new
      check = -> { true }
      dsl.action(:delete).when(&check)
      decl = dsl.to_declarations.actions.first
      assert_equal check, decl.when_proc
    end

    # ---- kwargs shorthand for action ----------------------------------

    def test_action_kwargs_on_sets_event
      dsl = ::Vident::Internals::DSL.new
      dsl.action(:submit, on: :form)
      descriptor = dsl.to_declarations.actions.first.args.first
      assert_equal :submit, descriptor[:method]
      assert_equal :form, descriptor[:event]
    end

    def test_action_kwargs_modifier_accepts_symbol_or_array
      dsl = ::Vident::Internals::DSL.new
      dsl.action(:save, modifier: :prevent)
      dsl.action(:nuke, modifier: [:prevent, :stop])
      args = dsl.to_declarations.actions.map { |a| a.args.first }
      assert_equal [:prevent], args[0][:options]
      assert_equal [:prevent, :stop], args[1][:options]
    end

    def test_action_kwargs_keyboard_and_window
      dsl = ::Vident::Internals::DSL.new
      dsl.action(:esc, on: :keydown, keyboard: "esc", window: true)
      descriptor = dsl.to_declarations.actions.first.args.first
      assert_equal :keydown, descriptor[:event]
      assert_equal "esc", descriptor[:keyboard]
      assert_equal true, descriptor[:window]
    end

    def test_action_kwargs_on_controller_sets_controller_ref
      dsl = ::Vident::Internals::DSL.new
      dsl.action(:save, on_controller: :admin)
      descriptor = dsl.to_declarations.actions.first.args.first
      assert_equal :admin, descriptor[:controller]
    end

    def test_action_kwargs_when_captures_proc
      dsl = ::Vident::Internals::DSL.new
      check = -> { true }
      dsl.action(:delete, when: check)
      assert_equal check, dsl.to_declarations.actions.first.when_proc
    end

    def test_action_kwargs_unknown_option_raises
      dsl = ::Vident::Internals::DSL.new
      err = assert_raises(ArgumentError) { dsl.action(:save, bogus: 1) }
      assert_match(/unknown option.*bogus/, err.message)
    end

    def test_action_kwargs_then_fluent_chain_composes
      dsl = ::Vident::Internals::DSL.new
      dsl.action(:save, on: :click).modifier(:prevent).keyboard("enter")
      descriptor = dsl.to_declarations.actions.first.args.first
      assert_equal :click, descriptor[:event]
      assert_equal :save, descriptor[:method]
      assert_equal [:prevent], descriptor[:options]
      assert_equal "enter", descriptor[:keyboard]
    end

    # ---- fluent TargetBuilder -----------------------------------------

    def test_target_when_captures_proc
      dsl = ::Vident::Internals::DSL.new
      check = -> { @rows.any? }
      dsl.target(:row).when(&check)
      decl = dsl.to_declarations.targets.first
      assert_equal check, decl.when_proc
      assert_equal [:row], decl.args
    end

    # ---- Declaration record -------------------------------------------

    def test_declaration_of_freezes_args
      d = ::Vident::Internals::Declaration.of(:a, :b)
      assert_predicate d.args, :frozen?
    end

    def test_declaration_captures_when_proc_meta
      fn = -> { true }
      d = ::Vident::Internals::Declaration.of(:x, when_proc: fn, static: 1)
      assert_equal [:x], d.args
      assert_equal fn, d.when_proc
      assert_equal({static: 1}, d.meta)
    end

    # ---- Mixed DSL usage ----------------------------------------------

    def test_dsl_mixes_all_primitives_in_one_block
      cls = make_component do
        stimulus do
          controller "admin/users", as: :admin
          action :click
          action :submit, on: :admin
          target :input
          value :api_url, -> { "/api" }
          param :item_id, -> { 42 }
          outlet :menu, ".js-menu"
          classes loading: "opacity-50"
          values_from_props :foo
        end
      end
      d = cls.declarations
      assert_equal 1, d.controllers.size
      assert_equal 2, d.actions.size
      assert_equal 1, d.targets.size
      assert_equal 1, d.values.size
      assert_equal 1, d.params.size
      assert_equal 1, d.outlets.size
      assert_equal 1, d.class_maps.size
      assert_equal [:foo], d.values_from_props
    end

    def test_dsl_captures_caller_location
      err = assert_raises(::Vident::DeclarationError) do
        make_component do
          no_stimulus_controller
          stimulus { action :click }
        end
      end
      assert_match(/dsl_test\.rb/, err.message)
    end
  end
end
