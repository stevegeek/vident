# frozen_string_literal: true

class GreeterButtonComponent < ViewComponent::Base
  include Vident::Component

  attribute :cta

  def call
    root_tag = root(element_tag: :button, html_options: {class: "ml-4 whitespace-no-wrap bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded"})
    render root_tag do
      @cta
    end
  end
end
