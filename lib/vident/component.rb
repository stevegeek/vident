# frozen_string_literal: true

require_relative "./attributes/not_typed"

module Vident
  module Component
    extend ActiveSupport::Concern

    included do
      include Vident::Base
      include Vident::Attributes::NotTyped

      attribute :id, delegates: false
      attribute :html_options, delegates: false
      attribute :element_tag, delegates: false

      # StimulusJS support
      attribute :controllers, default: [], delegates: false
      attribute :actions, default: [], delegates: false
      attribute :targets, default: [], delegates: false
      attribute :data_maps, default: [], delegates: false
      attribute :named_classes, delegates: false
    end

    def initialize(attrs = {})
      before_initialise(attrs)
      prepare_attributes(attrs)
      after_initialise
      super()
    end
  end
end
