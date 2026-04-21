# frozen_string_literal: true

require_relative "../internals/class_list_builder"

module Vident
  module Capabilities
    module ClassListBuilding
      def class_list_for_stimulus_classes(*names)
        resolve_stimulus_attributes_at_render_time
        plan = seal_draft
        maps = plan.class_maps
        return "" if maps.empty? || names.empty?

        result = ::Vident::Internals::ClassListBuilder.call(
          stimulus_classes: maps,
          stimulus_class_names: names,
          tailwind_merger: tailwind_merger
        )
        result || ""
      end
    end
  end
end
