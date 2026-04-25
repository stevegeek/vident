---
title: ViewComponent adapter
nav_order: 4
---

# ViewComponent adapter

`vident-view_component` ships `Vident::ViewComponent::Base` — a drop-in
base class for any project already using
[ViewComponent](https://viewcomponent.org/).

```ruby
class CardComponent < Vident::ViewComponent::Base
  prop :title, String
  prop :featured, _Boolean, default: false

  stimulus do
    targets :body
    actions :flash
  end

  def call
    root_element do |card|
      content_tag(:h2, @title)
    end
  end
end
```

A matching `card_component.html.erb` works identically to a regular
ViewComponent template; you can mix `def call` and ERB in the same project.

## ERB templates and the `root_element` helper

Inside a template:

```erb
<%= root_element do |card| %>
  <h2><%= @title %></h2>
  <%= card.child_element(:span, stimulus_target: :body) do %>
    <%= @body %>
  <% end %>
<% end %>
```

`card.stimulus_action(:click, :flash).to_attrs` returns a hash you can
splat into `content_tag` or any builder that accepts HTML attributes.

## Mixing with existing ViewComponents

Vident plays well with codebases that already have non-Vident components.
A non-Vident `ApplicationComponent` can sit alongside a
`Vident::ViewComponent::Base` subclass; only the components that need
Stimulus wiring or typed props need to inherit from the Vident base.

For projects with a lot of existing components, the cheapest first step
is to switch a single high-traffic interactive component to Vident. The
next time you rename the controller or add a target, the Vident version
will save you from chasing strings across files — that's usually the
inflection point that justifies a wider migration.
