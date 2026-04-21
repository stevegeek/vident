# frozen_string_literal: true

require_relative "../internals/declarations"
require_relative "../internals/dsl"

module Vident
  module Capabilities
    module StimulusDeclaring
      extend ActiveSupport::Concern

      included do
        @__vident_declarations = ::Vident::Internals::Declarations.empty
        @__vident_no_stimulus_controller = false
      end

      class_methods do
        def declarations
          @__vident_declarations ||= ::Vident::Internals::Declarations.empty
        end

        def no_stimulus_controller
          if declarations.any?
            raise ::Vident::DeclarationError,
              "#{name || "anonymous component"} called `no_stimulus_controller` after " \
              "`stimulus do` already recorded DSL entries. Declare `no_stimulus_controller` " \
              "before any `stimulus do` block."
          end
          @__vident_no_stimulus_controller = true
        end

        def stimulus_controller?
          !@__vident_no_stimulus_controller
        end

        # Second+ calls append (positional) or last-write-wins (keyed).
        def stimulus(&block)
          call_site = caller_locations(1, 1)&.first
          dsl = ::Vident::Internals::DSL.new(caller_location: call_site)
          dsl.instance_eval(&block) if block
          fresh = dsl.to_declarations

          if !stimulus_controller? && fresh.any?
            location = call_site ? " at #{call_site.path}:#{call_site.lineno}" : ""
            raise ::Vident::DeclarationError,
              "#{name || "anonymous component"} declared `no_stimulus_controller` but `stimulus do` emitted DSL entries#{location}. " \
              "A class with no implied controller cannot route DSL entries; drop the `stimulus do` block or remove `no_stimulus_controller`."
          end

          @__vident_declarations = declarations.merge(fresh).freeze
        end

        def stimulus_scoped_event(event)
          :"#{component_name}:#{event.to_s.camelize(:lower)}"
        end

        def stimulus_scoped_event_on_window(event)
          :"#{component_name}:#{event.to_s.camelize(:lower)}@window"
        end

        def inherited(subclass)
          super
          subclass.instance_variable_set(:@__vident_declarations, declarations)
          subclass.instance_variable_set(
            :@__vident_no_stimulus_controller,
            instance_variable_get(:@__vident_no_stimulus_controller) || false
          )
        end
      end

      def stimulus_scoped_event(event) = self.class.stimulus_scoped_event(event)

      def stimulus_scoped_event_on_window(event) = self.class.stimulus_scoped_event_on_window(event)
    end
  end
end
