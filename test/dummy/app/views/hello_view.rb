# frozen_string_literal: true

module Views
  class HelloView < Phlex::HTML
    def initialize(name:)
      @name = name
    end

    def template
      h4 { "👋 Hello #{@name}!" }
    end
  end
end
