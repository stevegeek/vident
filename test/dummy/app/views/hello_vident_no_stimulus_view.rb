# frozen_string_literal: true

module Views
  class HelloVidentNoStimulusView < Phlex::HTML
    include Vident::Component

    no_stimulus_controller

    attribute :name

    def template
      render root(element_tag: :h4) do
        "👋 Hello #{@name}!"
      end
    end
  end
end
