# frozen_string_literal: true

require_relative "declaration"
require_relative "declarations"
require_relative "action_builder"
require_relative "target_builder"

module Vident
  module Internals
    # Block receiver for `stimulus do ... end`. Records raw Declaration entries;
    # parsing into typed Stimulus value objects is deferred to the Resolver.
    class DSL
      attr_reader :caller_location

      def initialize(caller_location: nil)
        @caller_location = caller_location
        @controllers = []
        @actions = []
        @targets = []
        @outlets = []
        @values = []
        @params = []
        @class_maps = []
        @values_from_props = []
      end

      # ---- plural (kwargs) forms --------------------------------------

      def controllers(*args)
        args.each do |arg|
          case arg
          in Array
            controller(*arg)
          else
            controller(arg)
          end
        end
        self
      end

      def actions(*names)
        names.each do |name|
          case name
          in Array
            action(*name)
          else
            action(name)
          end
        end
        self
      end

      def targets(*names)
        names.each do |name|
          case name
          in Array
            target(*name)
          else
            target(name)
          end
        end
        self
      end

      def values(**hash)
        hash.each { |k, v| record_keyed(@values, k, v) }
        self
      end

      def params(**hash)
        hash.each { |k, v| record_keyed(@params, k, v) }
        self
      end

      def classes(**hash)
        hash.each { |k, v| record_keyed(@class_maps, k, v) }
        self
      end

      # Positional Hash arg supports keys like `"admin--users"` that can't be Ruby kwargs.
      def outlets(positional = nil, **hash)
        if positional.is_a?(Hash)
          positional.each { |k, v| record_keyed(@outlets, k, v) }
        elsif !positional.nil?
          raise ArgumentError, "outlets: positional arg must be a Hash, got #{positional.class}"
        end
        hash.each { |k, v| record_keyed(@outlets, k, v) }
        self
      end

      def values_from_props(*names)
        @values_from_props.concat(names.map(&:to_sym))
        self
      end

      # ---- singular forms --------------------------------------------

      def controller(*args, **meta)
        @controllers << Declaration.of(*args, **meta)
        self
      end

      def action(*args, **meta)
        builder = ActionBuilder.new(*args, **meta)
        @actions << builder
        builder
      end

      def target(*args)
        builder = TargetBuilder.new(*args)
        @targets << builder
        builder
      end

      def value(name, *args, **meta)
        entry = [name, Declaration.of(*args, **meta)]
        replace_or_append(@values, entry)
        self
      end

      def param(name, *args, **meta)
        entry = [name, Declaration.of(*args, **meta)]
        replace_or_append(@params, entry)
        self
      end

      def outlet(name, *args, **meta)
        entry = [name, Declaration.of(*args, **meta)]
        replace_or_append(@outlets, entry)
        self
      end

      def class_map(name, *args, **meta)
        entry = [name, Declaration.of(*args, **meta)]
        replace_or_append(@class_maps, entry)
        self
      end

      # ---- folding ----------------------------------------------------

      def to_declarations
        Declarations.new(
          controllers: @controllers.dup.freeze,
          actions: @actions.map(&:to_declaration).freeze,
          targets: @targets.map(&:to_declaration).freeze,
          outlets: @outlets.dup.freeze,
          values: @values.dup.freeze,
          params: @params.dup.freeze,
          class_maps: @class_maps.dup.freeze,
          values_from_props: @values_from_props.dup.freeze
        ).freeze
      end

      private

      def record_keyed(bucket, key, value)
        entry = [key, Declaration.of(value)]
        replace_or_append(bucket, entry)
      end

      def replace_or_append(bucket, entry)
        key = entry.first
        idx = bucket.index { |(k, _)| k == key }
        if idx
          bucket[idx] = entry
        else
          bucket << entry
        end
      end
    end
  end
end
