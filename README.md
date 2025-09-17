# Vident

Vident is a collection of gems that provide a set of tools for building web applications with Ruby on Rails.

## Included Gems

The core gems:

- `vident`: The core Vident library
- `vident-phlex`: Phlex integration for Vident
- `vident-view_component`: ViewComponent integration for Vident

Note that you can use both `Phlex` and `ViewComponent` in the same application if desired.

And then optional extra features:

- `vident-tailwind`: Tailwind CSS integration for Vident
- `vident-typed`: Type system for Vident components
- `vident-typed-minitest`: Minitest integration for typed Vident components
- `vident-typed-phlex`: Phlex integration for typed Vident components
- `vident-typed-view_component`: ViewComponent integration for typed Vident

## Directory Structure

The repository is structured like this:

```
vident/
├── lib/                       # All gem code
│   ├── vident.rb              # Core entry point
│   ├── vident-phlex.rb        # Gem entry points
├── test/                      # All tests
│   ├── vident/                # Core tests
│   ├── vident-phlex/          # Tests for each gem
│   └── ...
├── docs/                      # Documentation
├── examples/                  # Examples
├── vident.gemspec            # Gemspec for core gem
├── vident-phlex.gemspec      # Gemspecs for each gem
└── ...
```

## Development

### Setting Up Development Environment

```bash
# Clone the repository
git clone https://github.com/stevegeek/vident.git
cd vident

# Install dependencies
bundle install
```

### Running Tests

To run tests for all gems:

```bash
rake test
```

To run tests for a specific gem:

```bash
rake test:vident-phlex
```

### Building and Installing Gems

To build all gems:

```bash
rake build
```

To install all gems locally:

```bash
rake install
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## License

The gems are available as open source under the terms of the [MIT License](LICENSE.txt).

---

# Component Documentation

---

## gem: vident-typed-view_component

# Vident::Typed::ViewComponent

Adds typed attributes to Vident ViewComponent components.

```ruby
class ApplicationComponent < ::Vident::Typed::ViewComponent::Base
end
```

For more details see [vident](https://github.com/stevegeek/vident).

### Examples

Before we dive into a specific example note that there are some components implemented in `test/dummy/app/components`.

Try them out by starting Rails:

```bash
cd test/dummy
bundle install
rails assets:precompile
rails s
```

and visiting http://localhost:3000


### A Vident component example (without Stimulus)

First is an example component that uses `Vident::Typed::ViewComponent::Base` but no Stimulus features.

It is an avatar component that can either be displayed as an image or as initials.

It supports numerous sizes and shapes and can optionally have a border. It also generates a cache key for use in fragment caching or etag generation.

```ruby
class AvatarComponent < ::Vident::Typed::ViewComponent::Base
  include ::Vident::Tailwind
  include ::Vident::Caching

  no_stimulus_controller
  with_cache_key :attributes

  attribute :url, String, allow_nil: true, allow_blank: false
  attribute :initials, String, allow_blank: false

  attribute :shape, Symbol, in: %i[circle square], default: :circle

  attribute :border, :boolean, default: false

  attribute :size, Symbol, in: %i[tiny small normal medium large x_large xx_large], default: :normal

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
<!-- These will render -->
<%= render AvatarComponent.new(url: "https://someurl.com/avatar.jpg", initials: "AB" size: :large) %>
<%= render AvatarComponent.new(url: "https://someurl.com/avatar.jpg", html_options: {alt: "My alt text", class: "object-scale-down"}) %>
<%= render AvatarComponent.new(initials: "SG", size: :small) %>
<%= render AvatarComponent.new(initials: "SG", size: :large, html_options: {class: "border-2 border-red-600"}) %>

<!-- These will raise an error -->
<!-- missing initals -->
<%= render AvatarComponent.new(url: "https://someurl.com/avatar.jpg", size: :large) %> 
<!-- initials blank -->
<%= render AvatarComponent.new(initials: "", size: :large) %> 
 <!-- invalid size -->
<%= render AvatarComponent.new(initials: "SG", size: :foo_bar) %>
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


### Another ViewComponent + Vident example with Stimulus

Consider the following ERB that might be part of an application's views. The app uses `ViewComponent`, `Stimulus` and `Vident`.

The Greeter is a component that displays a text input and a button. When the button is clicked, the text input's value is
used to greet the user. At the same time the button changes to be a 'reset' button, which resets the greeting when clicked again.

![ex1.gif](examples/ex1.gif)

```erb
<%# app/views/home/index.html.erb %>

<!-- ... -->

<!-- render the Greeter ViewComponent (that uses Vident) -->
<%= render ::GreeterComponent.new(cta: "Hey!", html_options: {class: "my-4"}) do |greeter| %>
  <%# this component has a slot called `trigger` that renders a `ButtonComponent` (which also uses Vident) %> 
  <% greeter.with_trigger(
       
       # The button component has attributes that are typed
       before_clicked: "Greet",
       after_clicked: "Greeted! Reset?",
       
       # A stimulus action is added to the button that triggers the `greet` action on the greeter stimulus controller.
       # This action will be added to any defined on the button component itself
       actions: [
         greeter.action(:click, :greet),
       ],
       
       # We can also override the default button classes of our component, or set other HTML attributes
       html_options: {
         class: "bg-red-500 hover:bg-red-700"
       }
     ) %>
<% end %>

<!-- ... -->
```

The output HTML of the above, using Vident, is:

```html 
<div class="greeter-component py-2 my-4" 
     data-controller="greeter-component" 
     data-greeter-component-pre-click-class="text-md text-gray-500" 
     data-greeter-component-post-click-class="text-xl text-blue-700" 
     id="greeter-component-1599855-6">
  <input type="text" 
         data-greeter-component-target="name" 
         class="shadow appearance-none border rounded py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline">
  <button class="button-component ml-4 whitespace-no-wrap bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded bg-red-500 hover:bg-red-700" 
          data-controller="button-component" 
          data-action="click->greeter-component#greet button-component#changeMessage" 
          data-button-component-after-clicked-message="Greeted! Reset?" 
          data-button-component-before-clicked-message="Greet" 
          id="button-component-7799479-7">Hey!</button>
  <!-- you can also use the `target_tag` helper to render targets -->
  <span class="ml-4 text-md text-gray-500" 
        data-greeter-component-target="output">
    ...
  </span>
</div>
```

Let's look at the components in more detail.

The main component is the `GreeterComponent`:

```ruby
# app/components/greeter_component.rb

class GreeterComponent < ::Vident::ViewComponent::Base
  renders_one :trigger, ButtonComponent
end
```

```erb
<%# app/components/greeter_component.html.erb %>

<%# Rendering the `root` element creates a tag which has stimulus `data-*`s, a unique id & other attributes set. %>
<%# The stimulus controller name (identifier) is derived from the component name, and then used to generate the relavent data attribute names. %>

<%= render root named_classes: {
  pre_click: "text-md text-gray-500", # named classes are exposed to Stimulus as `data-<controller>-<n>-class` attributes
  post_click: "text-xl text-blue-700",
  html_options: {class: "py-2"}
} do |greeter| %>

  <%# `greeter` is the root element and exposes methods to generate stimulus targets and actions %>
  <input type="text"
         <%= greeter.as_target(:name) %>
         class="shadow appearance-none border rounded py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline">
  
  <%# Render the slot %>
  <%= trigger %>
  
  <%# you can also use the `target_tag` helper to render targets %>
  <%= greeter.target_tag(
        :span, 
        :output, 
        # Stimulus named classes can be referenced to set class attributes at render time
        class: "ml-4 #{greeter.named_classes(:pre_click)}" 
      ) do %>
    ...
  <% end %>
<% end %>

```

```js
// app/components/greeter_component_controller.js

import { Controller } from "@hotwired/stimulus"

// This is a Stimulus controller that is automatically registered for the `GreeterComponent`
// and is 'sidecar' to the component. You can see that while in the ERB we use Ruby naming conventions
// with snake_case Symbols, here they are converted to camelCase names. We can also just use camelCase 
// in the ERB if we want.
export default class extends Controller {
  static targets = [ "name", "output" ]
  static classes = [ "preClick", "postClick" ]

  greet() {
    this.clicked = !this.clicked;
    this.outputTarget.classList.toggle(this.preClickClasses, !this.clicked);
    this.outputTarget.classList.toggle(this.postClickClasses, this.clicked);

    if (this.clicked)
      this.outputTarget.textContent = `Hello, ${this.nameTarget.value}!`
    else
      this.clear();
  }

  clear() {
    this.outputTarget.textContent = '...';
    this.nameTarget.value = '';
  }
}
```

The slot renders a `ButtonComponent` component:

```ruby
# app/components/button_component.rb

class ButtonComponent < ::Vident::Typed::ViewComponent::Base
  # The attributes can specify an expected type, a default value and if nil is allowed.
  attribute :after_clicked, String, default: "Greeted!"
  attribute :before_clicked, String, allow_nil: false

  # This example is a templateless ViewComponent.
  def call
    # The button is rendered as a <button> tag with an click action on its own controller.
    render root(
      element_tag: :button,
      
      # We can define actions as arrays of Symbols, or pass manually manually crafted strings.
      # Here we specify the action name only, implying an action on the current components controller
      # and the default event type of `click`.
      actions: [:change_message],
      # Alternatively: [:click, :change_message] or ["click", "changeMessage"] or even "click->button-component#changeMessage"
      
      # A couple of data values are also set which will be available to the controller
      data_maps: [{after_clicked_message: after_clicked, before_clicked_message: before_clicked}],
      
      # The <button> tag has a default styling set directly on it. Note that
      # if not using utility classes, you can style the component using its 
      # canonical class name (which is equal to the component's stimulus identifier), 
      # in this case `button-component`.
      html_options: {class: "ml-4 whitespace-no-wrap bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded"}
    ) do
      @before_clicked
    end
  end
end
```

```js  
// app/components/button_component_controller.js

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  // The action is in camelCase.
  changeMessage() {
    this.clicked = !this.clicked;
    // The data attributes have their naming convention converted to camelCase.
    this.element.textContent = this.clicked ? this.data.get("afterClickedMessage") : this.data.get("beforeClickedMessage");
  }
}

```

### Usage
How to use my plugin.

### Installation
Add this line to your application's Gemfile:

```ruby
gem "vident-typed-view_component"
```

And then execute:
```bash
$ bundle
```

Or install it yourself as:
```bash
$ gem install vident-typed-view_component
```

---


## gem: vident-view_component

# Vident::ViewComponent

[ViewComponent](https://viewcomponent.org/) powered [Vident](https://github.com/stevegeek/vident) components.

```ruby
class ApplicationComponent < ::Vident::ViewComponent::Base
end
```

For more details see [vident](https://github.com/stevegeek/vident).

### Examples

Before we dive into a specific example note that there are some components implemented in the `test/dummy/app/components`.

Try them out by starting Rails:

```bash
cd test/dummy
bundle install
rails assets:precompile
rails s
```

and visiting http://localhost:3000


### A Vident component example (without Stimulus)

First is an example component that uses `Vident::ViewComponent::Base` but no Stimulus features. 

It is an avatar component that can either be displayed as an image or as initials. It supports numerous sizes and shapes and can optionally have a border. It also generates a cache key for use in fragment caching or etag generation.

```ruby
class AvatarComponent < ::Vident::ViewComponent::Base
  include ::Vident::Tailwind
  include ::Vident::Caching

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

### Usage
How to use my plugin.

### Installation
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

## gem: vident-phlex

# Vident::Phlex

[Phlex](https://phlex.fun/) powered [Vident](https://github.com/stevegeek/vident) components.

```ruby
class ApplicationComponent < ::Vident::Phlex::HTML
end
```

For more details see [vident](https://github.com/stevegeek/vident).

### Usage
How to use my plugin.

### Installation
Add this line to your application's Gemfile:

```ruby
gem "vident-phlex"
```

And then execute:
```bash
$ bundle
```

Or install it yourself as:
```bash
$ gem install vident-phlex
```

---

## gem: vident-tailwind

# Vident::Tailwind
Short description and motivation.

### Usage
How to use my plugin.

### Installation
Add this line to your application's Gemfile:

```ruby
gem "vident-tailwind"
```

And then execute:
```bash
$ bundle
```

Or install it yourself as:
```bash
$ gem install vident-tailwind
```

---

## gem: vident-typed-minitest

# Vident::Typed::Minitest
Short description and motivation.

### Usage
How to use my plugin.

### Installation
Add this line to your application's Gemfile:

```ruby
gem "vident-typed-minitest"
```

And then execute:
```bash
$ bundle
```

Or install it yourself as:
```bash
$ gem install vident-typed-minitest
```

---

## gem: vident-typed-phlex

# Vident::Typed::Phlex

Adds typed attributes to Vident Phlex based components.

```ruby
class ApplicationComponent < ::Vident::Typed::Phlex::HTML
end
```

For more details see [vident](https://github.com/stevegeek/vident).

### Usage
How to use my plugin.

### Installation
Add this line to your application's Gemfile:

```ruby
gem "vident-typed-phlex"
```

And then execute:
```bash
$ bundle
```

Or install it yourself as:
```bash
$ gem install vident-typed-phlex
```

---


## gem: vident-typed

# Vident::Typed
Short description and motivation.

### Usage
How to use my plugin.

### Installation
Add this line to your application's Gemfile:

```ruby
gem "vident-typed"
```

And then execute:
```bash
$ bundle
```

Or install it yourself as:
```bash
$ gem install vident-typed
```

---