# frozen_string_literal: true

require_relative "declaration"
require_relative "declarations"
require_relative "action_builder"
require_relative "target_builder"

module Vident2
  module Internals
    # @api private
    # Block receiver for `stimulus do ... end`. Records each primitive
    # call as one or more `Declaration` raw entries; `finalize` folds
    # them into a frozen `Declarations` aggregate.
    #
    # Parsing into `Stimulus::*` value objects is deferred to the
    # Resolver — this class stores only raw argument tuples.
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

      # Each arg becomes one controller entry. An Array arg is splatted
      # into positional args for a single controller (e.g. a tuple
      # `[path, {as: :alias}]`); anything else is treated as a path.
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

      # Array in the plural form splats into the singular parser (matching
      # V1's plural→singular forwarding) so `actions [:click, :handle]`
      # records a single Action entry with event+method rather than two
      # separate Actions.
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

      # Outlets accept a positional Hash (for keys like `"admin--users"`
      # that can't be a Ruby kwarg) plus kwargs. Order: positional first,
      # kwargs after — last-write wins on duplicates per the keyed merge
      # rule.
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

      # Optional `as: :alias` captured in meta for the Resolver.
      def controller(*args, **meta)
        @controllers << Declaration.of(*args, **meta)
        self
      end

      # Returns an `ActionBuilder` so users can fluent-chain
      # `.on(:event).modifier(:prevent).keyboard("ctrl+s").window.when { ... }`.
      # If no chain methods are called, the raw args pass through unchanged.
      def action(*args)
        builder = ActionBuilder.new(*args)
        @actions << builder
        builder
      end

      # Returns a `TargetBuilder` so users can chain `.when { ... }` for
      # conditional inclusion.
      def target(*args)
        builder = TargetBuilder.new(*args)
        @targets << builder
        builder
      end

      # `value(:url, "x")`, `value(:url, -> { ... })`,
      # `value(:count, static: 0)`, `value(:clicked_count, from_prop: true)`.
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

      # Returns a frozen Declarations snapshot of what this block
      # received. Called once the block finishes executing.
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

      # Last-write wins on matching key, insertion order otherwise.
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
