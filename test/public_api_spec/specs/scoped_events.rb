# frozen_string_literal: true

module Vident
  module PublicApiSpec
    # Covers: stimulus_scoped_event / stimulus_scoped_event_on_window —
    # the Vident helpers that convert a (dispatching-component, event-name)
    # pair into the Symbol Stimulus expects for cross-component event
    # dispatch (e.g. `"dispatcher-component:dataReady"` or the
    # `@window`-scoped variant). Both class and instance forms.
    module ScopedEvents
      # ---- no @window form -----------------------------------------------

      def test_stimulus_scoped_event_class_method
        klass = define_component(name: "DispatcherComponent")
        assert_equal :"dispatcher-component:dataReady",
          klass.stimulus_scoped_event(:data_ready)
      end

      def test_stimulus_scoped_event_camelizes_snake_case
        klass = define_component(name: "D")
        assert_equal :"d:helloWorldEvent", klass.stimulus_scoped_event(:hello_world_event)
      end

      def test_stimulus_scoped_event_instance_delegates_to_class
        klass = define_component(name: "DispatcherComponent")
        assert_equal klass.stimulus_scoped_event(:foo),
          klass.new.stimulus_scoped_event(:foo)
      end

      # ---- @window form --------------------------------------------------

      def test_stimulus_scoped_event_on_window_class_method
        klass = define_component(name: "DispatcherComponent")
        assert_equal :"dispatcher-component:dataReady@window",
          klass.stimulus_scoped_event_on_window(:data_ready)
      end

      def test_stimulus_scoped_event_on_window_instance_delegates
        klass = define_component(name: "DispatcherComponent")
        assert_equal klass.stimulus_scoped_event_on_window(:foo),
          klass.new.stimulus_scoped_event_on_window(:foo)
      end

      # ---- namespaced identifier uses dash-dash separator ----------------

      def test_stimulus_scoped_event_with_namespaced_class
        klass = define_component(name: "Admin::PanelComponent")
        assert_equal :"admin--panel-component:thingHappened",
          klass.stimulus_scoped_event(:thing_happened)
      end

      # ---- end-to-end: scoped event in the action DSL --------------------

      def test_scoped_event_in_action_dsl_emits_correct_data_action
        dispatcher = define_component(name: "DispatcherComponent")
        listener = define_component(name: "ListenerComponent") do
          define_singleton_method(:dispatcher_class) { dispatcher }
          stimulus do
            actions(-> { [self.class.dispatcher_class.stimulus_scoped_event_on_window(:data_ready), :handle_ready] })
          end
        end
        assert_includes render(listener.new),
          'data-action="dispatcher-component:dataReady@window->listener-component#handleReady"'
      end
    end
  end
end
