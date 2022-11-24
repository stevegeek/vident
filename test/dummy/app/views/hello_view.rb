# frozen_string_literal: true

module Views
  class HelloView < Phlex::HTML
    include Vident::Component

    attribute :name

    def template
      render(root) do
        h1 { "👋 Hello #{@name}!" }
      end
    end
  end
end
