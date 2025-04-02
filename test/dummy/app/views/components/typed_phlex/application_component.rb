# frozen_string_literal: true

module TypedPhlex
  class ApplicationComponent < ::Vident::Typed::Phlex::HTML
    include ::Phlex::Rails::Helpers::Routes

    if Rails.env.development?
      def before_template
        comment { "Before #{self.class.name}" }
        super
      end
    end
  end
end