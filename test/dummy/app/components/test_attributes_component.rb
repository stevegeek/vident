# frozen_string_literal: true

class TestAttributesComponent < ::Vident::ViewComponent::Base
  prop :name, String, default: -> { "World" }, reader: :public
  prop :initials, _String(&:present?), reader: :public
  prop :url, _Nilable(_String(&:present?)), reader: :public

  def call
    link_to_if(url.present?, "Hi #{name}", url)
  end
end
