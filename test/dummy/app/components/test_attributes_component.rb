# frozen_string_literal: true

require "vident"

# Custom-`call` VC that doesn't touch the Stimulus pipeline — exists to
# pin Literal `_Predicate` prop-validation error messages.
class TestAttributesComponent < ::Vident::ViewComponent::Base
  prop :name, String, default: -> { "World" }, reader: :public
  prop :initials, _String(_Predicate("present", &:present?)), reader: :public
  prop :url, _Nilable(_String(_Predicate("present", &:present?))), reader: :public

  def call
    link_to_if(url.present?, "Hi #{name}", url)
  end
end
