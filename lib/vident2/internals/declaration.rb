# frozen_string_literal: true

module Vident2
  module Internals
    # @api private
    # One unresolved DSL entry. `args` is the raw argument tuple passed
    # to the DSL primitive; the Resolver parses it into a Stimulus value
    # object at instance init. `when_proc` (optional) is a `-> { ... }`
    # filter evaluated in the component binding; `meta` is a free-form
    # Hash for options like `from_prop: true` the parser needs to see.
    Declaration = Data.define(:args, :when_proc, :meta) do
      def self.of(*args, when_proc: nil, **meta)
        new(args: args.freeze, when_proc: when_proc, meta: meta.freeze)
      end
    end
  end
end
