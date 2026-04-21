# frozen_string_literal: true

module Vident
  module PublicApiSpec
    # Covers: Vident::StableId public API — strategies, sequence-generator
    # management, the two named errors, determinism, and the component
    # `id` format that relies on it.
    #
    # test_helper.rb sets `Vident::StableId.strategy = RANDOM_FALLBACK`
    # globally. Tests that change strategy or generator state MUST restore
    # before exit to avoid leaking into other tests.
    module StableId
      # ---- strategies ----------------------------------------------------

      def test_strict_strategy_raises_when_no_generator
        previous_strategy = ::Vident::StableId.strategy
        ::Vident::StableId.strategy = ::Vident::StableId::STRICT
        ::Vident::StableId.clear_current_sequence_generator

        error = assert_raises(::Vident::StableId::GeneratorNotSetError) do
          ::Vident::StableId.next_id_in_sequence
        end
        assert_match(/No Vident::StableId sequence generator/, error.message)
      ensure
        ::Vident::StableId.strategy = previous_strategy
      end

      def test_random_fallback_without_generator_returns_hex
        previous_strategy = ::Vident::StableId.strategy
        ::Vident::StableId.strategy = ::Vident::StableId::RANDOM_FALLBACK
        ::Vident::StableId.clear_current_sequence_generator

        id = ::Vident::StableId.next_id_in_sequence
        assert_kind_of String, id
        # `Random.hex(16)` returns 32 lowercase hex chars
        assert_match(/\A[a-f0-9]{32}\z/, id)
      ensure
        ::Vident::StableId.strategy = previous_strategy
      end

      def test_strategy_not_configured_raises
        previous_strategy = ::Vident::StableId.strategy
        ::Vident::StableId.strategy = nil

        assert_raises(::Vident::StableId::StrategyNotConfiguredError) do
          ::Vident::StableId.next_id_in_sequence
        end
      ensure
        ::Vident::StableId.strategy = previous_strategy
      end

      # ---- with_sequence_generator ---------------------------------------

      def test_with_sequence_generator_scopes_and_restores
        previous_gen = Thread.current[:vident_number_sequence_generator]
        ::Vident::StableId.clear_current_sequence_generator

        ::Vident::StableId.with_sequence_generator(seed: "my-seed") do
          # Inside the block: generator is set
          refute_nil Thread.current[:vident_number_sequence_generator]
          id = ::Vident::StableId.next_id_in_sequence
          assert_kind_of String, id
        end
        # After the block: generator restored
        assert_nil Thread.current[:vident_number_sequence_generator]
      ensure
        Thread.current[:vident_number_sequence_generator] = previous_gen
      end

      def test_with_sequence_generator_raises_on_nil_seed
        assert_raises(ArgumentError) do
          ::Vident::StableId.with_sequence_generator(seed: nil) {}
        end
      end

      def test_set_and_clear_current_sequence_generator
        previous_gen = Thread.current[:vident_number_sequence_generator]
        ::Vident::StableId.set_current_sequence_generator(seed: "test")
        refute_nil Thread.current[:vident_number_sequence_generator]
        ::Vident::StableId.clear_current_sequence_generator
        assert_nil Thread.current[:vident_number_sequence_generator]
      ensure
        Thread.current[:vident_number_sequence_generator] = previous_gen
      end

      # ---- determinism ---------------------------------------------------

      def test_same_seed_yields_same_first_id
        previous_strategy = ::Vident::StableId.strategy
        previous_gen = Thread.current[:vident_number_sequence_generator]
        ::Vident::StableId.strategy = ::Vident::StableId::STRICT

        id_a = ::Vident::StableId.with_sequence_generator(seed: "seed-x") do
          ::Vident::StableId.next_id_in_sequence
        end
        id_b = ::Vident::StableId.with_sequence_generator(seed: "seed-x") do
          ::Vident::StableId.next_id_in_sequence
        end
        assert_equal id_a, id_b
      ensure
        ::Vident::StableId.strategy = previous_strategy
        Thread.current[:vident_number_sequence_generator] = previous_gen
      end

      def test_different_seed_yields_different_first_id
        previous_strategy = ::Vident::StableId.strategy
        previous_gen = Thread.current[:vident_number_sequence_generator]
        ::Vident::StableId.strategy = ::Vident::StableId::STRICT

        id_a = ::Vident::StableId.with_sequence_generator(seed: "seed-x") do
          ::Vident::StableId.next_id_in_sequence
        end
        id_b = ::Vident::StableId.with_sequence_generator(seed: "seed-y") do
          ::Vident::StableId.next_id_in_sequence
        end
        refute_equal id_a, id_b
      ensure
        ::Vident::StableId.strategy = previous_strategy
        Thread.current[:vident_number_sequence_generator] = previous_gen
      end

      # ---- error hierarchy -----------------------------------------------

      def test_stable_id_errors_inherit_from_configuration_error
        assert ::Vident::StableId::GeneratorNotSetError.ancestors.include?(::Vident::ConfigurationError),
          "GeneratorNotSetError must inherit from Vident::ConfigurationError"
        assert ::Vident::StableId::StrategyNotConfiguredError.ancestors.include?(::Vident::ConfigurationError),
          "StrategyNotConfiguredError must inherit from Vident::ConfigurationError"
      end

      # ---- component id integration --------------------------------------

      def test_component_id_format_is_component_name_dash_stable_id
        klass = define_component(name: "ButtonComponent")
        assert_match(/\Abutton-component-[a-f0-9]+/, klass.new.id)
      end

      def test_explicit_id_prop_overrides_auto_generated
        klass = define_component(name: "ButtonComponent")
        assert_equal "my-button", klass.new(id: "my-button").id
      end

      def test_component_auto_id_is_stable_per_instance
        klass = define_component(name: "ButtonComponent")
        comp = klass.new
        # Same id across multiple calls (memoized via @random_id)
        assert_equal comp.id, comp.id
      end
    end
  end
end
