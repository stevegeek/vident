# frozen_string_literal: true

require "vident2"

module PhlexV2
  # V2 sibling of Phlex::ApplicationComponent. Inherits from
  # Vident2::Phlex::HTML so subclasses pick up the V2 DSL, Resolver,
  # and Draft/Plan pipeline.
  class ApplicationComponent < ::Vident2::Phlex::HTML
    include ::Vident2::Caching
    include ::Phlex::Rails::Helpers::Routes

    if ::Rails.env.development?
      def before_template
        comment { "Before #{self.class.name}" }
        super
      end
    end
  end
end
