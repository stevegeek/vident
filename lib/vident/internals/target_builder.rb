# frozen_string_literal: true

require_relative "declaration"

module Vident
  module Internals
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
