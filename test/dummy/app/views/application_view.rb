# frozen_string_literal: true

module Views
  module ApplicationView
    include Rails.application.routes.url_helpers
    include Phlex::Translation
  end
end
