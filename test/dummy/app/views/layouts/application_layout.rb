# frozen_string_literal: true

class ApplicationLayout < ApplicationView
  include ::Phlex::Rails::Layout

  def view_template(&block)
    doctype

    html do
      head do
        title { "You're awesome" }
        meta name: "viewport", content: "width=device-width,initial-scale=1"
        csp_meta_tag
        csrf_meta_tags
        stylesheet_link_tag "tailwind", "inter-font", "data-turbo-track": "reload"
        stylesheet_link_tag "application", data_turbo_track: "reload"
        javascript_importmap_tags "application"
      end

      body do
        main(class: "container mx-auto my-28 px-5 prose", &block)
      end
    end
  end
end
