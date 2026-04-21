# frozen_string_literal: true

require_relative "registry"

module Vident2
  module Internals
    # @api private
    # Frozen snapshot produced by `Draft#seal!`. One field per Registry
    # kind, each an Array<Stimulus::*>.
    Plan = Data.define(*Registry.names)
  end
end
