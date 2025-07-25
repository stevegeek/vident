# Vident Stimulus.js Integration Guide

## Overview

Vident provides deep integration with Stimulus.js, automatically generating data attributes and providing a declarative DSL for defining controller behavior. This eliminates boilerplate and reduces errors when connecting server-side components to client-side controllers.

## Controller Naming Convention

Vident automatically generates Stimulus controller names from Ruby class names:

```ruby
ButtonComponent           # => data-controller="button-component"
Admin::UserCardComponent  # => data-controller="admin--user-card-component" 
MyApp::WidgetComponent   # => data-controller="my-app--widget-component"
```

## Stimulus DSL

### Actions

Actions map DOM events to controller methods. When defined in the stimulus block they apply to the component's root element:

```ruby
stimulus do
  # Single action
  actions :toggle
  # => data-action="click->toggle-component#toggle"
  
  # Multiple actions
  actions :save, :cancel, :reset
  
  # Action with specific event
  actions [:submit, :handleSubmit], [:keydown, :handleKeyboard]
  # => data-action="submit->component#handleSubmit keydown->component#handleKeyboard"
  
  # Dynamic actions using procs
  actions -> { can_edit? ? :edit : nil },
          -> { can_delete? ? [:click, :confirmDelete] : nil }
  
  # Scoped events
  actions -> { [stimulus_scoped_event(:custom), :handleCustom] }
  # => data-action="component:custom->component#handleCustom"
  
  # Window events
  actions -> { [stimulus_scoped_event_on_window(:resize), :handleResize] }
  # => data-action="component:resize@window->component#handleResize"
end
```

### Targets

Targets provide references to DOM elements, when defined in the stimulus block they apply to the component's root element:

```ruby
stimulus do
  # Static targets
  targets :input, :output, :button
  # => data-[controller]-target="input", etc.
  
  # Dynamic targets
  targets -> { expandable? ? [:content, :toggle] : :toggle }
  
  # Conditional targets
  targets :base,
          -> { advanced_mode? ? :advancedPanel : nil }
end
```

### Values

Values pass data from Ruby to JavaScript:

```ruby
stimulus do
  # Static values
  values count: 0, enabled: true, name: "Default"
  # => data-[controller]-count-value="0"
  # => data-[controller]-enabled-value="true"
  # => data-[controller]-name-value="Default"
  
  # Dynamic values using procs
  values item_count: -> { @items.count },
         api_url: -> { Rails.application.routes.url_helpers.api_items_path },
         user_name: -> { current_user&.name || "Guest" }
  
  # Map component properties as values
  values_from_props :title, :description, :user_id
  
  # Mixed static and dynamic
  values static_config: "production",
         dynamic_count: -> { calculate_count },
         feature_flag: -> { feature_enabled?(:new_ui) }
end
```

### Classes

Stimulus classes:

```ruby
stimulus do
  # Static class mappings
  classes active: "bg-blue-500 text-white",
          inactive: "bg-gray-200 text-gray-600",
          loading: "opacity-50 cursor-wait"
  # => data-[controller]-active-class="bg-blue-500 text-white"
  
  # Dynamic classes
  classes theme: -> { dark_mode? ? "dark-theme" : "light-theme" },
          size: -> { "size-#{@size}" }
  
  # Conditional classes
  classes base: "component",
          premium: -> { user.premium? ? "component-premium" : nil }
end
```

### Outlets

Connect to other Stimulus controllers:

```ruby
stimulus do
  # Static outlets
  outlets modal: "modal-component",
          notification: "notification-component"
  # => data-[controller]-modal-outlet="modal-component"
  
  # Dynamic outlets
  outlets -> { 
    connected? ? { socket: "websocket-component" } : {}
  }
  
  # Multiple outlets of same type
  outlets tabs: ["tab-component", "tab-component", "tab-component"]
end
```

## Generated HTML Examples

### Basic Component

```ruby
class ToggleComponent < Vident::ViewComponent::Base
  prop :expanded, _Boolean, default: false
  
  stimulus do
    actions :toggle
    values_from_props :expanded
    classes expanded: "block", collapsed: "hidden"
  end
   
  def call
    root_element do
      content_tag :div, data: {**stimulus_target(:content)} do
        # ...
      end
    end
  end
end
```

Generates:

```html
<div data-controller="toggle-component"
     data-action="click->toggle-component#toggle"
     data-toggle-component-expanded-value="false"
     data-toggle-component-expanded-class="block"
     data-toggle-component-collapsed-class="hidden"
     id="toggle-component-123">
  <div data-toggle-component-target="content">
    <!-- Content -->
  </div>
</div>
```

## JavaScript Controller Implementation

### Basic Controller

```javascript
// app/javascript/controllers/toggle_component_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { expanded: Boolean }
  static targets = ["content"]
  static classes = ["expanded", "collapsed"]
  
  connect() {
    this.updateClasses()
  }
  
  toggle() {
    this.expandedValue = !this.expandedValue
  }
  
  expandedValueChanged() {
    this.updateClasses()
  }
  
  updateClasses() {
    if (this.expandedValue) {
      this.contentTarget.classList.add(this.expandedClass)
      this.contentTarget.classList.remove(this.collapsedClass)
    } else {
      this.contentTarget.classList.add(this.collapsedClass)
      this.contentTarget.classList.remove(this.expandedClass)
    }
  }
}
```


## Template Helpers

### Using root_element

```erb
<%= root_element do |component| %>
  <!-- Automatic target setup -->
  <div <%= component.as_target(:content) %>>
    Content
  </div>
  
  <!-- Action with custom selector -->
  <button <%= component.as_action(:click, :save, ".save-btn") %>>
    Save
  </button>
  
  <!-- Multiple attributes -->
  <form <%= component.as_target(:filterForm) %>
        <%= component.as_action(:submit, :filterData) %>>
    <!-- Form fields -->
  </form>
<% end %>
```

### Tag Helper

```erb
<%= root_element do |component| %>
  <%= component.tag :div, 
    stimulus_target: :output,
    stimulus_action: [:mouseover, :highlight],
    class: "output-panel" do %>
    <!-- Content -->
  <% end %>
  
  <!-- Multiple targets -->
  <%= component.tag :input,
    stimulus_targets: [:field, :searchInput],
    stimulus_action: [[:input, :search], [:blur, :validate]],
    type: "text",
    class: "form-input" %>
<% end %>
```

## Custom Events

### Dispatching Events

```ruby
class NotificationComponent < Vident::ViewComponent::Base
  stimulus do
    # Listen for custom events
    actions -> { 
      [
        [stimulus_scoped_event(:show), :displayNotification],
        [stimulus_scoped_event(:hide), :hideNotification],
        [stimulus_scoped_event_on_window(:broadcast), :handleBroadcast]
      ]
    }
  end
  
  def notification_event_name
    stimulus_scoped_event(:show) # => "notification-component:show"
  end
end
```

JavaScript:

```javascript
// Dispatch custom event
this.dispatch("show", { detail: { message: "Hello" } })
// Dispatches: "notification-component:show"

// Dispatch on window
this.dispatch("broadcast", { target: window })
// Dispatches: "notification-component:broadcast" on window
```

## Sidecar Controllers

Vident supports placing Stimulus controllers alongside components:

```
app/components/
├── button_component.rb
├── button_component.html.erb
└── button_component_controller.js
```

### Configuration for Asset Pipeline

```ruby
# config/importmap.rb
components_directories = [Rails.root.join("app/components")]
components_directories.each do |components_path|
  prefix = components_path.basename.to_s
  components_path.glob("**/*_controller.js").each do |controller|
    name = controller.relative_path_from(components_path).to_s.remove(/\.js$/)
    pin "#{prefix}/#{name}", to: name
  end
end

# config/application.rb
config.importmap.cache_sweepers.append(Rails.root.join("app/components"))
config.assets.paths.append("app/components")

# app/assets/config/manifest.js
//= link_tree ../../components .js
```

## Performance Considerations

### Memoization

Stimulus attributes are memoized for performance:

```ruby
class OptimizedComponent < Vident::ViewComponent::Base
  # Attributes computed once per render
  def stimulus_attributes
    @stimulus_attributes ||= build_stimulus_attributes
  end
  
  private
  
  def build_stimulus_attributes
    # Complex computation happens once
    super.merge(custom_attributes)
  end
end
```

### Conditional Rendering

Avoid unnecessary Stimulus initialization:

```ruby
stimulus do
  # Only add controller if interactive
  controllers -> { interactive? ? stimulus_controller_name : nil }
  
  # Conditional features
  actions -> { editable? ? [:click, :edit] : nil }
  values -> { trackable? ? { userId: current_user.id } : {} }
end
```

## Best Practices

1. **Use Semantic Action Names**: Name actions based on what they do, not the event
   ```ruby
   # Good
   actions [:click, :saveForm], [:submit, :processData]
   
   # Avoid
   actions [:click, :handleClick], [:submit, :onSubmit]
   ```

2. **Leverage Dynamic Values**: Use procs for values that might change
   ```ruby
   values count: -> { items.count },  # Updates with items
          static: 42                  # Never changes
   ```

3. **Organize Complex Controllers**: Split large controllers into mixins
   ```javascript
   import { Controller } from "@hotwired/stimulus"
   import { Sortable } from "./mixins/sortable"
   import { Filterable } from "./mixins/filterable"
   
   export default class extends Controller {
     static targets = ["table"]
     
     connect() {
       this.initializeSortable()
       this.initializeFilterable()
     }
   }
   
   Object.assign(Controller.prototype, Sortable, Filterable)
   ```

4. **Type-Safe Value Access**: Define TypeScript interfaces for values
   ```typescript
   interface DataTableValues {
     apiUrl: string
     totalItems: number
     refreshInterval: number
   }
   
   export default class extends Controller<HTMLElement, DataTableValues> {
     // Type-safe value access
   }
   ```