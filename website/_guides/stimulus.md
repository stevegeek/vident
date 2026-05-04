---
title: Stimulus integration
nav_order: 2
---

# Stimulus integration

Every Vident component gets a `stimulus do` block. Whatever you declare
inside resolves against the component's controller identifier — derived
from the class name unless you override `stimulus_identifier_path` — and
turns into the right `data-*` attributes when the component renders.

```ruby
class ToggleComponent < Vident::ViewComponent::Base
  prop :expanded, _Boolean, default: false

  stimulus do
    actions :toggle, :expand, :collapse
    targets :button, :panel
    values_from_props :expanded
    classes hidden: "hidden", visible: "block"
  end
end
```

## Actions

Three forms — pick whichever reads best:

```ruby
stimulus do
  # Fluent: "the handle_click method fires on the click event"
  action(:handle_click).on(:click)

  # Kwargs shorthand
  action :handle_submit, on: :submit, modifier: [:prevent, :stop]

  # Proc — evaluated in the component instance at render time
  action(-> { [stimulus_scoped_event(:my_event), :handle_this] if should_handle? })
end
```

In templates, `stimulus_action(:click, :greet)` returns a value object you
can spread into a tag's `data:` hash. A plain `actions :greet, :reset`
declaration registers the methods up front so the rendered controller
attribute lists them all at once.

## Targets and values

```ruby
stimulus do
  targets :name, :output

  # Static values
  values loading_duration: 1000
  # Dynamic values — evaluated in the component context at render time
  values item_count: -> { @items.count }, api_url: -> { api_items_path }
  # Map a typed prop straight to a Stimulus value
  values_from_props :clicked_count
end
```

In templates use `stimulus_target(:output)` and
`stimulus_targets(:name, :output)` (both return value objects with `.to_h`
for spreading into Phlex tags or `.to_attrs` for ERB).

## Classes and outlets

```ruby
stimulus do
  classes loading: "opacity-50 cursor-wait",
          size: -> { @items.count > 10 ? "large" : "small" }

  outlets toast: nil                                # auto: [data-controller~=toast] scoped to this component
  outlets panel: Vident::Selector(".side-panel")    # verbatim CSS selector
end
```

`class_list_for_stimulus_classes(:loading)` returns the right CSS classes
inside the component, and `stimulus_outlet(:toast)` emits the matching
`data-<controller>-<outlet>-outlet` attribute on the parent. The outlet
kwarg key is the *child controller identifier*; bare String values are
rejected (wrap with `Vident::Selector(...)` if you genuinely need a
verbatim selector).

## Manual configuration

For one-off cases (or migrating an existing component), pass `stimulus_*`
keys to `root_element_attributes`:

```ruby
def root_element_attributes
  {
    stimulus_controllers: ["custom-controller"],
    stimulus_actions: [[:click, :greet]],
    stimulus_targets: [:output],
    stimulus_values: {api_url: "/api/items"}
  }
end
```

The full list of every helper, value-object, and form is in the
[Stimulus DSL reference](/reference/stimulus-dsl/).
