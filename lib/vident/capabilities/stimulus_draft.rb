# frozen_string_literal: true

require_relative "../internals/resolver"

module Vident
  module Capabilities
    module StimulusDraft
      def after_component_initialize
      end

      # Flag set before the guards so a sealed Draft can't trap us in a
      # loop where every subsequent call re-takes the sealed branch.
      def resolve_stimulus_attributes_at_render_time
        return if @__vident_procs_resolved
        @__vident_procs_resolved = true
        return if @__vident_draft.nil? || @__vident_draft.sealed?
        ::Vident::Internals::Resolver.resolve_procs_into(
          @__vident_draft, self.class.declarations, self
        )
      end

      private

      # DSL procs defer to render (`view_context` isn't wired yet at init time).
      def after_initialize
        @__vident_draft = ::Vident::Internals::Resolver.call(
          self.class.declarations, self, phase: :static
        )
        @stimulus_outlet_host&.add_stimulus_outlets(self)
        after_component_initialize
      end

      def raise_if_sealed!
        if @__vident_draft.nil?
          raise ::Vident::StateError,
            "stimulus Draft is nil — Literal::Data `after_initialize` never fired. " \
            "If you subclassed and overrode `initialize`, ensure `super` is called. " \
            "If you instantiated with `allocate`, call `after_initialize` manually."
        end
        return unless @__vident_draft.sealed?
        raise ::Vident::StateError,
          "cannot modify stimulus attributes after rendering has begun"
      end

      def seal_draft
        resolve_stimulus_attributes_at_render_time
        @__vident_plan ||= @__vident_draft.seal!
      end
    end
  end
end
