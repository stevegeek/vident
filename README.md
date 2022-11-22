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

- `Vident::RootElement` which is for creating
  the 'root' element in your view components. Similar to `Primer::BaseComponent` but
  exposes a simple API for configuring and adding Stimulus controllers, targets and actions.

- `Vident::Component`: A mixin for your `ViewComponent` components or `Phlex` components that provides the a helper to create the
  root element component (either in the sidecar view or directly in template-less components, eg in Phlex).

- `Vident::TypedComponent`: like `Vident::Component` but uses `dry-types` to define typed attributes for your components.

## Examples:

Let's grab a real example from a real app. In this case we are using a view from https://github.com/excid3/tailwindcss-stimulus-components/

### With ViewComponent

```ruby
class DropdownComponent < ViewComponent::Base
  def initialize(dismiss_after: 5000, remove_delay: 0)
    @dismiss_after = dismiss_after
    @remove_delay = remove_delay
  end
end
```

Here is our starting `ViewComponent` template:

```erb
<div class="relative"
    data-controller="dropdown"
    data-action="click->dropdown#toggle click@window->dropdown#hide"
    data-dropdown-active-target="#dropdown-button"
    data-dropdown-active-class="bg-teal-600"
    data-dropdown-invisible-class="opacity-0 scale-95"
    data-dropdown-visible-class="opacity-100 scale-100"
    data-dropdown-entering-class="ease-out duration-100"
    data-dropdown-enter-timeout="100"
    data-dropdown-leaving-class="ease-in duration-75"
    data-dropdown-leave-timeout="75">
  <div data-action="click->dropdown#toggle click@window->dropdown#hide" role="button" data-dropdown-target="button" tabindex="0" class="inline-block select-none">
    <%= t ".button-cta" %>
  </div>
  <div data-dropdown-target="menu" class="absolute pin-r mt-2 transform transition hidden opacity-0 scale-95">
    <div class="bg-white shadow rounded border overflow-hidden">
      <%= content %>
    </div>
  </div>
</div>
```

Some thoughts on it:

- The data attributes feel like a lot of boilerplate. Especially if I have multiple data values for the 
  controller, or multiple actions on an element.
- a Stimulus controller is often 1-1 with the ViewComponent, so why constantly repeat the controller name? 
- I want to use 'named classes', but writing out the data attributes for them is tedious.
- What happens if I want to style the root element differently in different contexts?


If we include `Vident::Component` in our component, we can render the root element and use the Stimulus helpers instead:

```ruby
class DropdownComponent < ViewComponent::Base
  include Vident::ViewComponent
  
    def initialize(dismiss_after: 5000, remove_delay: 0) 
      @dismiss_after = dismiss_after
      @remove_delay = remove_delay
    end
end
```

```erb
<%= render root_element actions: [["click@window", :hide]],
                        targets: [[:active, "#dropdown-button"]],
                        data_maps: [
                          { dismiss_after: @dismiss_after },
                          { remove_delay: @remove_delay }
                        ], 
                        named_classes: {
                           active: "bg-teal-600",
                           invisible: "opacity-0 scale-95",
                           visible: "opacity-100 scale-100",
                           entering: "ease-out duration-100",
                           leaving: "ease-in duration-75"
                         },
                        } do |dropdown| %>
  <%= dropdown.target_tag :button, 
                          actions: [[:click, :toggle]], 
                          html_options: {class: "inline-block select-none", role: "button", tabindex: 0} do %>
    <%= t ".button-cta" %>
  <% end %>
  <%= dropdown.target_tag :menu, 
                          html_options: {class: ["absolute pin-r mt-2 transform transition hidden", dropdown.named_class(:invisibile)]} do %>
    <div class="bg-white shadow rounded border overflow-hidden">
      <%= content %>
    </div>
  <% end %>
<% end %>
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
