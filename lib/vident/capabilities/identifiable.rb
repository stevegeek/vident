# frozen_string_literal: true

require_relative "../stimulus/controller"
require_relative "../stable_id"

module Vident
  module Capabilities
    module Identifiable
      extend ActiveSupport::Concern

      class_methods do
        def stimulus_identifier_path
          name&.underscore || "anonymous_component"
        end

        def stimulus_identifier
          stimulus_identifier_path.split("/").map(&:dasherize).join("--")
        end

        def component_name
          @component_name ||= stimulus_identifier
        end
      end

      def component_name = self.class.component_name

      def stimulus_identifier = self.class.stimulus_identifier

      private def default_controller_path = self.class.stimulus_identifier_path

      # `.presence` is intentional — blank string falls through to auto-generation.
      def id
        @id.presence || random_id
      end

      def random_id
        @__vident_auto_id ||= "#{component_name}-#{::Vident::StableId.next_id_in_sequence}"
      end

      def outlet_id
        @outlet_id ||= [stimulus_identifier, "##{id}"]
      end

      private

      def implied_controller
        @__vident_implied_controller ||= ::Vident::Stimulus::Controller.new(
          path: self.class.stimulus_identifier_path,
          name: self.class.stimulus_identifier
        )
      end
    end
  end
end
