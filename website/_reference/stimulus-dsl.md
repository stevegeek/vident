---
title: Stimulus DSL reference
nav_order: 1
---

# Stimulus DSL reference

Every form the `stimulus do` block accepts. For the narrative version see
the [Stimulus integration guide](/guides/stimulus/).

## Actions

```ruby
stimulus do
  # Bare names — methods on the controller, default events
  actions :toggle, :expand, :collapse

  # Fluent
  action(:handle_click).on(:click)
  action(:save).on(:submit).with(:prevent, :stop)

  # Kwargs
  action :handle_submit, on: :submit, modifier: [:prevent, :stop]

  # Proc — evaluated in the component at render time
  action(-> { [stimulus_scoped_event(:my_event), :handle_this] if should_handle? })
end
```

In templates:

```ruby
greeter.stimulus_action(:click, :greet)
greeter.stimulus_actions(:greet, [:click, :another_action])
```

`.to_h` for Phlex `data:` hashes, `.to_attrs` for ERB `content_tag(...)`.

## Targets

```ruby
stimulus do
  targets :name, :output, :button
end

# Templates
greeter.stimulus_target(:output)
greeter.stimulus_targets(:name, :output)
```

## Values

```ruby
stimulus do
  # Static
  values loading_duration: 1000

  # Dynamic
  values item_count: -> { @items.count }
  values api_url:    -> { api_items_path }

  # Map a typed prop directly
  values_from_props :clicked_count, :expanded
end
```

## Classes

```ruby
stimulus do
  classes loading: "opacity-50 cursor-wait",
          size: -> { @items.count > 10 ? "large" : "small" }
end

# Inside the component
class_list_for_stimulus_classes(:loading)
```

## Outlets

The kwarg key is the **child controller identifier**. The value is either
`nil` (auto-builds `[data-controller~=<id>]` scoped to this component) or
`Vident::Selector("...css...")` for a verbatim CSS selector. A bare String
is rejected — that ambiguity used to silently produce broken outlets.

```ruby
stimulus do
  outlets toast: nil                                # auto-selector
  outlets panel: Vident::Selector(".side-panel")    # verbatim
  outlets({"admin--users" => nil})                  # namespaced child id
end

# Templates
component.stimulus_outlet(:toast)
```

## Action parameters

```ruby
stimulus do
  action(:select).on(:click).with_params(id: -> { @id })
end
```

Renders the matching `data-<controller>-id-param` attribute on the element
the action is bound to.

## Scoped custom events

```ruby
stimulus_scoped_event(:my_custom_event)
# => "<controller-identifier>:my-custom-event"
```

Useful for cross-component communication: dispatch a scoped event in one
component and listen for it on a parent's action.

## Manual configuration

For escape hatches or migrating existing components:

```ruby
def root_element_attributes
  {
    stimulus_controllers: ["custom-controller"],
    stimulus_actions: [[:click, :greet]],
    stimulus_targets: [:output],
    stimulus_values: {api_url: "/api/items"},
    stimulus_classes: {pre_click: "text-gray-500", post_click: "text-blue-700"}
  }
end
```

## Identifier overrides

By default the identifier is derived from the class name
(`PhlexGreeters::GreeterVidentComponent` →
`phlex-greeters--greeter-vident-component`). To lock to a specific path —
for example, when a Stimulus controller file lives outside the conventional
location — override the class method:

```ruby
class << self
  def stimulus_identifier_path = "phlex_greeters/greeter_vident_component"
end
```
