---
title: Building components
nav_order: 1
---

# Building components

A Vident component inherits from a base class that combines Vident's
capabilities with your chosen rendering engine:

```ruby
class CardComponent < Vident::Phlex::HTML; end           # Phlex
class CardComponent < Vident::ViewComponent::Base; end   # ViewComponent
```

In an existing app, prefer to create a single `ApplicationComponent` that
inherits from one of these and have the rest of your components inherit
from that. It's the natural place for shared layout, route helpers, and
development-only instrumentation.

## Typed properties

Vident uses the [Literal gem](https://github.com/joeldrapper/literal) for
properties, so every component is type-checked at construction:

```ruby
class CardComponent < Vident::ViewComponent::Base
  prop :title, String
  prop :subtitle, String, default: ""
  prop :image_url, _Nilable(String)
  prop :size, _Union(:small, :medium, :large), default: :medium
  prop :featured, _Boolean, default: false
end
```

Pass `predicate: :public` to a `_Boolean` prop to also generate a `?`
method. If you need to derive state from props, override
`after_component_initialize` rather than Literal's `after_initialize` — the
hook lets Vident finish its own setup first:

```ruby
def after_component_initialize
  @processed = @data.transform_values(&:upcase)
end
```

If you do override `after_initialize` directly, **call `super` first**.

## The root element

Every Vident component renders its outer element through `root_element`,
which knows the right tag, ID, classes, and `data-*` attributes for the
configured Stimulus controller, values, and outlets:

```ruby
def view_template
  root_element do |card|
    h2 { @title }
    p  { @subtitle } if @subtitle.present?
  end
end

private

def root_element_classes
  ["card", @featured ? "card-featured" : nil]
end

def root_element_attributes
  {
    element_tag: @url ? :a : :div,
    html_options: {role: "article", "aria-label": @title}
  }
end
```

Built-in props on every component:

| Prop           | Default    | Purpose                                  |
| -------------- | ---------- | ---------------------------------------- |
| `element_tag`  | `:div`     | HTML tag for the root element.           |
| `id`           | auto       | DOM ID — stable per render, see below.   |
| `classes`      | `nil`      | Extra classes appended at the call site. |
| `html_options` | `{}`       | Passthrough HTML attributes.             |

## Stable element IDs

Element IDs are derived from a per-request seed so they stay deterministic
within a request (cached fragments rehydrate cleanly) without colliding
across requests. The install generator wires this up automatically. See
[Element IDs and seeding](/reference/element-ids/) for the rationale and
the alternatives if you render outside a request.

## Where to next

- [Stimulus integration](/guides/stimulus/) — actions, targets, values.
- [Phlex specifics](/guides/phlex/) and
  [ViewComponent specifics](/guides/view-component/).
- [Component caching](/guides/caching/) — `cache_component` for fragment caching.
