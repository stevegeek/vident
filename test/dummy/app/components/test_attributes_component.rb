# frozen_string_literal: true

class TestAttributesComponent < ViewComponent::Base
  include Vident::TypedComponent

  attribute :name, String, default: "World"
  attribute :initials, String, allow_blank: false
  attribute :url, String, allow_blank: false, allow_nil: true

  def call
    link_to_if(url.present?, "Hi #{name}", url)
  end
end
