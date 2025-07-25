# Vident API Reference

## Core Classes

### Vident::Component

Base module included in all Vident components.

#### Class Methods

##### `prop(name, type, options = {})`
Defines a typed property for the component, see `literal` gem documentation for how this works.

##### `stimulus(&block)`
DSL for configuring Stimulus integration.

```ruby
stimulus do
  actions ...
  targets ...
  values ...
  classes ...
  outlets ...
end
```

##### `stimulus_controller_name`
Returns the Stimulus controller identifier.

```ruby
ButtonComponent.stimulus_controller_name # => "button-component"
```

##### `stimulus_scoped_event(event_name)`
Generates a scoped event name.

```ruby
MyComponent.stimulus_scoped_event(:loaded) # => "my-component:loaded"
```

##### `stimulus_scoped_event_on_window(event_name)`
Generates a window-scoped event name.

```ruby
MyComponent.stimulus_scoped_event_on_window(:resize) 
# => "my-component:resize@window"
```

#### Instance Methods

##### `root_element(&block)`
Renders the component's root element with all configured attributes.

```erb
<%= root_element do %>
  <!-- Component content -->
<% end %>
```

##### `root_element_attributes`
Returns hash of attributes for the root element. Override to customize.

```ruby
def root_element_attributes
  {
    element_tag: :article,
    html_options: { role: "article" },
    stimulus_controllers: ["my-controller"]
  }
end
```

##### `root_element_classes`
Returns array/string of CSS classes for root element. Override to customize.

```ruby
def root_element_classes
  ["component", variant_class, size_class].compact
end
```

##### `after_component_initialize`
Hook called after component initialization.

```ruby
def after_component_initialize
  @computed_value = compute_something(@prop_value)
end
```

### Vident::ViewComponent::Base

Base class for ViewComponent-based components.

```ruby
class MyComponent < Vident::ViewComponent::Base
  # Component implementation
end
```

Inherits all methods from `Vident::Component` and `ViewComponent::Base`.

### Vident::Phlex::HTML

Base class for Phlex-based components.

```ruby
class MyComponent < Vident::Phlex::HTML
  def view_template
    root do
      # Component content
    end
  end
end
```

#### Methods

##### `root(&block)`
Phlex-specific root element renderer.

```ruby
def view_template
  root do
    h1 { "Hello" }
  end
end
```

## Stimulus DSL Methods

### Actions

##### `actions(*action_definitions)`
Defines Stimulus actions.

```ruby
# Single action (defaults to click event)
actions :save

# Action with event
actions [:submit, :handleSubmit]

# Multiple actions
actions [:click, :toggle], [:keydown, :handleKeys]

# Dynamic actions
actions -> { admin? ? :delete : nil }

# With selector
actions [[:click, ".button"], :handleClick]
```

### Targets

##### `targets(*target_names)`
Defines Stimulus targets.

```ruby
# Single target
targets :input

# Multiple targets
targets :header, :body, :footer

# Dynamic targets
targets -> { expandable? ? [:content, :toggle] : :toggle }
```

### Values

##### `values(**value_definitions)`
Defines Stimulus values.

```ruby
# Static values
values count: 0, enabled: true

# Dynamic values with procs
values api_url: -> { api_endpoint_path },
       user_name: -> { current_user.name }

# Mixed
values static: "value",
       dynamic: -> { computed_value }
```

##### `values_from_props(*prop_names)`
Maps component properties as Stimulus values.

```ruby
prop :user_id, Integer
prop :session_token, String

stimulus do
  values_from_props :user_id, :session_token
end
```

### Classes

##### `classes(**class_definitions)`
Defines Stimulus CSS classes.

```ruby
# Static classes
classes active: "bg-blue-500",
        inactive: "bg-gray-200"

# Dynamic classes
classes theme: -> { dark_mode? ? "dark" : "light" }
```

### Outlets

##### `outlets(**outlet_definitions)`
Defines Stimulus outlets.

```ruby
# Single outlet
outlets modal: "modal-component"

# Multiple outlets
outlets modal: "modal-component",
        dropdown: "dropdown-component"

# Dynamic outlets
outlets -> { feature_enabled? ? { advanced: "advanced-component" } : {} }
```

## Stimulus Helper Methods

### Attribute Generation

##### `stimulus_target(name)`
Generates target data attribute.

```ruby
component.stimulus_target(:input)
# => { "data-my-component-target" => "input" }
```

##### `stimulus_targets(*names)`
Generates multiple target attributes.

```ruby
component.stimulus_targets(:input, :output)
# => { "data-my-component-target" => "input output" }
```

##### `stimulus_action(event_or_pair, method = nil)`
Generates action data attribute.

```ruby
component.stimulus_action(:click, :save)
# => { "data-action" => "click->my-component#save" }

component.stimulus_action([:submit, :handleSubmit])
# => { "data-action" => "submit->my-component#handleSubmit" }
```

##### `stimulus_actions(*actions)`
Generates multiple action attributes.

```ruby
component.stimulus_actions(
  [:click, :save],
  [:keydown, :handleKeys]
)
# => { "data-action" => "click->my-component#save keydown->my-component#handleKeys" }
```

##### `stimulus_value(name, value)`
Generates value data attribute.

```ruby
component.stimulus_value(:count, 5)
# => { "data-my-component-count-value" => "5" }
```

##### `stimulus_class(name, css_class)`
Generates class data attribute.

```ruby
component.stimulus_class(:active, "highlighted")
# => { "data-my-component-active-class" => "highlighted" }
```

### Template Helpers

##### `as_target(name)`
Generates target attribute for direct HTML use.

```erb
<div <%= component.as_target(:content) %>>
  Content
</div>
```

##### `as_targets(*names)`
Generates multiple target attributes.

```erb
<input <%= component.as_targets(:field, :input) %>>
```

##### `as_action(event, method)`
Generates action attribute for direct HTML use.

```erb
<button <%= component.as_action(:click, :save) %>>
  Save
</button>
```

##### `as_actions(*actions)`
Generates multiple action attributes.

```erb
<form <%= component.as_actions([:submit, :handleSubmit], [:input, :validate]) %>>
```

##### `tag(name, **options, &block)`
Enhanced tag helper with Stimulus support.

```ruby
component.tag :div,
  stimulus_target: :output,
  stimulus_action: [:click, :handleClick],
  class: "output-panel" do
  "Content"
end
```

## Caching Module

### Vident::Caching

Module for adding caching support to components.

```ruby
class ExpensiveComponent < Vident::ViewComponent::Base
  include Vident::Caching
  
  with_cache_key :id, :updated_at
end
```

#### Class Methods

##### `with_cache_key(*attrs)`
Specifies attributes to use for cache key generation.

```ruby
# Use specific attributes
with_cache_key :id, :version

# Use all attributes
with_cache_key :to_h

# Custom cache key
with_cache_key ->(component) { "#{component.id}-#{component.computed_hash}" }
```

#### Instance Methods

##### `cache_key`
Returns the cache key for the component.

```ruby
component.cache_key # => "expensive-component/123-20230101120000"
```


## Type Definitions

### Literal Types

Common type patterns used with properties:

```ruby
prop :description, _Nilable(String)
prop :enabled, _Boolean
prop :status, _Union(:draft, :published, :archived)
prop :size, _Union(:sm, :md, :lg, :xl)
prop :tags, _Array(String)
prop :items, _Array(_Hash(Symbol, _Any))
prop :metadata, _Hash(String, _Any)
prop :config, _Hash(Symbol, _Union(String, Integer))
```

## Built-in Properties

Every Vident component has these properties:

### `element_tag`
- Type: `Symbol`
- Default: `:div`
- The HTML tag for the root element

### `id`
- Type: `_Nilable(String)`
- Default: Auto-generated
- The DOM ID for the component

### `classes`
- Type: `_Union(String, Array, NilClass)`
- Default: `nil`
- Additional CSS classes to merge

### `html_options`
- Type: `Hash`
- Default: `{}`
- Additional HTML attributes

## Utilities

### Class Management

##### `class_list_for(*names)`
Builds class list from various sources.

```ruby
component.class_list_for(:base, :variant, :custom)
# Merges classes from multiple methods/sources
```

##### `class_list_for_stimulus_classes(*names)`
Gets classes defined in Stimulus DSL.

```ruby
component.class_list_for_stimulus_classes(:active, :loading)
# => "bg-blue-500 opacity-50"
```

### Identifier Generation

##### `stable_id`
Generates a stable, unique identifier for the component.

```ruby
component.stable_id # => "button-component-a1b2c3d4"
```

## Error Classes

### Vident::MissingPropertyError
Raised when a required property is not provided.

### Vident::InvalidPropertyError
Raised when a property value fails type validation.

### Vident::ConfigurationError
Raised for configuration-related errors.

## Integration Hooks

### Rails Integration

Vident automatically integrates with Rails helpers in ViewComponents, and in Phlex components you should 
include the helpers you need via modules, see the https://www.phlex.fun/rails/helpers.html documentation

### Asset Pipeline Integration

For sidecar controllers, configure your asset pipeline:

```ruby
# config/application.rb
config.importmap.cache_sweepers.append(
  Rails.root.join("app/components")
)
config.assets.paths.append("app/components")
```

### Turbo Integration

Components work seamlessly with Turbo:

```ruby
class TurboComponent < Vident::ViewComponent::Base
  include Turbo::FramesHelper
  
  def turbo_frame_tag(...)
    helpers.turbo_frame_tag(...)
  end
end
```