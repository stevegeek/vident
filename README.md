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

Image the following in an application that uses ViewComponent, Stimulus and Vident:

```erb
<%= render ::GreeterComponent.new do |greeter| %>
  <% greeter.trigger(
       before_clicked: "Greet",
       after_clicked: "Greeted! Reset?",
       actions: [
         greeter.action(:click, :greet),
       ],
       html_options: {
         class: "bg-red-500 hover:bg-red-700"
       }
     ) %>
<% end %>
```

Where the components are defined as follows:

```ruby
# app/components/greeter_component.rb

class GreeterComponent < ViewComponent::Base
  include Vident::Component

  renders_one :trigger, ButtonComponent
end
```

```erb
<%# app/components/greeter_component.html.erb %>

<%= render root named_classes: {
  pre_click: "text-md text-gray-500",
  post_click: "text-xl text-blue-700"
} do |greeter| %>
  <input type="text"
         <%= greeter.as_target(:name) %>
         class="shadow appearance-none border rounded py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline">
  <% if trigger? %>
    <%= trigger %>
  <% else %>
    <%= trigger(cta: "Greet", actions: greeter.action(:click, :greet)) %>
  <% end %>
  <!-- you can also use the `target_tag` helper to render targets -->
  <%= greeter.target_tag(:span, :output, class: "ml-4 #{greeter.named_classes(:pre_click)}") do %>
    ...
  <% end %>
<% end %>

```

```js
// app/components/greeter_component_controller.js

import { Controller } from "@hotwired/stimulus"

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
  }
}
```

The slot renders this component:

```ruby
# app/components/button_component.rb

class ButtonComponent < ViewComponent::Base
  include Vident::TypedComponent

  attribute :after_clicked, String, default: "Greeted!"
  attribute :before_clicked, String, default: "Greet"

  def call
    root_tag = root(
      element_tag: :button,
      actions: [:change_message],
      data_maps: [{after_clicked_message: after_clicked, before_clicked_message: before_clicked}],
      html_options: {class: "ml-4 whitespace-no-wrap bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded"}
    )
    render root_tag do
      @before_clicked
    end
  end
end
```

```js  
// app/components/button_component_controller.js

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  changeMessage() {
    this.clicked = !this.clicked;
    this.element.textContent = this.clicked ? this.data.get("afterClickedMessage") : this.data.get("beforeClickedMessage");
  }
}

```

Generates the following HTML for you:

```html 
<div class="greeter-component" 
     data-controller="greeter-component" 
     data-greeter-component-pre-click-class="text-md text-gray-500" 
     data-greeter-component-post-click-class="text-xl text-blue-700" 
     id="greeter-component-1599855-6">
  <input type="text" 
         data-greeter-component-target="name" 
         class="shadow appearance-none border rounded py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline">
  <button class="greeter-button-component ml-4 whitespace-no-wrap bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded bg-red-500 hover:bg-red-700" 
          data-controller="greeter-button-component" 
          data-action="click->greeter-component#greet greeter-button-component#changeMessage" 
          data-greeter-button-component-after-clicked-message="Greeted! Reset?" 
          data-greeter-button-component-before-clicked-message="Greet" 
          id="greeter-button-component-7799479-7">Greet</button>
  <!-- you can also use the `target_tag` helper to render targets -->
  <span class="ml-4 text-md text-gray-500" 
        data-greeter-component-target="output">
    ...
  </span>
</div>
```

![img_1.png](img_1.png)
![img.png](img.png)

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
