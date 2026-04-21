# frozen_string_literal: true

require "vident2"

module V2
  # Mirrors V1 TestAttributesComponent — a custom-`call` VC that
  # doesn't go near the Stimulus pipeline. Here primarily to check
  # Literal prop validation via `_Predicate` still surfaces correctly
  # under V2 (gotcha-style type errors should remain informative).
  class TestAttributesComponent < ::Vident2::ViewComponent::Base
    prop :name, String, default: -> { "World" }, reader: :public
    prop :initials, _String(_Predicate("present", &:present?)), reader: :public
    prop :url, _Nilable(_String(_Predicate("present", &:present?))), reader: :public

    def call
      link_to_if(url.present?, "Hi #{name}", url)
    end
  end
end
