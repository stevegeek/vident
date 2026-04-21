# frozen_string_literal: true

require "vident2"

module PhlexGreetersV2
  # V2 sibling of PhlexGreeters::ApplicationComponent.
  class ApplicationComponent < ::Vident2::Phlex::HTML
    include ::Phlex::Rails::Helpers::Routes

    if Rails.env.development?
      def before_template
        comment { "Before #{self.class.name}" }
        super
      end
    end
  end
end
