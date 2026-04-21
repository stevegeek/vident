# frozen_string_literal: true

require "vident"

module Phlex
  # V2 sibling of Phlex::ApplicationComponent. Inherits from
  # Vident::Phlex::HTML so subclasses pick up the V2 DSL, Resolver,
  # and Draft/Plan pipeline.
  class ApplicationComponent < ::Vident::Phlex::HTML
    include ::Vident::Caching
    include ::Phlex::Rails::Helpers::Routes

    if ::Rails.env.development?
      def before_template
        comment { "Before #{self.class.name}" }
        super
      end
    end
  end
end
