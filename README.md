# Vident::ViewComponent
Short description and motivation.



# Examples

Before we dive into a specific example note that there are some components implemented in the `test/dummy/app/components`.

Try them out by starting Rails:

```bash
cd test/dummy
bundle install
rails assets:precompile
rails s
```

and visiting http://localhost:3000


## A Vident component example (without Stimulus)

First is an example component that uses `Vident::ViewComponent::Base` but no Stimulus features. 

It is an avatar component that can either be displayed as an image or as initials. It supports numerous sizes and shapes and can optionally have a border. It also generates a cache key for use in fragment caching or etag generation.

```ruby
class AvatarComponent < ::Vident::ViewComponent::Base
  include ::Vident::Tailwind
  include ::Vident::ViewComponent::Caching

  no_stimulus_controller
  with_cache_key :attributes

  attribute :url, allow_nil: true
  attribute :initials, allow_nil: false

  attribute :shape, default: :circle

  attribute :border, default: false

  attribute :size, default: :normal

  private

  def default_html_options
    if image_avatar?
      { class: "inline-block object-contain", src: url, alt: t(".image") }
    else
      { class: "inline-flex items-center justify-center bg-gray-500" }
    end
  end

  def element_classes
    [size_classes, shape_class, border? ? "border" : ""]
  end

  alias_method :image_avatar?, :url?

  def shape_class
    (shape == :circle) ? "rounded-full" : "rounded-md"
  end

  def size_classes
    case size
    when :tiny
      "w-6 h-6"
    when :small
      "w-8 h-8"
    when :medium
      "w-12 h-12"
    when :large
      "w-14 h-14"
    when :x_large
      "sm:w-24 sm:h-24 w-16 h-16"
    when :xx_large
      "sm:w-32 sm:h-32 w-24 h-24"
    else
      "w-10 h-10"
    end
  end

  def text_size_class
    case size
    when :tiny
      "text-xs"
    when :small
      "text-xs"
    when :medium
      "text-lg"
    when :large
      "sm:text-xl text-lg"
    when :extra_large
      "sm:text-2xl text-xl"
    else
      "text-medium"
    end
  end
end
```

```erb
<%= render root(
             element_tag: image_avatar? ? :img : :div,
             html_options: default_html_options
           ) do %>
  <% unless image_avatar? %>
    <span class="<%= text_size_class %> font-medium leading-none text-white"><%= initials %></span>
  <% end %>
<% end %>
```

Example usages:

```erb
<%= render AvatarComponent.new(url: "https://someurl.com/avatar.jpg", initials: "AB" size: :large) %>
<%= render AvatarComponent.new(url: "https://someurl.com/avatar.jpg", html_options: {alt: "My alt text", class: "object-scale-down"}) %>
<%= render AvatarComponent.new(initials: "SG", size: :small) %>
<%= render AvatarComponent.new(initials: "SG", size: :large, html_options: {class: "border-2 border-red-600"}) %>
```

The following is rendered when used `render AvatarComponent.new(initials: "SG", size: :small, border: true)`:

```html
<div class="avatar-component w-8 h-8 rounded-full border inline-flex items-center justify-center bg-gray-500" id="avatar-component-9790427-12">
  <span class="text-xs font-medium leading-none text-white">SG</span>
</div>
```

The following is rendered when used `render AvatarComponent.new(url: "https://i.pravatar.cc/300", initials: "AB", html_options: {alt: "My alt text", class: "block"})`:

```html
<img src="https://i.pravatar.cc/300" alt="My alt text" class="avatar-component w-10 h-10 rounded-full object-contain block" id="avatar-component-7083941-11">
```

----

![Example](examples/avatar.png)

## Usage
How to use my plugin.

## Installation
Add this line to your application's Gemfile:

```ruby
gem "vident-view_component"
```

And then execute:
```bash
$ bundle
```

Or install it yourself as:
```bash
$ gem install vident-view_component
```

## Contributing
Contribution directions go here.

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
