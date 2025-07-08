# Vident

A powerful Ruby gem for building interactive, type-safe components in Rails applications with seamless [Stimulus.js](https://stimulus.hotwired.dev/) integration. 

Vident supports both [ViewComponent](https://viewcomponent.org/) and [Phlex](https://www.phlex.fun/) rendering engines while providing a consistent API for creating 
reusable UI components powered by [Stimulus.js](https://stimulus.hotwired.dev/).

## Table of Contents

- [Introduction](#introduction)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Core Concepts](#core-concepts)
- [Component DSL](#component-dsl)
- [Stimulus Integration](#stimulus-integration)
- [Advanced Features](#advanced-features)
- [Testing](#testing)
- [Contributing](#contributing)

## Introduction

Vident is a collection of gems that enhance Rails view components with:

- **Type-safe properties** using the Literal gem
- **First-class [Stimulus.js](https://stimulus.hotwired.dev/) integration** for interactive behaviors
- **Support for both [ViewComponent](https://viewcomponent.org/) and [Phlex](https://www.phlex.fun/)** rendering engines
- **Intelligent CSS class management** with built-in Tailwind CSS merging
- **Component caching** for improved performance
- **Declarative DSL** for clean, maintainable component code

### Why Vident?

Stimulus.js is a powerful framework for adding interactivity to HTML, but managing the data attributes can be cumbersome,
and refactoring can be error-prone (as say controller names are repeated in many places).

Vident simplifies this by providing a declarative DSL for defining Stimulus controllers, actions, targets, and values
directly within your component classes so you don't need to manually craft data attributes in your templates.

Vident also ensures that your components are flexible: for example you can easily add to, or override configuration,
classes etc at the point of rendering.

Vident's goal is to make building UI components more maintainable, and remove some of the boilerplate code of Stimulus 
without being over-bearing or including too much magic.

## Installation

Add the core gem and your preferred rendering engine integration to your Gemfile:

```ruby
# Core gem (required)
gem "vident"

# Choose your rendering engine (at least one required)
gem "vident-view_component"  # For ViewComponent support
gem "vident-phlex"           # For Phlex support
```

Then run:

```bash
bundle install
```

## Quick Start

Here's a simple example of a Vident component using ViewComponent:

```ruby
# app/components/button_component.rb
class ButtonComponent < Vident::ViewComponent::Base
  # Define typed properties
  prop :text, String, default: "Click me"
  prop :url, _Nilable(String)
  prop :style, Symbol, in: [:primary, :secondary], default: :primary
  prop :clicked_count, Integer, default: 0
  
  # Configure Stimulus integration
  stimulus do
    actions [:click, :handle_click]
    # Static values
    values loading_duration: 1000
    # Map the clicked_count prop as a Stimulus value
    values_from_props :clicked_count
    # Dynamic values using procs (evaluated in component context)
    values item_count: -> { @items.count }
    values api_url: -> { Rails.application.routes.url_helpers.api_items_path }
    # Static and dynamic classes
    classes loading: "opacity-50 cursor-wait"
    classes size: -> { @items.count > 10 ? "large" : "small" }
  end

  def call
    root_element do |component|
      component.tag(:span, stimulus_target: :status) do
        @text
      end
    end
  end

  private

  def root_element_attributes
    {
      element_tag: @url ? :a : :button,
      html_options: { href: @url }.compact
    }
  end

  def element_classes
    base_classes = "btn"
    case @style
    when :primary
      "#{base_classes} btn-primary"
    when :secondary
      "#{base_classes} btn-secondary"
    end
  end
end
```


Add the corresponding Stimulus controller would be:

```javascript
// app/javascript/controllers/button_component_controller.js
// Can also be "side-car" in the same directory as the component, see the documentation for details
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { 
    clickedCount: Number, 
    loadingDuration: Number 
  }
  static classes = ["loading"]
  static targets = ["status"]
  
  handleClick(event) {
    // Increment counter
    this.clickedCountValue++
    
    // Store original text
    const originalText = this.statusTarget.textContent
    
    // Add loading state
    this.element.classList.add(this.loadingClass)
    this.element.disabled = true
    this.statusTarget.textContent = "Loading..."
    
    // Use the loading duration from the component
    setTimeout(() => {
      this.element.classList.remove(this.loadingClass)
      this.element.disabled = false
      
      // Update text to show count
      this.statusTarget.textContent = `${originalText} (${this.clickedCountValue})`
    }, this.loadingDurationValue)
  }
}
```

Use the component in your views:

```erb
<!-- Default clicked count of 0 -->
<%= render ButtonComponent.new(text: "Save", style: :primary) %>

<!-- Pre-set clicked count -->
<%= render ButtonComponent.new(text: "Submit", style: :primary, clicked_count: 5) %>

<!-- Link variant -->
<%= render ButtonComponent.new(text: "Cancel", url: "/home", style: :secondary) %>

<!-- Override things -->
<%= render ButtonComponent.new(text: "Cancel", url: "/home" classes: "bg-red-900", html_options: {role: "button"}) %>
```

The rendered HTML includes all Stimulus data attributes:

```html
<!-- First button with default count -->
<button class="bg-blue-500 hover:bg-blue-700 text-white" 
        data-controller="button-component" 
        data-action="click->button-component#handleClick"
        data-button-component-clicked-count-value="0"
        data-button-component-loading-duration-value="1000"
        data-button-component-loading-class="opacity-50 cursor-wait"
        id="button-component-123">
  <span data-button-component-target="status">Save</span>
</button>

<!-- Second button with pre-set count -->
<button class="bg-blue-500 hover:bg-blue-700 text-white" 
        data-controller="button-component" 
        data-action="click->button-component#handleClick"
        data-button-component-clicked-count-value="5"
        data-button-component-loading-duration-value="1000"
        data-button-component-loading-class="opacity-50 cursor-wait"
        id="button-component-456">
  <span data-button-component-target="status">Submit</span>
</button>
```

## Core Concepts

### Component Properties

Vident uses the Literal gem to provide type-safe component properties:

```ruby
class CardComponent < Vident::ViewComponent::Base
  # Basic property with type
  prop :title, String
  
  # Property with default value
  prop :subtitle, String, default: ""
  
  # Nullable property
  prop :image_url, _Nilable(String)
  
  # Property with validation
  prop :size, _Union(:small, :medium, :large), default: :medium
  
  # Boolean property (creates predicate method)
  prop :featured, _Boolean, default: false
end
```

### Built-in Properties

Every Vident component includes these properties:

- `element_tag` - The HTML tag for the root element (default: `:div`)
- `id` - The component's DOM ID (auto-generated if not provided)
- `classes` - Additional CSS classes
- `html_options` - Hash of HTML attributes

### Root Element Rendering

The `root_element` helper method renders your component's root element with all configured attributes:

```ruby
# In your component class
def element_classes
  ["card", featured? ? "card-featured" : nil]
end

private

def root_element_attributes
  {
    html_options: { role: "article", "aria-label": title }
  }
end
```

```erb
<%# In your template %>
<%= root_element do %>
  <h2><%= title %></h2>
  <p><%= subtitle %></p>
<% end %>
```

## Component DSL

### ViewComponent Integration

```ruby
class MyComponent < Vident::ViewComponent::Base
  # Component code
end

# Or with an application base class
class ApplicationComponent < Vident::ViewComponent::Base
  # Shared configuration
end

class MyComponent < ApplicationComponent
  # Component code
end
```

### Phlex Integration

```ruby
class MyComponent < Vident::Phlex::HTML
  def view_template
    root do
      h1 { "Hello from Phlex!" }
    end
  end
end
```

## Stimulus Integration

Vident provides comprehensive Stimulus.js integration to add interactivity to your components.

### Declarative Stimulus DSL

Use the `stimulus` block for clean, declarative configuration:

```ruby
class ToggleComponent < Vident::ViewComponent::Base
  prop :expanded, _Boolean, default: false
  
  stimulus do
    # Define actions the controller responds to
    actions :toggle, :expand, :collapse
    
    # Define targets for DOM element references
    targets :button, :content
    
    # Define static values
    values animation_duration: 300
    
    # Define dynamic values using procs (evaluated in component context)
    values item_count: -> { @items.count }
    values current_state: proc { expanded? ? "open" : "closed" }
    
    # Map values from component props
    values_from_props :expanded
    
    # Define CSS classes for different states
    classes expanded: "block",
            collapsed: "hidden",
            transitioning: "opacity-50"
  end
end
```

### Dynamic Values and Classes with Procs

The Stimulus DSL supports dynamic values and classes using procs or lambdas that are evaluated in the component instance context:

```ruby
class DynamicComponent < Vident::ViewComponent::Base
  prop :items, _Array(Hash), default: -> { [] }
  prop :loading, _Boolean, default: false
  prop :user, _Nilable(User)
  
  stimulus do
    # Mix static and dynamic values in a single call
    values(
      static_config: "always_same",
      item_count: -> { @items.count },
      loading_state: proc { @loading ? "loading" : "idle" },
      user_role: -> { @user&.role || "guest" },
      api_endpoint: -> { Rails.application.routes.url_helpers.api_items_path }
    )
    
    # Mix static and dynamic classes
    classes(
      base: "component-container",
      loading: -> { @loading ? "opacity-50 cursor-wait" : "" },
      size: proc { @items.count > 10 ? "large" : "small" },
      theme: -> { current_user&.dark_mode? ? "dark" : "light" }
    )
    
    # Dynamic actions and targets
    actions -> { @loading ? [] : [:click, :submit] }
    targets -> { @expanded ? [:content, :toggle] : [:toggle] }
  end
  
  private
  
  def current_user
    @current_user ||= User.current
  end
end
```

Procs have access to instance variables, component methods, and Rails helpers.

**Important**: Each proc returns a single value for its corresponding stimulus attribute. If a proc returns an array, that entire array is treated as a single value, not multiple separate values. To provide multiple values for an attribute, use multiple procs or mix procs with static values:

```ruby
stimulus do
  # Single proc returns a single value (even if it's an array)
  actions -> { @expanded ? [:click, :submit] : :click }
  
  # Multiple procs provide multiple values
  actions -> { @can_edit ? :edit : nil },
          -> { @can_delete ? :delete : nil },
          :cancel  # static value
  
  # This results in: [:edit, :delete, :cancel] (assuming both conditions are true)
end
```

### Scoped Custom Events

Vident provides helper methods to generate scoped event names for dispatching custom events that are unique to your component:

```ruby
class MyComponent < Vident::ViewComponent::Base
  stimulus do
    # Define an action that responds to a scoped event
    actions -> { [stimulus_scoped_event_on_window(:data_loaded), :handle_data_loaded] }
  end
  
  def handle_click
    # Dispatch a scoped event from JavaScript
    # This would generate: "my-component:dataLoaded"
    puts stimulus_scoped_event(:data_loaded)
    
    # For window events, this generates: "my-component:dataLoaded@window" 
    puts stimulus_scoped_event_on_window(:data_loaded)
  end
end

# Available as both class and instance methods:
MyComponent.stimulus_scoped_event(:data_loaded)      # => "my-component:dataLoaded"
MyComponent.new.stimulus_scoped_event(:data_loaded)  # => "my-component:dataLoaded"
```

This is useful for:
- Dispatching events from Stimulus controllers to communicate between components
- Creating unique event names that won't conflict with other components
- Setting up window-level event listeners with scoped names

### Manual Stimulus Configuration

For more control, configure Stimulus attributes manually:

```ruby
class CustomComponent < Vident::ViewComponent::Base
  private
  
  def root_element_attributes
    {
      element_tag: :article,
      stimulus_controllers: ["custom", "analytics"],
      stimulus_actions: [
        [:click, :handleClick],
        [:custom_event, :handleCustom]
      ],
      stimulus_values: {
        endpoint: "/api/data",
        refresh_interval: 5000
      },
      stimulus_targets: {
        container: true
      }
    }
  end
end
```

or you can use tag helpers to generate HTML with Stimulus attributes:

```erb
  <%= content_tag(:input, type: "text", class: "...", data: {**greeter.stimulus_target(:name)}) %>
  <%= content_tag(:button, @cta, class: "...", data: {**greeter.stimulus_action([:click, :greet])}) do %>
    <%= @cta %>
  <% end %>
  <%= content_tag(:span, class: "...", data: {**greeter.stimulus_target(:output)}) %>

  <%# OR use the vident tag helper  %>

  <%= greeter.tag(:input, stimulus_target: :name, type: "text", class: "...") %>
  <%= greeter.tag(:button, stimulus_action: [:click, :greet], class: "...") do %>
    <%= @cta %>
  <% end %>
  <%= greeter.tag(:span, stimulus_target: :output, class: "...") %>
```

or in your Phlex templates:

```ruby
root_element do |greeter|
  input(type: "text", data: {**greeter.stimulus_target(:name)}, class: %(...))
  trigger_or_default(greeter)
  greeter.tag(:span, stimulus_target: :output, class: "ml-4 #{greeter.class_list_for_stimulus_classes(:pre_click)}") do
    plain %( ... )
  end
end
```

or directly in the ViewComponent template (eg with ERB) using the `as_stimulus_*` helpers

```erb
  <%# HTML embellishment approach, most familiar to working with HTML in ERB, but is injecting directly into open HTML tags... %>
  <input type="text"
         <%= greeter.as_stimulus_targets(:name) %>
         class="...">
  <button <%= greeter.as_stimulus_actions([:click, :greet]) %>
          class="...">
    <%= @cta %>
  </button>
  <span <%= greeter.as_stimulus_targets(:output) %> class="..."></span>
```


### Stimulus Helpers in Templates

Vident provides helper methods for generating Stimulus attributes:

```erb
<%= render root do |component| %>
  <!-- Create a target -->
  <div <%= component.as_target(:content) %>>
    Content here
  </div>
  
  <!-- Create an action -->
  <button <%= component.as_action(:click, :toggle) %>>
    Toggle
  </button>
  
  <!-- Use the tag helper -->
  <%= component.tag :div, stimulus_target: :output, class: "mt-4" do %>
    Output here
  <% end %>
  
  <!-- Multiple targets/actions -->
  <input <%= component.as_targets(:input, :field) %> 
         <%= component.as_actions([:input, :validate], [:change, :save]) %>>
<% end %>
```

### Stimulus Outlets

Connect components via Stimulus outlets:




### Stimulus Controller Naming

Vident automatically generates Stimulus controller names based on your component class:

- `ButtonComponent` → `button-component`
- `Admin::UserCardComponent` → `admin--user-card-component`
- `MyApp::WidgetComponent` → `my-app--widget-component`

### Working with Child Components

Setting Stimulus configuration between parent and child components:

```ruby
class ParentComponent < Vident::ViewComponent::Base
  renders_one :a_nested_component, ButtonComponent
  
  stimulus do
    actions :handleTrigger
  end
end
```

```erb
<%= root_element do |parent| %>
  <% parent.with_a_nested_component(
    text: "Click me",
    stimulus_actions: [
      parent.stimulus_action(:click, :handleTrigger)
    ]
  ) %>
<% end %>
```

This creates a nested component that once clicked triggers the parent components `handleTrigger` action.

## Other Features

### Custom Element Tags

Change the root element tag dynamically:

```ruby
class LinkOrButtonComponent < Vident::ViewComponent::Base
  prop :url, _Nilable(String)
  
  private
  
  def root_element_attributes
    {
      element_tag: url? ? :a : :button,
      html_options: {
        href: url,
        type: url? ? nil : "button"
      }.compact
    }
  end
end
```

### Intelligent Class Management

Vident intelligently merges CSS classes from multiple sources:

```ruby
class StyledComponent < Vident::ViewComponent::Base
  prop :variant, Symbol, default: :default
  
  private
  
  # Classes on the root element
  def element_classes
    ["base-class", variant_class]
  end
  
  def variant_class
    case @variant
    when :primary then "text-blue-600 bg-blue-100"
    when :danger then "text-red-600 bg-red-100"
    else "text-gray-600 bg-gray-100"
    end
  end
end
```

Usage:
```erb
<!-- All classes are intelligently merged -->
<%= render StyledComponent.new(
  variant: :primary,
  classes: "rounded-lg shadow"
) %>
<!-- Result: class="base-class text-blue-600 bg-blue-100 rounded-lg shadow" -->
```

### Tailwind CSS Integration

Vident includes built-in support for Tailwind CSS class merging when the `tailwind_merge` gem is available:

```ruby
class TailwindComponent < Vident::ViewComponent::Base
  prop :size, Symbol, default: :medium
  
  private
  
  def element_classes
    # Conflicts with size_class will be resolved automatically
    "p-2 text-sm #{size_class}"
  end
  
  def size_class
    case @size
    when :small then "p-1 text-xs"
    when :large then "p-4 text-lg"
    else "p-2 text-base"
    end
  end
end
```

### Component Caching

Enable fragment caching for expensive components:

```ruby
class ExpensiveComponent < Vident::ViewComponent::Base
  include Vident::Caching
  
  with_cache_key :to_h  # Cache based on all attributes
  # or
  with_cache_key :id, :updated_at  # Cache based on specific attributes
end
```

```erb
<% cache component.cache_key do %>
  <%= render component %>
<% end %>
```


## Testing

Vident components work seamlessly with testing frameworks that support ViewComponent or Phlex.

## Development

### Running Tests

```bash
# Run all tests
bin/rails test
```

### Local Development

```bash
# Clone the repository
git clone https://github.com/stevegeek/vident.git
cd vident

# Install dependencies
bundle install

# Run the dummy app
cd test/dummy
rails s
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/my-new-feature`)
3. Write tests for your changes
4. Commit your changes (`git commit -am 'Add new feature'`)
5. Push to the branch (`git push origin feature/my-new-feature`)
6. Create a Pull Request

## License

The gem is available as open source under the terms of the [MIT License](LICENSE.txt).

## Credits

Vident is maintained by [Stephen Ierodiaconou](https://github.com/stevegeek).

Special thanks to the ViewComponent and Phlex communities for their excellent component frameworks that Vident builds upon.