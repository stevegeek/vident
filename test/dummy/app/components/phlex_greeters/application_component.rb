# frozen_string_literal: true

require "vident"

module PhlexGreeters
  # V2 sibling of PhlexGreeters::ApplicationComponent.
  class ApplicationComponent < ::Vident::Phlex::HTML
    include ::Phlex::Rails::Helpers::Routes

    if Rails.env.development?
      def before_template
        comment { "Before #{self.class.name}" }
        super
      end
    end
  end
end
