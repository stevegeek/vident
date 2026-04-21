# frozen_string_literal: true

require "test_helper"
require "vident2"

module Vident2
  # Draft is the single mutable seam in V2. One instance per component;
  # `add_*` mutates until `seal!`, after which it becomes a frozen Plan
  # and any further `add_*` raises StateError.
  class DraftTest < Minitest::Test
    def setup
      @controller = ::Vident2::Stimulus::Controller.new(
        path: "button_component", name: "button-component"
      )
    end

    def action(sym = :click)
      ::Vident2::Stimulus::Action.parse(sym, implied: @controller)
    end

    def target(sym = :input)
      ::Vident2::Stimulus::Target.parse(sym, implied: @controller)
    end

    # ---- Construction & accessors ---------------------------------------

    def test_new_draft_has_empty_collections
      draft = ::Vident2::Internals::Draft.new
      assert_empty draft.controllers
      assert_empty draft.actions
      assert_empty draft.targets
      assert_empty draft.outlets
      assert_empty draft.values
      assert_empty draft.params
      assert_empty draft.class_maps
    end

    def test_new_draft_is_not_sealed
      refute ::Vident2::Internals::Draft.new.sealed?
    end

    # ---- add_* mutators -------------------------------------------------

    def test_add_controllers_appends_single_value
      draft = ::Vident2::Internals::Draft.new
      draft.add_controllers(@controller)
      assert_equal [@controller], draft.controllers
    end

    def test_add_actions_appends_multiple_from_array
      draft = ::Vident2::Internals::Draft.new
      a1 = action(:click)
      a2 = action(:submit)
      draft.add_actions([a1, a2])
      assert_equal [a1, a2], draft.actions
    end

    def test_add_returns_self_for_chaining
      draft = ::Vident2::Internals::Draft.new
      assert_same draft, draft.add_actions(action)
    end

    def test_add_across_kinds_keeps_collections_independent
      draft = ::Vident2::Internals::Draft.new
      draft.add_actions(action(:click))
      draft.add_targets(target(:input))
      assert_equal 1, draft.actions.size
      assert_equal 1, draft.targets.size
    end

    def test_multiple_add_calls_accumulate
      draft = ::Vident2::Internals::Draft.new
      draft.add_actions(action(:click))
      draft.add_actions(action(:submit))
      assert_equal 2, draft.actions.size
    end

    # ---- seal! lifecycle ------------------------------------------------

    def test_seal_returns_a_plan
      draft = ::Vident2::Internals::Draft.new
      draft.add_actions(action)
      plan = draft.seal!
      assert_kind_of ::Vident2::Internals::Plan, plan
    end

    def test_seal_flips_sealed_predicate
      draft = ::Vident2::Internals::Draft.new
      draft.seal!
      assert draft.sealed?
    end

    def test_seal_is_idempotent_and_memoised
      draft = ::Vident2::Internals::Draft.new
      plan1 = draft.seal!
      plan2 = draft.seal!
      assert_same plan1, plan2
    end

    def test_plan_reflects_pre_seal_state
      draft = ::Vident2::Internals::Draft.new
      draft.add_actions(action(:click))
      draft.add_targets(target(:input))
      plan = draft.seal!
      assert_equal 1, plan.actions.size
      assert_equal 1, plan.targets.size
    end

    def test_sealed_plan_arrays_are_frozen
      draft = ::Vident2::Internals::Draft.new
      draft.add_actions(action)
      plan = draft.seal!
      assert_predicate plan.actions, :frozen?
    end

    # ---- Post-seal mutation raises StateError ---------------------------

    def test_add_after_seal_raises_state_error
      draft = ::Vident2::Internals::Draft.new
      draft.seal!
      assert_raises(::Vident2::StateError) { draft.add_actions(action) }
    end

    def test_state_error_message_names_the_rendering_boundary
      draft = ::Vident2::Internals::Draft.new
      draft.seal!
      err = assert_raises(::Vident2::StateError) { draft.add_actions(action) }
      assert_match(/rendering/, err.message)
    end

    def test_seal_accepts_repeat_calls_without_raising
      draft = ::Vident2::Internals::Draft.new
      draft.seal!
      draft.seal!
      assert draft.sealed?
    end

    # ---- plan accessor --------------------------------------------------

    def test_plan_accessor_seals_if_needed
      draft = ::Vident2::Internals::Draft.new
      assert_kind_of ::Vident2::Internals::Plan, draft.plan
      assert draft.sealed?
    end
  end
end
