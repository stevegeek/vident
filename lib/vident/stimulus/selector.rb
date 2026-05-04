# frozen_string_literal: true

module Vident
  module Stimulus
    Selector = Data.define(:css) do
      def to_s = css
    end

    def self.Selector(css) = Selector.new(css: css)
  end

  def self.Selector(css) = Stimulus::Selector.new(css: css)
end
