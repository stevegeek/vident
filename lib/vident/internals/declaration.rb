# frozen_string_literal: true

module Vident
  module Internals
    # One unresolved DSL entry; the Resolver parses it into typed Stimulus
    # value objects at instance init time.
    Declaration = Data.define(:args, :when_proc, :meta) do
      def self.of(*args, when_proc: nil, **meta)
        new(args: args.freeze, when_proc: when_proc, meta: meta.freeze)
      end
    end
  end
end
