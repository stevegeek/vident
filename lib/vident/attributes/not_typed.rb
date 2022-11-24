# frozen_string_literal: true

module Vident
  module Attributes
    module NotTyped
      extend ActiveSupport::Concern

      def attributes
        @__attributes ||= {}
      end

      def prepare_attributes(attributes)
        @__attributes ||= {}
        attribute_names.each do |attr_name|
          default = self.class.attribute_options&.dig(attr_name, :default)
          if attributes&.include? attr_name
            value = attributes[attr_name]
            @__attributes[attr_name] = (value.nil? && default) ? default : value
          else
            @__attributes[attr_name] = default
          end
          instance_variable_set(self.class.attribute_ivar_names[attr_name], @__attributes[attr_name])
        end
      end

      def attribute_names
        self.class.attribute_names
      end

      def attribute(key)
        attributes[key]
      end

      def to_hash
        attributes.dup
      end

      class_methods do
        def inherited(subclass)
          subclass.instance_variable_set(:@attribute_ivar_names, @attribute_ivar_names.clone)
          super
        end

        attr_reader :attribute_ivar_names, :attribute_names, :attribute_options

        def attribute(name, **options)
          @attribute_names ||= []
          @attribute_names << name
          @attribute_ivar_names ||= {}
          @attribute_ivar_names[name] = :"@#{name}"
          @attribute_options ||= {}
          @attribute_options[name] = options
          define_attribute_delegate(name) if delegates?(options)
        end

        def delegates?(options)
          options[:delegates] != false
        end

        def define_attribute_delegate(attr_name)
          # Define reader & presence check method
          class_eval(<<-RUBY, __FILE__, __LINE__ + 1)
          def #{attr_name}
            @#{attr_name}
          end

          def #{attr_name}?
            send(:#{attr_name}).present?
          end
          RUBY
        end
      end
    end
  end
end
