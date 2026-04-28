# frozen_string_literal: true

module Vident
  # Composition root. Include order mirrors capability dependencies.
  # Caching is opt-in and NOT included here.
  module Component
    extend ActiveSupport::Concern

    include ::Vident::Capabilities::Tailwind
    include ::Vident::Capabilities::Declarable
    include ::Vident::Capabilities::Identifiable
    include ::Vident::Capabilities::StimulusDeclaring
    include ::Vident::Capabilities::StimulusParsing
    include ::Vident::Capabilities::StimulusMutation
    include ::Vident::Capabilities::StimulusDraft
    include ::Vident::Capabilities::StimulusDataEmitting
    include ::Vident::Capabilities::StimulusAttributeStrings
    include ::Vident::Capabilities::ClassListBuilding
    include ::Vident::Capabilities::RootElementRendering
    include ::Vident::Capabilities::ChildElementRendering
    include ::Vident::Capabilities::Inspectable
  end
end
