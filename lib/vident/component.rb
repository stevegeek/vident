# frozen_string_literal: true

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
      attribute :outlets, default: [], delegates: false
      attribute :outlet_host, delegates: false
      attribute :values, default: [], delegates: false
      attribute :named_classes, delegates: false
    end

    def initialize(attrs = {})
      before_initialize(attrs)
      prepare_attributes(attrs)
      after_initialize
      super()
    end
  end
end
