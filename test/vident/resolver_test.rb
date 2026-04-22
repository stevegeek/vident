# frozen_string_literal: true

require "test_helper"
require "vident"

module Vident
  # Resolver is the pure `(Declarations, instance) -> Draft` pipeline.
  # Tests exercise it without the render surface so proc binding,
  # prop-merge, and declaration resolution are pinned in isolation.
  class ResolverTest < Minitest::Test
    def make_component(name: "ButtonComponent", &block)
      Class.new do
        include ::Vident::Component
        define_singleton_method(:name) { name }
        class_eval(&block) if block
      end
    end

    # ---- Implied controller seed ----------------------------------------

    def test_implied_controller_seeded_by_default
      cls = make_component
      draft = ::Vident::Internals::Resolver.call(cls.declarations, cls.new)
      assert_equal 1, draft.controllers.size
      assert_equal "button-component", draft.controllers.first.name
    end

    def test_implied_controller_suppressed_by_no_stimulus_controller
      cls = make_component { no_stimulus_controller }
      draft = ::Vident::Internals::Resolver.call(cls.declarations, cls.new)
      assert_empty draft.controllers
    end

    def test_controllers_prop_appends_to_implied
      cls = make_component
      instance = cls.new(stimulus_controllers: ["tooltip"])
      draft = ::Vident::Internals::Resolver.call(cls.declarations, instance)
      names = draft.controllers.map(&:name)
      assert_equal ["button-component", "tooltip"], names
    end

    def test_root_element_attributes_controllers_append_to_implied
      cls = make_component do
        define_method(:root_element_attributes) { {stimulus_controllers: ["tooltip"]} }
      end
      draft = ::Vident::Internals::Resolver.call(cls.declarations, cls.new)
      names = draft.controllers.map(&:name)
      assert_equal ["button-component", "tooltip"], names
    end

    # ---- Actions: DSL proc resolution ------------------------------------

    def test_action_proc_resolves_in_instance_binding
      cls = make_component do
        prop :mode, Symbol, default: :click
        stimulus { actions(-> { @mode }) }
      end
      draft = ::Vident::Internals::Resolver.call(cls.declarations, cls.new(mode: :submit))
      assert_equal 1, draft.actions.size
      assert_equal "submit", draft.actions.first.method_name
    end

    def test_action_proc_returning_nil_drops_entry
      cls = make_component do
        stimulus { actions(-> {}) }
      end
      draft = ::Vident::Internals::Resolver.call(cls.declarations, cls.new)
      assert_empty draft.actions
    end

    def test_action_proc_returning_array_splats_into_singular_parser
      cls = make_component do
        stimulus { actions(-> { [:click, :handle] }) }
      end
      draft = ::Vident::Internals::Resolver.call(cls.declarations, cls.new)
      assert_equal 1, draft.actions.size
      action = draft.actions.first
      assert_equal "click", action.event
      assert_equal "handle", action.method_name
    end

    # ---- Values: DSL proc / static / from_prop ---------------------------

    def test_value_static_meta_serialized
      cls = make_component do
        stimulus { value :count, static: 42 }
      end
      draft = ::Vident::Internals::Resolver.call(cls.declarations, cls.new)
      assert_equal 1, draft.values.size
      assert_equal "42", draft.values.first.serialized
    end

    def test_value_proc_resolved_in_instance_binding
      cls = make_component do
        prop :title, String, default: "Hi"
        stimulus { values title: -> { @title.upcase } }
      end
      draft = ::Vident::Internals::Resolver.call(cls.declarations, cls.new)
      assert_equal "HI", draft.values.first.serialized
    end

    def test_value_proc_returning_nil_drops_entry
      cls = make_component do
        stimulus { values maybe: -> {} }
      end
      draft = ::Vident::Internals::Resolver.call(cls.declarations, cls.new)
      assert_empty draft.values
    end

    def test_value_proc_returning_false_survives
      cls = make_component do
        stimulus { values open: -> { false } }
      end
      draft = ::Vident::Internals::Resolver.call(cls.declarations, cls.new)
      assert_equal 1, draft.values.size
      assert_equal "false", draft.values.first.serialized
    end

    def test_value_from_prop_reads_matching_ivar
      cls = make_component do
        prop :release_id, Integer, default: 7
        stimulus { value :release_id, from_prop: true }
      end
      draft = ::Vident::Internals::Resolver.call(cls.declarations, cls.new)
      assert_equal "7", draft.values.first.serialized
    end

    def test_values_from_props_populates_each
      cls = make_component do
        prop :title, String, default: "Hi"
        prop :count, Integer, default: 3
        stimulus { values_from_props :title, :count }
      end
      draft = ::Vident::Internals::Resolver.call(cls.declarations, cls.new)
      assert_equal 2, draft.values.size
      names = draft.values.map(&:name)
      assert_includes names, "title"
      assert_includes names, "count"
    end

    # ---- Outlets: procs resolved ----------------------------------------

    def test_outlet_proc_resolved_in_instance_binding
      cls = make_component do
        prop :selector, String, default: ".default"
        stimulus { outlets modal: -> { @selector } }
      end
      draft = ::Vident::Internals::Resolver.call(cls.declarations, cls.new(selector: ".custom"))
      assert_equal 1, draft.outlets.size
      assert_equal ".custom", draft.outlets.first.selector
    end

    def test_outlet_static_selector
      cls = make_component do
        stimulus { outlets modal: ".js-modal" }
      end
      draft = ::Vident::Internals::Resolver.call(cls.declarations, cls.new)
      assert_equal ".js-modal", draft.outlets.first.selector
    end

    # ---- Targets ---------------------------------------------------------

    def test_target_dsl_entry_parsed
      cls = make_component do
        stimulus { targets :input }
      end
      draft = ::Vident::Internals::Resolver.call(cls.declarations, cls.new)
      assert_equal 1, draft.targets.size
      assert_equal "input", draft.targets.first.name
    end

    def test_target_cross_controller_tuple
      cls = make_component do
        stimulus { targets ["admin/users", :row] }
      end
      draft = ::Vident::Internals::Resolver.call(cls.declarations, cls.new)
      assert_equal "admin--users", draft.targets.first.controller.name
      assert_equal "row", draft.targets.first.name
    end

    # ---- Params and ClassMaps --------------------------------------------

    def test_param_proc_resolved
      cls = make_component do
        prop :item_id, Integer, default: 42
        stimulus { params item_id: -> { @item_id } }
      end
      draft = ::Vident::Internals::Resolver.call(cls.declarations, cls.new)
      assert_equal "42", draft.params.first.serialized
    end

    def test_class_map_static
      cls = make_component do
        stimulus { classes loading: "opacity-50" }
      end
      draft = ::Vident::Internals::Resolver.call(cls.declarations, cls.new)
      assert_equal "opacity-50", draft.class_maps.first.css
    end

    def test_class_map_proc_resolved
      cls = make_component do
        prop :status, Symbol, default: :ok
        stimulus { classes status: -> { (@status == :ok) ? "ok" : "err" } }
      end
      draft = ::Vident::Internals::Resolver.call(cls.declarations, cls.new(status: :error))
      assert_equal "err", draft.class_maps.first.css
    end

    # ---- Merge order (DSL -> props -> root_element_attributes) -----------

    def test_merge_order_dsl_then_prop_then_root_element_attributes
      cls = make_component do
        stimulus { actions :a_from_dsl }
        define_method(:root_element_attributes) { {stimulus_actions: [:a_from_attrs]} }
      end
      instance = cls.new(stimulus_actions: [:a_from_prop])
      draft = ::Vident::Internals::Resolver.call(cls.declarations, instance)
      methods = draft.actions.map(&:method_name)
      assert_equal %w[aFromDsl aFromProp aFromAttrs], methods
    end

    # ---- Returns Draft (unsealed) ---------------------------------------

    def test_result_is_a_draft_not_a_plan
      cls = make_component
      draft = ::Vident::Internals::Resolver.call(cls.declarations, cls.new)
      assert_kind_of ::Vident::Internals::Draft, draft
      refute draft.sealed?
    end

    def test_result_draft_accepts_further_mutations
      cls = make_component
      draft = ::Vident::Internals::Resolver.call(cls.declarations, cls.new)
      assert_equal 1, draft.controllers.size
      action = ::Vident::Stimulus::Action.parse(
        :click,
        implied: draft.controllers.first
      )
      draft.add_actions(action)
      assert_equal 1, draft.actions.size
    end

    # ---- Pre-built value pass-through ------------------------------------

    def test_prop_accepts_pre_built_value_object
      cls = make_component
      implied = ::Vident::Stimulus::Controller.new(path: "button_component", name: "button-component")
      preset = ::Vident::Stimulus::Action.parse(:click, implied: implied)
      instance = cls.new(stimulus_actions: [preset])
      draft = ::Vident::Internals::Resolver.call(cls.declarations, instance)
      assert_same preset, draft.actions.first
    end

    # ---- Prop absorb shapes ----------------------------------------------

    def test_target_prop_array_pair_becomes_single_entry
      cls = make_component
      instance = cls.new(stimulus_targets: [["admin/users", :row]])
      draft = ::Vident::Internals::Resolver.call(cls.declarations, instance)
      assert_equal 1, draft.targets.size
      assert_equal "admin--users", draft.targets.first.controller.name
    end

    def test_value_prop_hash_becomes_one_entry_per_pair
      cls = make_component
      instance = cls.new(stimulus_values: {title: "X", count: 7})
      draft = ::Vident::Internals::Resolver.call(cls.declarations, instance)
      assert_equal 2, draft.values.size
    end

    def test_value_prop_array_triple_cross_controller
      cls = make_component
      instance = cls.new(stimulus_values: [["other/ctrl", :foo, "bar"]])
      draft = ::Vident::Internals::Resolver.call(cls.declarations, instance)
      v = draft.values.first
      assert_equal "other--ctrl", v.controller.name
      assert_equal "foo", v.name
      assert_equal "bar", v.serialized
    end

    # ---- Outlet auto-selector scoping ------------------------------------

    def test_outlet_auto_selector_without_explicit_id_scopes_by_auto_id
      cls = make_component
      instance = cls.new(stimulus_outlets: [:user_status])
      draft = ::Vident::Internals::Resolver.call(cls.declarations, instance)
      assert_match(/\A#button-component-[^\s]+ \[data-controller~=user-status\]\z/,
        draft.outlets.first.selector)
      assert_includes draft.outlets.first.selector, "##{instance.id} "
    end

    def test_outlet_auto_selector_with_explicit_id_scopes_by_id
      cls = make_component
      instance = cls.new(id: "my-card", stimulus_outlets: [:user_status])
      draft = ::Vident::Internals::Resolver.call(cls.declarations, instance)
      assert_equal "#my-card [data-controller~=user-status]", draft.outlets.first.selector
    end

    def test_outlet_auto_selector_matches_between_dsl_and_mutation_paths
      cls = make_component do
        stimulus { outlet :profile }
      end
      instance = cls.new
      instance.add_stimulus_outlets(:team)
      draft = ::Vident::Internals::Resolver.call(cls.declarations, instance)
      dsl_outlet = draft.outlets.find { |o| o.name == "profile" }
      runtime_outlet = instance.instance_variable_get(:@__vident_draft).outlets.last
      assert dsl_outlet.selector.start_with?("##{instance.id} ")
      assert runtime_outlet.selector.start_with?("##{instance.id} ")
    end

    # ---- no-declaration empty path ---------------------------------------

    def test_component_without_stimulus_do_has_only_implied_controller
      cls = make_component
      draft = ::Vident::Internals::Resolver.call(cls.declarations, cls.new)
      assert_equal 1, draft.controllers.size
      assert_empty draft.actions
      assert_empty draft.targets
      assert_empty draft.values
    end

    # ---- Controller alias carried through --------------------------------

    def test_controller_alias_in_dsl
      cls = make_component do
        stimulus { controller "admin/users", as: :admin }
      end
      draft = ::Vident::Internals::Resolver.call(cls.declarations, cls.new)
      # Draft still has implied + declared
      aliases = draft.controllers.map(&:alias_name)
      assert_includes aliases, :admin
    end

    # ---- Action -> Controller alias resolution ---------------------------

    def test_action_on_controller_fluent_resolves_alias
      cls = make_component do
        stimulus do
          controller "admin/users", as: :admin
          action(:save).on_controller(:admin)
        end
      end
      draft = ::Vident::Internals::Resolver.call(cls.declarations, cls.new)
      action = draft.actions.first
      assert_equal "admin--users", action.controller.name
      assert_equal "save", action.method_name
    end

    def test_action_kwargs_form_resolves_alias_via_on_controller
      cls = make_component do
        stimulus do
          controller "admin/users", as: :admin
          action :save, on_controller: :admin
        end
      end
      draft = ::Vident::Internals::Resolver.call(cls.declarations, cls.new)
      assert_equal "admin--users", draft.actions.first.controller.name
    end

    def test_unknown_action_alias_raises_declaration_error
      cls = make_component do
        stimulus do
          controller "admin/users", as: :admin
          action(:save).on_controller(:ghost)
        end
      end
      err = assert_raises(::Vident::DeclarationError) do
        ::Vident::Internals::Resolver.call(cls.declarations, cls.new)
      end
      assert_match(/Unknown controller alias :ghost/, err.message)
    end

    def test_stimulus_actions_prop_resolves_alias
      cls = make_component do
        stimulus { controller "admin/users", as: :admin }
      end
      instance = cls.new(stimulus_actions: [{method: :save, controller: :admin}])
      draft = ::Vident::Internals::Resolver.call(cls.declarations, instance)
      admin_action = draft.actions.find { |a| a.controller.name == "admin--users" }
      refute_nil admin_action, "alias should resolve in prop input"
      assert_equal "save", admin_action.method_name
    end

    def test_stimulus_actions_prop_unknown_alias_raises_when_aliases_declared
      cls = make_component do
        stimulus { controller "admin/users", as: :admin }
      end
      assert_raises(::Vident::DeclarationError) do
        cls.new(stimulus_actions: [{method: :save, controller: :ghost}])
      end
    end

    # ---- False in a positional proc reaches the parser -------------------

    def test_action_proc_returning_false_reaches_parser_and_raises
      cls = make_component do
        stimulus { actions(-> { false }) }
      end
      assert_raises(::Vident::ParseError) do
        ::Vident::Internals::Resolver.call(cls.declarations, cls.new)
      end
    end

    # ---- phase: :static / :procs split ---------------------------------

    def test_static_phase_skips_proc_declarations
      cls = make_component do
        prop :count, Integer, default: 3
        stimulus do
          values total: 5                    # literal — resolves in :static
          values dynamic: -> { @count + 1 }  # proc — deferred
        end
      end
      draft = ::Vident::Internals::Resolver.call(cls.declarations, cls.new, phase: :static)
      keys = draft.values.map(&:name)
      assert_includes keys, "total"
      refute_includes keys, "dynamic"
    end

    def test_procs_phase_adds_only_deferred_proc_entries
      cls = make_component do
        prop :count, Integer, default: 3
        stimulus do
          values total: 5
          values dynamic: -> { @count + 1 }
        end
      end
      draft = ::Vident::Internals::Resolver.call(cls.declarations, cls.new, phase: :static)
      ::Vident::Internals::Resolver.resolve_procs_into(draft, cls.declarations, cls.new)
      keys = draft.values.map(&:name).sort
      assert_equal %w[dynamic total], keys
    end

    def test_static_phase_skips_action_procs
      cls = make_component do
        stimulus do
          action :click
          action(:handle).on(:keydown).when { true }  # has when_proc — deferred
        end
      end
      draft = ::Vident::Internals::Resolver.call(cls.declarations, cls.new, phase: :static)
      assert_equal 1, draft.actions.size
      assert_equal "click", draft.actions.first.method_name
    end

    def test_static_phase_does_not_eval_proc_that_would_raise
      # Concrete scenario: a DSL proc that would fail at init because
      # `helpers` isn't wired yet. The :static phase must not trip it.
      cls = make_component do
        stimulus { values path: -> { raise "would blow up without view_context" } }
      end
      draft = ::Vident::Internals::Resolver.call(cls.declarations, cls.new, phase: :static)
      assert_empty draft.values
    end

    def test_procs_phase_resolves_when_proc_gated_action_passing_the_gate
      cls = make_component do
        stimulus do
          action :click                                  # static, seeds at :static
          action(:handle).on(:keydown).when { true }     # when_proc, deferred
        end
      end
      draft = ::Vident::Internals::Resolver.call(cls.declarations, cls.new, phase: :static)
      ::Vident::Internals::Resolver.resolve_procs_into(draft, cls.declarations, cls.new)
      methods = draft.actions.map(&:method_name)
      assert_equal ["click", "handle"], methods
    end

    def test_procs_phase_drops_when_proc_gated_action_failing_the_gate
      cls = make_component do
        stimulus { action(:handle).on(:keydown).when { false } }
      end
      draft = ::Vident::Internals::Resolver.call(cls.declarations, cls.new, phase: :static)
      ::Vident::Internals::Resolver.resolve_procs_into(draft, cls.declarations, cls.new)
      assert_empty draft.actions
    end

    def test_call_raises_on_explicit_procs_phase
      cls = make_component
      assert_raises(ArgumentError) do
        ::Vident::Internals::Resolver.call(cls.declarations, cls.new, phase: :procs)
      end
    end
  end
end
