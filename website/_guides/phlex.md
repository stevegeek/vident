---
title: Phlex adapter
nav_order: 3
---

# Phlex adapter

`vident-phlex` ships `Vident::Phlex::HTML`, a base class that combines
`Phlex::HTML` with Vident's capabilities.

```ruby
class CardComponent < Vident::Phlex::HTML
  prop :title, String

  def view_template
    root_element do |card|
      h2 { @title }
      yield card if block_given?
    end
  end
end
```

## Helpers worth knowing

- **`root_element`** yields the component instance so you can call
  `card.stimulus_target(:body)`, `card.child_element(...)`, etc., from
  inside the template.
- **`child_element(:tag, stimulus_target: :name, class: "...") { … }`**
  renders a child tag with the right `data-*` attributes attached — the
  Phlex equivalent of writing `data: greeter.stimulus_target(:name).to_h`
  inline. Only valid **inside `view_template`** — it writes to Phlex's
  render buffer, so calling it from an external ERB partial, a helper, or
  `ApplicationController.renderer.render` raises
  `undefined method 'buffer' for nil`. From outside the render lifecycle,
  use `as_stimulus_target(:name)` (returns an HTML-safe `data-*` string)
  or spread `data: { **component.stimulus_target(:name) }` instead.
- **`vanish(&)`** consumes the outer block's content so configuration-only
  child blocks (slot setters that mutate state but render nothing) don't
  end up in the output.

## Slot-like patterns

Phlex doesn't have ViewComponent's `renders_one`. The common pattern is a
memoised method that doubles as the slot setter:

```ruby
def trigger(**args)
  @trigger ||= GreeterButtonComponent.new(**args)
end

def view_template(&)
  vanish(&)                 # the outer block's content was just config
  root_element do |greeter|
    render @trigger if @trigger
  end
end
```

See `PhlexGreeters::GreeterWithTriggerComponent` in the dummy app for a
worked example.

## App layout

A typical Phlex app sets up an `ApplicationView`/`ApplicationLayout` pair
and an `ApplicationComponent` that inherits from `Vident::Phlex::HTML`.
That's where you include things like `Phlex::Rails::Helpers::Routes` and
optional development-only instrumentation:

```ruby
module App
  class ApplicationComponent < ::Vident::Phlex::HTML
    include ::Phlex::Rails::Helpers::Routes

    if Rails.env.development?
      def before_template
        comment { "Before #{self.class.name}" }
        super
      end
    end
  end
end
```
