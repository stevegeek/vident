# frozen_string_literal: true

class ApplicationIndexView < ApplicationView
  def view_template
    p { "Render an avatar" }
    render AvatarComponent.new(initials: "V C")
    br
    component = AvatarComponent.new(initials: "V C", html_options: {class: "bg-red-500"})
    p {
      "The following example sets a background color override using a tailwind utility class (note that sometimes you will find overrides don't work due to CSS specificity. To solve this use the `vident-tailwind` module in your component!)"
    }
    render component
    br
    p { "Components can also have a `#cache_key` method which plays nicely with fragment caching." }
    p { "Cache Key for above component:" }
    pre { component.cache_key }
    p { "Cache Key for Avatar component with different attributes:" }
    pre { AvatarComponent.new(initials: "V C").cache_key }
  end
end
