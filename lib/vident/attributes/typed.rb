# frozen_string_literal: true

require "active_support/concern"

if Gem.loaded_specs.has_key? "dry-struct"
  require_relative "./types"
  require_relative "./typed_niling_struct"

  module Vident
    # Adapts Dry Types to confinus Typed Attributes. We use dry-struct (see ::Core::NilingStruct) but
    # we could probably also use dry-initializer directly, saving us from maintaining the schema.
    module Attributes
      module Typed
        extend ActiveSupport::Concern

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

          def attr_string(name, **options)
            attribute(name, String, **options)
          end

          def attr_boolean(name, **options)
            attribute(name, :boolean, **options)
          end

          def attr_symbol(name, **options)
            attribute(name, Symbol, **options)
          end

          def attr_float(name, **options)
            attribute(name, Float, **options)
          end

          def attr_numeric(name, **options)
            attribute(name, Numeric, **options)
          end

          def attr_integer(name, **options)
            attribute(name, Integer, **options)
          end

          def attr_hash(name, **options)
            attribute(name, Hash, **options)
          end

          def attr_array(name, **options)
            attribute(name, Array, **options)
          end

          def attr_any(name, **options)
            attribute(name, :any, **options)
          end

          def attr_model(name, **options)
            attribute(name, options[:type] || options[:sub_type] || :any, **options)
          end

          def attribute(name, type = :any, **options)
            type_info = map_primitive_to_dry_type(type, !options[:convert])
            type_info = set_constraints(type_info, type, options)
            define_on_schema(name, type_info, options)
          end

          private

          def set_constraints(type_info, specified_type, options)
            member_klass = options[:type] || options[:sub_type]
            if member_klass && type_info.respond_to?(:of)
              # Sub types of collections currently can be nil - this should be an option
              type_info = type_info.of(
                map_primitive_to_dry_type(member_klass, !options[:convert]).optional.meta(required: false)
              )
            end
            type_info = type_info.optional.meta(required: false) if allows_nil?(options)
            type_info = type_info.constrained(filled: true) unless allows_blank?(options)
            if options[:default]&.is_a?(Proc)
              type_info = type_info.default(options[:default].freeze)
            elsif !options[:default].nil?
              type_info = type_info.default(->(_) { options[:default] }.freeze)
            end
            type_info = type_info.constrained(included_in: options[:in].freeze) if options[:in]

            # Store adapter type info in the schema for use by typed form
            metadata = {typed_attribute_type: specified_type, typed_attribute_options: options}
            type_info.meta(**metadata)
          end

          def delegates?(options)
            options[:delegates] != false
          end

          def define_on_schema(name, type_info, options)
            @attribute_ivar_names ||= {}
            @attribute_ivar_names[name] = :"@#{name}"
            define_attribute_delegate(name) if delegates?(options)
            @schema ||= Class.new(Vident::Attributes::TypedNilingStruct)
            @schema.attribute name, type_info
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

          def map_primitive_to_dry_type(type, strict)
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
              Types.Constructor(type) { |values| type.new(**values) }
            end
          end
        end
      end
    end
  end
else
  module Vident
    module Attributes
      module Typed
        def self.included(base)
          raise "Vident::Attributes::Typed requires dry-struct to be installed"
        end
      end
    end
  end
end
