# frozen_string_literal: true

require_relative "declaration"

module Vident2
  module Internals
    # @api private
    # Fluent chain returned by `target(...)` inside a `stimulus do` block.
    # The only current chain method is `.when` (conditional inclusion);
    # the target itself has no other DSL-facing knobs.
    #
    #   target(:row).when { @rows.any? }
    class TargetBuilder
      def initialize(*args)
        @args = args
        @when_proc = nil
      end

      def when(callable = nil, &block)
        @when_proc = block || callable
        self
      end

      def to_declaration
        Declaration.new(args: @args.freeze, when_proc: @when_proc, meta: {}.freeze)
      end
    end
  end
end
