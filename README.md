# Vident

Vident makes using Stimulus with your `ViewComponent` or `Phlex` view components as
easy as writing Ruby. 

# Why?

I love working with Stimulus, but I find manually crafting the data attributes for
targets and actions error prone and tedious. Vident aims to make this process easy
and keeps me thinking in Ruby. 

I have been using Vident in production apps for over a year now and it has been constantly
evolving.

This gem is a work in progress and I would love to get your feedback and contributions!

## What does Vident provide?

- `Vident::Component`: A mixin for your `ViewComponent` components or `Phlex` components that provides the a helper to create the
  root element component (either in the sidecar view or directly in template-less components, eg in Phlex).

- `Vident::TypedComponent`: like `Vident::Component` but uses `dry-types` to define typed attributes for your components.

- `Vident::RootElement` which is for creating
  the 'root' element in your view components. Similar to `Primer::BaseComponent` but
  exposes a simple API for configuring and adding Stimulus controllers, targets and actions.


## The Stimulus Greeter Example

Let's grab a real example from a real app. In this case we are using the example from https://stimulus.hotwired.dev/

Start with a simple `ViewComponent` component implementation of the Stimulus Greeter example:

`app/components/hello_component.rb`

```ruby
class HelloComponent < ViewComponent::Base
  def initialize(cta: "Greet")
    @cta = cta
  end
end
```

Here is our starting `ViewComponent` template:

`app/components/hello_component.html.erb`

```erb
<!--HTML from anywhere-->
<div data-controller="hello">
  <input data-hello-target="name" type="text">

  <button data-action="click->hello#greet">
    <%= @cta %>
  </button>

  <span data-hello-target="output">
  </span>
</div>
```

`app/javascript/controllers/hello_controller.js`

```js
import { Controller } from "stimulus"

export default class extends Controller {
  static targets = [ "name", "output" ]

  greet() {
    this.outputTarget.textContent =
      `Hello, ${this.nameTarget.value}!`
  }
}
```

Some thoughts on using Stimulus:

- The HTML data attributes may feel cumbersome. Especially if I have multiple data values for the 
  controller, or multiple actions on an element. The Greeter example is simple, but it can get much more complex.
- a Stimulus controller is often 1-1 with the ViewComponent, so why repeat the controller name? 
- I want to use 'named classes', but writing out the data attributes for them is tedious.
- What happens if I want to style the root element differently in different contexts?

### Enter Vident...

Let's include `Vident::Component` in our component, 

```ruby
class HelloComponent < ViewComponent::Base
  include Vident::Component
  
  attributes(cta: "Greet")
  # Or => attribute :cta, default: "Greet"
end
```

We can now render the root/parent element and use helpers to create our Stimulus attributes.

Note that the JavaScript remains unchanged but now it can be 'sidecared' in the same directory as the component:
`app/components/hello_controller.js`

For the template, there are a few ways we might approach it.

First we can have Vident create the `data-*` attributes and output them directly to our HTML:

```erb
<%= render root do |greeter| %>
  <input type="text" <%= greeter.as_target(:name) %>>

  <button <%= greeter.with_actions([:click, :greet]) %>>
    <%= @cta %>
  </button>

  <span <%= greeter.as_target(:output) %>>
  </span>
<% end %>
```

Alternatively we can use methods such as `target_tag`. Also imagine the button was actually a ViewComponent too 
(which used Vident) then we could do this:

```erb
<%= render root do |greeter| %>
  <%= greeter.target_tag :input, :name, html_options: {type: "text"} %>
 
  <%= render ::ButtonComponent.new(actions: [greeter.action(:click, :greet)]) do |button| %>
    <%= @cta %>
  <% end %>

  <%= greeter.target_tag :span, :output %>
<% end %>
```

By rendering the root component like this, we can now manipulate that element from the points at which we render it.

For example:

```erb
<%= render AnotherComponent.new do |another_component|%>
  <%= render ::HelloComponent.new(
    targets: [another_component.target(:my_greeter)], # The Greeters outer <div> will have the 'data-another-component-target="myGreeter"' attribute added to it
    cta: "Greet Me",
    html_options: {class: "bg-red-500"}
  ) %>
<% end %>
```

### Typed attributes with TypedComponent

With types on the attributes

```ruby
class HelloComponent < ViewComponent::Base
  include Vident::TypedComponent
  
  attribute :cta, String, default: "Greet"
end
```

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'vident'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install vident

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



## Usage

TODO: Write usage instructions here

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/vident. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/vident/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Vident project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/vident/blob/master/CODE_OF_CONDUCT.md).
