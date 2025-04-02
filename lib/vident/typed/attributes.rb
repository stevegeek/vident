require "vident/typed/version"
require "vident/typed/engine"

module Vident
  module Typed
    module Attributes
      extend ActiveSupport::Concern

      # TODO: better handling of when either class.schema is undefined (as no attributes configured) or when
      # other methods ar called before prepare_attributes is called
      def prepare_attributes(attributes)
        @__attributes = self.class.schema.new(**attributes)
      end

      def attributes
        @__attributes.attributes
      end

      def attribute_names
        @attribute_names ||= self.class.attribute_names
      end

      def attribute(key)
        if Rails.env.development? && !key?(key)
          raise StandardError, "Attribute #{key} not found in #{self.class.name}"
        end
        @__attributes.attributes[key]
      end
      alias_method :[], :attribute

      def key?(key)
        self.class.schema.attribute_names.include?(key)
      end

      def to_hash
        @__attributes.to_h
      end

      class_methods do
        def inherited(subclass)
          subclass.instance_variable_set(:@schema, @schema.clone)
          subclass.instance_variable_set(:@attribute_ivar_names, @attribute_ivar_names.clone)
          super
        end

        def attribute_names
          schema.attribute_names
        end

        def attribute_metadata(key)
          schema.schema.key(key).meta
        end

        attr_reader :schema, :attribute_ivar_names

        def attribute(name, signature = :any, **options, &converter)
          strict = !options[:convert]
          signatures = extract_member_type_and_subclass(signature, options)
          type_info = map_primitive_to_dry_type(signatures, strict, converter)
          type_info = set_constraints(type_info, options)
          type_info = set_metadata(type_info, signatures, options)
          define_on_schema(name, type_info, options)
        end

        private

        def set_constraints(type_info, options)
          type_info = constrain_nil(type_info, options)
          type_info = constrain_blank(type_info, options)
          type_info = set_default(type_info, options)
          constrain_inclusion(type_info, options)
        end

        def constrain_nil(type_info, options)
          if allows_nil?(options)
            type_info.optional.meta(required: false)
          else
            type_info
          end
        end

        def constrain_blank(type_info, options)
          if allows_blank?(options)
            type_info
          else
            type_info.constrained(filled: true)
          end
        end

        def set_default(type_info, options)
          default = options[:default]

          if default.is_a?(Proc)
            type_info.default(default.freeze)
          elsif !default.nil?
            type_info.default(->(_) { default }.freeze)
          else
            type_info
          end
        end

        def constrain_inclusion(type_info, options)
          if options[:in]
            type_info.constrained(included_in: options[:in].freeze)
          else
            type_info
          end
        end

        def set_metadata(type_info, signatures, options)
          metadata = {typed_attribute_type: signatures, typed_attribute_options: options}
          type_info.meta(**metadata)
        end

        def delegates?(options)
          options[:delegates] != false
        end

        def define_on_schema(attribute_name, type_info, options)
          @attribute_ivar_names ||= {}
          @attribute_ivar_names[attribute_name] = :"@#{attribute_name}"
          define_attribute_delegate(attribute_name) if delegates?(options)
          @schema ||= const_set(:TypedSchema, Class.new(TypedNilingStruct))
          @schema.attribute attribute_name, type_info
        end

        def define_attribute_delegate(attr_name)
          # Define reader & presence check method
          class_eval(<<-RUBY, __FILE__, __LINE__ + 1)
        def #{attr_name}
          @__attributes.attributes[:#{attr_name}]
        end

        def #{attr_name}?
          send(:#{attr_name}).present?
        end
          RUBY
        end

        def allows_nil?(options)
          return true unless options
          allow_nil = options[:allow_nil]
          return false if allow_nil == false
          allow_nil || allows_blank?(options)
        end

        def allows_blank?(options)
          return true unless options
          allow_blank = options[:allow_blank]
          allow_blank.nil? ? true : allow_blank
        end

        def map_primitive_to_dry_type(signatures, strict, converter)
          types = signatures.map do |type, subtype|
            dry_type = dry_type_from_primary_type(type, strict, converter)
            if subtype && dry_type.respond_to?(:of)
              subtype_info = dry_type_from_primary_type(subtype, strict, converter)
              # Sub types of collections currently can be nil - this should be an option
              dry_type.of(subtype_info.optional.meta(required: false))
            else
              dry_type
            end
          end
          types.reduce(:|)
        end

        def extract_member_type_and_subclass(signature, options)
          case signature
          when Set
            signature.flat_map { |s| extract_member_type_and_subclass(s, options) }
          when Array
            [[Array, signature.first]]
          else
            [[signature, options[:type] || options[:sub_type]]]
          end
        end

        def dry_type_from_primary_type(type, strict, converter)
          # If a converter is provided, we should use it to coerce the value
          if converter && !strict && !type.is_a?(Symbol)
            return Types.Constructor(type) do |value|
              next value if value.is_a?(type)

              converter.call(value).tap do |new_value|
                unless new_value.is_a?(type)
                  raise ArgumentError, "Type conversion proc did not convert #{value} to #{type}"
                end
              end
            end
          end

          if type == :any
            Types::Nominal::Any
          elsif type == Integer
            strict ? Types::Strict::Integer : Types::Params::Integer
          elsif type == BigDecimal
            strict ? Types::Strict::Decimal : Types::Params::Decimal
          elsif type == Float
            strict ? Types::Strict::Float : Types::Params::Float
          elsif type == Numeric
            if strict
              Types::Strict::Float | Types::Strict::Integer | Types::Strict::Decimal
            else
              Types::Params::Float | Types::Params::Integer | Types::Params::Decimal
            end
          elsif type == Symbol
            strict ? Types::Strict::Symbol : Types::Coercible::Symbol
          elsif type == String
            strict ? Types::Strict::String : Types::Coercible::String
          elsif type == Time
            strict ? Types::Strict::Time : Types::Params::Time
          elsif type == Date
            strict ? Types::Strict::Date : Types::Params::Date
          elsif type == Array
            strict ? Types::Strict::Array : Types::Params::Array
          elsif type == Hash
            strict ? Types::Strict::Hash : Types::Coercible::Hash
          elsif type == :boolean
            strict ? Types::Strict::Bool : Types::Params::Bool
          elsif strict
            # when strict create a Nominal type with a is_a? constraint, otherwise create a Nominal type which constructs
            # values using the default constructor, `new`.
            Types.Instance(type)
          else
            # dry calls this when initialising the Type. Check if type of input is correct or create new instance
            Types.Constructor(type) do |value|
              next value if value.is_a?(type)

              type.new(**value)
            end
          end
        end
      end
    end
  end
end
