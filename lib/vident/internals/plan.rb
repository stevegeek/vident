# frozen_string_literal: true

require_relative "registry"

module Vident
  module Internals
    Plan = Data.define(*Registry.names)
  end
end
