# frozen_string_literal: true

require "vident"

module Tasks
  class ApplicationComponent < ::Vident::Phlex::HTML
    include ::Phlex::Rails::Helpers::Routes
  end
end
