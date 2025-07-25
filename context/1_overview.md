# Vident Architecture Overview

## Purpose

Vident is a Ruby gem that enhances Rails view components with type-safe properties and seamless Stimulus.js integration. 
It simplifies maintaining the server-side component and client-side interactivity by automatically generating 
Stimulus data attributes from Ruby component definitions.

## Core Architecture

### Component System

Vident provides base classes for two popular rendering engines:
- `Vident::ViewComponent::Base` - For ViewComponent-based components
- `Vident::Phlex::HTML` - For Phlex-based components

Both inherit from `Vident::Component` which provides:
- Type-safe property declarations via Literal gem
- Stimulus.js integration via declarative DSL
- Intelligent CSS class management
- Component caching capabilities
- Root element rendering helpers

### Key Modules and Classes

#### Component Core (`lib/vident/component.rb`)
- Base component functionality
- Property system integration
- Stimulus component mixing
- Class management

#### Stimulus Integration (`lib/vident/stimulus_component.rb`)
- Stimulus controller generation
- Data attribute building
- Event scoping
- Outlet management

#### Property System
- Uses Literal gem for type checking
- Supports default values, nullable types, unions
- Creates getter methods and predicate methods for booleans
- Validates property values at initialization

### Data Flow

1. **Component Definition**: Developer defines component class with properties and Stimulus configuration
2. **Instantiation**: Component is instantiated with property values
3. **Attribute Resolution**: Component resolves all attributes including Stimulus data attributes
4. **Rendering**: Component renders HTML with all necessary attributes
5. **Client-side**: Stimulus controllers automatically connect and initialize

## Key Concepts

### Properties
Properties are typed attributes that define the component's interface:
- Enforced at runtime via Literal gem
- Support complex types (arrays, hashes, unions)
- Can have defaults (static or dynamic via procs)
- Built-in properties: `element_tag`, `id`, `classes`, `html_options`

### Stimulus DSL
Declarative configuration for Stimulus controllers:
- **Controllers**: Auto-generated based on component class name
- **Actions**: DOM events mapped to controller methods
- **Targets**: DOM element references
- **Values**: Data passed to controller
- **Classes**: CSS classes for different states
- **Outlets**: References to other Stimulus controllers

### Root Element
Special helper that renders the component's outermost HTML element:
- Configurable tag name
- Merges all CSS classes intelligently
- Includes all Stimulus data attributes
- Supports custom HTML attributes

### Class Management
Intelligent merging of CSS classes from multiple sources:
- Component-defined classes
- Classes passed at render time
- Stimulus class definitions
- Tailwind CSS conflict resolution (when available)

## Component Lifecycle

1. **Initialization**
   - Properties validated and set
   - `after_component_initialize` hook called
   - Stimulus configuration evaluated

2. **Attribute Resolution**
   - `root_element_attributes` method called
   - Stimulus attributes generated
   - CSS classes merged
   - HTML options combined

3. **Rendering**
   - Template rendered (ERB for ViewComponent, Ruby for Phlex)
   - Root element helper injects all attributes
   - Child components rendered if present

4. **Client-side Connection**
   - Stimulus finds elements with data-controller
   - Controllers instantiated
   - Values, targets, and actions connected

## Integration Points

### Stimulus Integration
- Generates standard Stimulus data attributes
- Compatible with stimulus-rails gem
- Supports sidecar controller files

### CSS Framework Integration
- Built-in Tailwind CSS class merging
- Maintains class order precedence

## Performance Considerations

- Supports fragment caching via `Vident::Caching`

## Extensibility

- Custom base classes for shared behavior
- Pluggable class merging strategies
- Hookable lifecycle methods

# Vident LLM Reference

Rails component library for building interactive, type-safe components with Stimulus.js integration. Supports ViewComponent and Phlex rendering engines.

## Core Features
- Type-safe properties using Literal gem
- First-class Stimulus.js integration with declarative DSL
- Support for ViewComponent and Phlex
- Intelligent CSS class management with Tailwind CSS merging
- Component caching for performance
- Automatic Stimulus controller naming and data attribute generation

## Installation
```ruby
gem "vident"                 # Core gem
gem "vident-view_component"  # ViewComponent support
gem "vident-phlex"           # Phlex support
```

## Base Classes
- ViewComponent: `Vident::ViewComponent::Base`
- Phlex: `Vident::Phlex::HTML`

## Property Definition
```ruby
# Type-safe properties using Literal gem
prop :text, String, default: "Click me"
prop :url, _Nilable(String)
prop :style, _Union(:primary, :secondary), default: :primary
prop :enabled, _Boolean, default: false
prop :items, _Array(String), default: -> { [] }
prop :count, Integer, default: 0
```

## Built-in Properties
- `element_tag` - Root HTML tag (default: :div)
- `id` - DOM ID (auto-generated if not provided)
- `classes` - Additional CSS classes
- `html_options` - Hash of HTML attributes

## Stimulus DSL
```ruby
stimulus do
  # Define actions controller responds to
  actions :click, :toggle, :expand, :collapse
  
  # Define targets for DOM element references
  targets :button, :content
  
  # Define static and dynamic values
  values(
    animation_duration: 300,
    enabled: true,
    # Dynamic values using procs (evaluated in component context)
    item_count: -> { @items.count },
    loading_state: proc { @loading ? "loading" : "idle" },
    api_url: -> { Rails.application.routes.url_helpers.api_items_path }
  )
  
  # Map component props as Stimulus values
  values_from_props :count, :title
  
  # Define static and dynamic CSS classes
  classes(
    base: "component",
    expanded: "block", 
    collapsed: "hidden",
    # Dynamic classes using procs
    loading: -> { @loading ? "opacity-50" : "" },
    size: proc { @items.count > 10 ? "large" : "small" }
  )
  
  # Dynamic actions and targets using procs
  # Each proc returns a single value (even if it's an array)
  actions -> { @loading ? [] : [:click, :submit] }
  targets -> { @expanded ? [:content, :toggle] : [:toggle] }
  
  # For multiple values, use multiple procs
  actions -> { @can_edit ? :edit : nil },
          -> { @can_delete ? :delete : nil },
          :cancel  # static value
  
  # Define outlets for connecting to other controllers
  outlets modal: "#modal-id"
end

# Disable Stimulus entirely
no_stimulus_controller
```

## Proc Behavior
Each proc returns a single value for its stimulus attribute. If a proc returns an array, that entire array is treated as one value, not multiple separate values. To provide multiple values for an attribute, use multiple procs or mix procs with static values.

```ruby
stimulus do
  # Single proc = single value (even if array)
  actions -> { @enabled ? [:click, :submit] : :disabled }
  
  # Multiple procs = multiple values
  actions -> { @can_edit ? :edit : nil },
          -> { @can_save ? :save : nil },
          :cancel
end
```

## Scoped Custom Events
Generate unique event names for component communication:

```ruby
# Define actions that respond to scoped events
stimulus do
  actions -> { [stimulus_scoped_event_on_window(:data_loaded), :handle_data_loaded] }
end

# Generate scoped event names
stimulus_scoped_event(:data_loaded)         # => "component-name:dataLoaded"
stimulus_scoped_event_on_window(:data_loaded) # => "component-name:dataLoaded@window"

# Available as both class and instance methods
MyComponent.stimulus_scoped_event(:click)
component_instance.stimulus_scoped_event(:click)
```

## Manual Stimulus Configuration
```ruby
def root_element_attributes
  {
    element_tag: :button,
    stimulus_controllers: ["custom", "analytics"],
    stimulus_actions: [[:click, :handleClick], [:custom_event, :handleCustom]],
    stimulus_targets: { container: true },
    stimulus_values: { endpoint: "/api/data", refresh_interval: 5000 },
    stimulus_classes: { active: "bg-blue-500", loading: "opacity-50" }
  }
end
```

## Template Helpers (ViewComponent)
```erb
<%= root_element do |component| %>
  <!-- Create targets -->
  <div <%= component.as_target(:content) %>>Content</div>
  
  <!-- Create actions -->
  <button <%= component.as_action(:click, :toggle) %>>Toggle</button>
  
  <!-- Use tag helper -->
  <%= component.tag :div, stimulus_target: :output, class: "mt-4" do %>
    Output here
  <% end %>
  
  <!-- Multiple targets/actions -->
  <input <%= component.as_targets(:input, :field) %> 
         <%= component.as_actions([:input, :validate], [:change, :save]) %>>
<% end %>
```

## Phlex Syntax
```ruby
def view_template
  root do |component|
    div(data: component.stimulus_target(:name).to_h) { "Content" }
    button(data: {**component.stimulus_actions(:click)}) { "Click" }
    component.tag(:span, stimulus_target: :output, class: "ml-4")
  end
end
```

## Controller Naming Convention
- `ButtonComponent` → `button-component`
- `Admin::UserCardComponent` → `admin--user-card-component`
- `MyApp::WidgetComponent` → `my-app--widget-component`

## Generated Data Attributes
- `data-controller="component-name"`
- `data-component-name-target="target"`
- `data-action="event->component-name#action"`
- `data-component-name-value-name-value="value"`
- `data-component-name-class-name-class="classes"`

## Class Management
```ruby
# Override root_element_classes for custom CSS classes
def root_element_classes
  base_classes = "btn"
  case @style
  when :primary
    "#{base_classes} btn-primary"
  when :secondary
    "#{base_classes} btn-secondary"
  end
end

# Classes are intelligently merged from multiple sources
```

## Component Caching
```ruby
class ExpensiveComponent < Vident::ViewComponent::Base
  include Vident::Caching
  
  with_cache_key :to_h  # Cache based on all attributes
  # or
  with_cache_key :id, :updated_at  # Cache based on specific attributes
end

# Usage:
<% cache component.cache_key do %>
  <%= render component %>
<% end %>
```

## Tailwind CSS Integration
Built-in support for Tailwind CSS class merging when `tailwind_merge` gem is available. Conflicting classes are automatically resolved.

## Testing
```ruby
# ViewComponent testing
render_inline(ButtonComponent.new(text: "Save", style: :primary))
assert_selector "[data-controller='button-component']"
assert_selector "[data-button-component-clicked-count-value='0']"

# Test Stimulus attributes
assert_selector "button[data-action='click->button-component#handleClick']"
```

## Post-Initialization Hooks

Components can perform actions after initialization:

```ruby
class MyComponent < Vident::ViewComponent::Base
  prop :data, Hash, default: -> { {} }

  def after_component_initialize
    @processed_data = process_data(@data)
  end
end
```

**Important**: If overriding Literal `after_initialize`, you **must** call `super` first to ensure Vident's initialization completes properly. The `after_component_initialize` hook is recommended as it doesn't require calling `super`.

## Key Methods
- `root_element` / `root` - Renders root element with all configured attributes
- `root_element_classes` - Override for custom CSS classes
- `root_element_attributes` - Override for element tag, HTML attributes, and Stimulus config
- `stimulus_action(event, method)` - Create action configuration
- `stimulus_controller(name)` - Add additional controller
- `after_component_initialize` - Post-initialization hook (recommended)

## Literal Types Reference
- Basic: `String`, `Integer`, `Symbol`, `Float`
- Boolean: `_Boolean`
- Nullable: `_Nilable(Type)`
- Collections: `_Array(Type)`, `_Hash(KeyType, ValueType)`
- Unions: `_Union(:small, :medium, :large)`
- Any: `_Any`

## Child Component Integration
```ruby
# Pass Stimulus actions between parent and child components
class ParentComponent < Vident::ViewComponent::Base
  renders_one :nested_button, ButtonComponent
  
  stimulus do
    actions :handleTrigger
  end
end

# In template:
<%= root_element do |parent| %>
  <% parent.with_nested_button(
    text: "Click me",
    stimulus_actions: [parent.stimulus_action(:click, :handleTrigger)]
  ) %>
<% end %>
```