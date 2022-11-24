# frozen_string_literal: true

if Gem.loaded_specs.has_key? "dry-struct"
  require_relative "./attributes/typed"

  module Vident
    module TypedComponent
      extend ActiveSupport::Concern

      included do
        include Vident::Base
        include Vident::Attributes::Typed

        attribute :id, String, delegates: false
        attribute :html_options, Hash, delegates: false
        attribute :element_tag, Symbol, delegates: false

        # StimulusJS support
        attribute :controllers, Array, default: [], delegates: false
        attribute :actions, Array, default: [], delegates: false
        attribute :targets, Array, default: [], delegates: false
        attribute :data_maps, Array, default: [], delegates: false

        # TODO normalise the syntax of defining actions, controllers, etc
        attribute :named_classes, Hash, delegates: false
      end

      def initialize(attrs = {})
        before_initialise(attrs)
        prepare_attributes(attrs)
        # The attributes need to also be set as ivars
        attributes.each do |attr_name, attr_value|
          instance_variable_set(self.class.attribute_ivar_names[attr_name], attr_value)
        end
        after_initialise
        super()
      end
    end
  end
else
  module Vident
    module TypedComponent
      def self.included(base)
        raise "Vident::TypedComponent requires dry-struct to be installed"
      end
    end
  end
end
