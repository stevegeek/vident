# frozen_string_literal: true

module Vident
  module Typed
    module Component
      extend ActiveSupport::Concern

      included do
        include Vident::Base
        include Vident::Typed::Attributes

        attribute :id, String, delegates: false
        attribute :html_options, Hash, delegates: false
        attribute :element_tag, Symbol, delegates: false

        # StimulusJS support
        attribute :controllers, Array, default: [], delegates: false
        attribute :actions, Array, default: [], delegates: false
        attribute :outlets, Array, default: [], delegates: false
        attribute :outlet_host, :any, delegates: false

        attribute :targets, Array, default: [], delegates: false
        attribute :values, Array, default: [], delegates: false

        # TODO normalise the syntax of defining actions, controllers, etc
        attribute :named_classes, Hash, delegates: false
      end

      def initialize(attrs = {})
        before_initialize(attrs)
        prepare_attributes(attrs)
        # The attributes need to also be set as ivars
        attributes.each do |attr_name, attr_value|
          instance_variable_set(self.class.attribute_ivar_names[attr_name], attr_value)
        end
        after_initialize
        super()
      end
    end
  end
end
