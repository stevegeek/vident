# Vident

Vident helps you create flexible & maintainable component libraries for your application.

Vident makes using Stimulus with your [`ViewComponent`](https://viewcomponent.org/) or [`Phlex`](https://phlex.fun) components easier.

## Things still to do...

This is a work in progress. Here's what's left to do for first release:

- Iterate on the interfaces and functionality
- Add tests
- Make the gem more configurable to fit more use cases
- Create an example library of a few components for some design system
  - Create a demo app with `lookbook` and those components
- Add more documentation
- split `vident` into `vident` + `vident-rails` gems (and maybe `vident-rspec`) (Phlex can be used outside of Rails)
  - possibly also split into `vident-phlex` and `vident-view_component` gems ?

# Motivation

I love working with Stimulus, but I find manually crafting the data attributes for
targets and actions error prone and tedious. Vident aims to make this process easier
and keep me thinking in Ruby. 

I have been using Vident with `ViewComponent` in production apps for a while now and it has been constantly
evolving.

This gem is a work in progress and I would love to get your feedback and contributions!

## What does Vident provide?

- `Vident::Component`: A mixin for your `ViewComponent` components or `Phlex` components that provides the a helper to create the
  root element component (in templated or template-less components).

- `Vident::TypedComponent`: like `Vident::Component` but uses `dry-types` to define typed attributes for your components.

- `Vident::RootComponent::*` which are components for creating the 'root' element in your view components. Similar to `Primer::BaseComponent` but
  exposes a simple API for configuring and adding Stimulus controllers, targets and actions. Normally you create these
  using the `root` helper method on `Vident::Component`/`Vident::TypedComponent`.

# Example

Consider the following ERB that might be part of an application's views. The app uses `ViewComponent`, `Stimulus` and `Vident`.

The Greeter is a component that displays a text input and a button. When the button is clicked, the text input's value is
used to greet the user. At the same time the button changes to be a 'reset' button, which resets the greeting when clicked again.

![ex1.gif](examples%2Fex1.gif)

```erb
<%# app/views/home/index.html.erb %>

<!-- ... -->

<!-- render the Greeter ViewComponent (that uses Vident) -->
<%= render ::GreeterComponent.new do |greeter| %>
  <%# this component has a slot called `trigger` that renders a `ButtonComponent` (which also uses Vident) %> 
  <% greeter.trigger(
       
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
<div class="greeter-component" 
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
          id="button-component-7799479-7">Greet</button>
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

class GreeterComponent < ViewComponent::Base
  include Vident::Component

  renders_one :trigger, ButtonComponent
end
```

```erb
<%# app/components/greeter_component.html.erb %>

<%# Rendering the `root` element creates a tag which has stimulus `data-*`s, a unique id & other attributes set. %>
<%# The stimulus controller name (identifier) is derived from the component name, and then used to generate the relavent data attribute names. %>

<%= render root named_classes: {
  pre_click: "text-md text-gray-500", # named classes are exposed to Stimulus as `data-<controller>-<name>-class` attributes
  post_click: "text-xl text-blue-700"
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

class ButtonComponent < ViewComponent::Base
  # This component uses Vident::TypedComponent which uses dry-types to define typed attributes.
  include Vident::TypedComponent

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

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'vident'
```

Also ensure you have installed your chosen view component library, eg:

```ruby
gem 'view_component'
```

or

```ruby
gem 'phlex' # Must be version 0.5 or higher
```

or **both**!

If you want to use typed attributes you must also include `dry-struct`

```ruby
gem 'dry-struct'
```

And then execute:

    $ bundle install

## Making 'sidecar' Stimulus Controllers work

### When using `stimulus-rails`, `sprockets-rails` & `importmap-rails`

Pin any JS modules from under `app/views` and `app/components` which are sidecar with their respective components.

Add to `config/importmap.rb`:

```ruby
components_directories = [Rails.root.join("app/components"), Rails.root.join("app/views")]
components_directories.each do |components_path|
  prefix = components_path.basename.to_s
  components_path.glob("**/*_controller.js").each do |controller|
    name = controller.relative_path_from(components_path).to_s.remove(/\.js$/)
    pin "#{prefix}/#{name}", to: name
  end
end
```

Note we don't use `pin_all_from` as it is meant to work with a subdirectory in `assets.paths`
See this for more: https://stackoverflow.com/a/73228193/268602

Then we need to ensure that sprockets picks up those files in build, so add
to the `app/assets/config/manifest.js`:

```js
//= link_tree ../../components .js
//= link_tree ../../views .js
```

We also need to add to `assets.paths`. Add to your to `config/application.rb`

```ruby
config.importmap.cache_sweepers.append(Rails.root.join("app/components"), Rails.root.join("app/views"))
config.assets.paths.append("app/components", "app/views")
```

### When using `webpacker`

TODO

### When using `propshaft`

TODO

## Using TypeScript for Stimulus Controllers

TODO

## Usage

TODO: Write usage instructions here

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Running the Examples in `test/dummy`

```bash
cd test/dummy
bundle install
rails assets:precompile
rails s
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/stevegeek/vident. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/vident/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Vident project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/vident/blob/master/CODE_OF_CONDUCT.md).
