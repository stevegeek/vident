# frozen_string_literal: true

module Phlex
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