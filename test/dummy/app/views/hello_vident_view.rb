# frozen_string_literal: true

module Views
  class HelloVidentView < Phlex::HTML
    include Vident::Component

    attribute :name

    def template
      render root(element_tag: :h1) do
        "👋 Hello #{@name}!"
      end
    end
  end
end
