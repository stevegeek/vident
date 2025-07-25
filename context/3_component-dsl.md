# Vident Component DSL Reference

### Built-in Properties

Every Vident component has these properties:

```ruby
# HTML element tag (default: :div)
prop :element_tag, Symbol, default: :div

# Component DOM ID (auto-generated if not provided)
prop :id, _Nilable(String)

# Additional CSS classes
prop :classes, _Union(String, Array, NilClass)

# HTML attributes (set attributes on HTML root element. If you set `class` it will override `classes` prop & root_element_classes method).
prop :html_options, Hash, default: -> { {} }
```

## Component Methods

### Root Element Configuration

```ruby
class MyComponent < Vident::ViewComponent::Base
  private

  # Configure root element attributes
  def root_element_attributes
    {
      element_tag: :article,
      stimulus_controllers: ["my-controller"],
      html_options: {
        role: "article",
        "aria-label": @title
      }
    }
  end

  # Define CSS classes for root element
  def root_element_classes
    ["component", size_class, featured_class].compact
  end

  def size_class
    case @size
    when :small then "component--small"
    when :large then "component--large"
    else "component--medium"
    end
  end

  def featured_class
    "component--featured" if featured?
  end
end
```

### Lifecycle Hooks

```ruby
class MyComponent < Vident::ViewComponent::Base
  # Called after all properties are set
  def after_component_initialize
    @computed_value = expensive_computation(@data)
    validate_configuration!
  end

  private

  def validate_configuration!
    raise ArgumentError, "Invalid config" unless valid?
  end
end
```

### Stimulus DSL

The `stimulus` block provides a declarative way to configure Stimulus integration:

```ruby
class InteractiveComponent < Vident::ViewComponent::Base
  stimulus do
    # Define controller actions
    actions :click, :submit, :toggle
    actions [:mouseover, :highlight], [:mouseout, :unhighlight]
    
    # Dynamic actions with procs
    actions -> { admin? ? [:delete, :confirmDelete] : nil }
    
    # Define targets
    targets :input, :output, :button
    targets -> { expandable? ? :content : nil }
    
    # Define values
    values count: 0, enabled: true
    values api_url: -> { api_endpoint_path }
    
    # Map component props as values
    values_from_props :user_id, :session_token
    
    # Define CSS classes
    classes active: "bg-blue-500 text-white"
    classes loading: -> { "opacity-50 cursor-wait" }
    
    # Define outlets
    outlets modal: "modal-component"
    outlets -> { connected? ? { notifier: "notification-component" } : {} }
  end
end
```

Also possible via `root_element_attributes` method:

```ruby
def root_element_attributes
  {
    stimulus_controllers: ...
    stimulus_actions:...
    stimulus_values: ...
    stimulus_targets: ...
    stimulus_classes: ...
    stimulus_outlets: ...
  }
end
```

## Rendering

### ViewComponent

```ruby
# component.rb
class CardComponent < Vident::ViewComponent::Base
  prop :title, String
  prop :body, String
  
  renders_one :header
  renders_many :actions
end

# component.html.erb
<%= root_element do |component| %>
  <% if header? %>
    <div class="card-header">
      <%= header %>
    </div>
  <% end %>
  
  <div class="card-body">
    <h3><%= @title %></h3>
    <p><%= @body %></p>
  </div>
  
  <% if actions.any? %>
    <div class="card-actions">
      <% actions.each do |action| %>
        <%= action %>
      <% end %>
    </div>
  <% end %>
<% end %>
```

### Phlex

```ruby
class CardComponent < Vident::Phlex::HTML
  prop :title, String
  prop :body, String
  
  def view_template
    root_element do
      div(class: "card-header") { h3 { @title } }
      div(class: "card-body") { p { @body } }
    end
  end
end
```

## Stimulus Helpers

### In ERB Templates only

```erb
<%= root_element do |component| %>
  <!-- Create targets -->
  <div <%= component.as_target(:content) %>>
    Content
  </div>
  
  <!-- Create actions -->
  <button <%= component.as_action(:click, :save) %>>
    Save
  </button>
  
  <!-- Multiple attributes -->
  <input <%= component.as_targets(:field, :input) %>
         <%= component.as_actions([:input, :validate], [:blur, :save]) %>>
  
  <!-- Using tag helper -->
  <%= component.tag :div, 
    stimulus_target: :output,
    stimulus_action: [:click, :handleClick],
    class: "output-area" do %>
    Output content
  <% end %>
<% end %>
```

### Stimulus Attribute Methods

```ruby
# Generate specific attributes
component.stimulus_target(:fieldName)
# => { "data-#{controller}-target" => "fieldName" }

component.stimulus_action(:click, :methodName)
# => { "data-action" => "click->#{controller}#methodName" }

component.stimulus_value(:count, 5)
# => { "data-#{controller}-count-value" => "5" }

component.stimulus_class(:active, "highlighted")
# => { "data-#{controller}-active-class" => "highlighted" }

# Get controller name
component.stimulus_controller_name
# => "my-component"

# Scoped events
component.stimulus_scoped_event(:loaded)
# => "my-component:loaded"

component.stimulus_scoped_event_on_window(:resize)
# => "my-component:resize@window"
```

## Component Stimulus Integration / Composing Stimulus attributes and components

### Parent-Child Communication

```ruby
class ParentComponent < Vident::ViewComponent::Base
  renders_one :child, ChildComponent
  
  stimulus do
    actions :handleChildEvent
  end
end

# In template:
<%= root_element do |parent| %>
  <% parent.with_child(
    text: "Click me",
    stimulus_actions: [
      # Child triggers parent action
      parent.stimulus_action(:click, :handleChildEvent)
    ]
  ) %>
<% end %>
```

### Shared Behavior

```ruby
# Define a base component
class ApplicationComponent < Vident::ViewComponent::Base
  # Shared configuration
  include Turbo::FramesHelper
  
  private
  
  def current_user
    helpers.current_user
  end
  
  def root_element_classes
    ["component", theme_class]
  end
  
  def theme_class
    current_user&.dark_mode? ? "dark" : "light"
  end
end

# Inherit shared behavior
class MyComponent < ApplicationComponent
  # Component-specific code
end
```


## Class Management

### Class Merging

Vident intelligently merges classes from multiple sources:

```ruby
class StyledComponent < Vident::ViewComponent::Base
  prop :variant, Symbol, default: :primary
  
  private
  
  def root_element_classes
    ["btn", variant_classes, size_classes]
  end
  
  def variant_classes
    case @variant
    when :primary then "btn-primary bg-blue-500"
    when :secondary then "btn-secondary bg-gray-500"
    when :danger then "btn-danger bg-red-500"
    end
  end
end

# Usage:
render StyledComponent.new(
  variant: :primary,
  classes: "rounded-lg shadow-lg"
)
# Results in: "btn btn-primary bg-blue-500 rounded-lg shadow-lg"
```
