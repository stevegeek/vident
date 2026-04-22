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
bin/rails generate vident:install
```

The `vident:install` generator writes `config/initializers/vident.rb`, wires per-request ID seeding into `ApplicationController`, and (if you use Claude Code) drops a Vident skill into `.claude/skills/vident/SKILL.md` so the model has first-party guidance on the gem's conventions. See [Element IDs and request-scoped seeding](#element-ids-and-request-scoped-seeding) for the initializer rationale, and [Claude Code skill](#claude-code-skill) for the skill.

## Quick Start

Here's a simple example of a Vident component using ViewComponent:

```ruby
# app/components/button_component.rb
class ButtonComponent < Vident::ViewComponent::Base
  # Define typed properties
  prop :text, String, default: "Click me"
  prop :url, _Nilable(String)
  prop :style, _Union(:primary, :secondary), default: :primary
  prop :clicked_count, Integer, default: 0
  
  # Configure Stimulus integration
  stimulus do
    # Fluent action DSL: reads left-to-right as "the handle_click method fires on the click event".
    action(:handle_click).on(:click)
    # Kwargs shorthand — same result, pick whichever reads better:
    action :handle_submit, on: :submit, modifier: [:prevent, :stop]
    # Proc for conditional / cross-component wiring, evaluated in the instance at render time.
    action(-> { [stimulus_scoped_event(:my_custom_event), :handle_this] if should_handle_this? })

    # Map the clicked_count prop as a Stimulus value
    values_from_props :clicked_count
    # Dynamic values using procs (evaluated in component context)
    values item_count: -> { @items.count },
           api_url: -> { Rails.application.routes.url_helpers.api_items_path },
           loading_duration: 1000 # or set static values
    # Static and dynamic classes
    classes loading: "opacity-50 cursor-wait",
            size: -> { @items.count > 10 ? "large" : "small" }
  end

  def call
    root_element do |component|
      # Wire up targets etc
      component.child_element(:span, stimulus_target: :status) do
        @text
      end
    end
  end

  private

  # Configure your components root HTML element
  def root_element_attributes
    {
      element_tag: @url ? :a : :button,
      html_options: { href: @url }.compact
    }
  end

  # optionally add logic to determine initial classes
  def root_element_classes
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
<%= render ButtonComponent.new(text: "Cancel", url: "/home", classes: "bg-red-900", html_options: {role: "button"}) %>
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
  
  # Boolean property (pass `predicate: :public` to also generate a `?` method)
  prop :featured, _Boolean, default: false
end
```

### Post-Initialization Hooks

Vident provides a hook for performing actions after component initialization:

```ruby
class MyComponent < Vident::ViewComponent::Base
  prop :data, Hash, default: -> { {} }
  
  def after_component_initialize
    @processed_data = process_data(@data)
  end
  
  private
  
  def process_data(data)
    # Your initialization logic here
    data.transform_values(&:upcase)
  end
end
```

**Important**: If you decide to override Literal's `after_initialize`, you **must** call `super` first to ensure Vident's initialization completes properly. Alternatively, use `after_component_initialize` which doesn't require calling `super`.

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
def root_element_classes
  ["card", @featured ? "card-featured" : nil]
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

    # Action parameters (element-scoped; readable as event.params.* in JS)
    params item_id: -> { @item.id }, kind: "inline"
  end
end
```

**Action modifiers — fluent DSL.** Singular `action(...)` returns a builder you chain with event, modifier, keyboard, and window setters. Kwargs shorthand is equivalent:

```ruby
stimulus do
  action(:submit).on(:click).modifier(:once, :prevent)          # click:once:prevent->implied#submit
  action(:on_key).on(:keydown).keyboard("ctrl+a")               # keydown.ctrl+a->implied#onKey
  action(:on_resize).on(:resize).window                         # resize@window->implied#onResize

  # kwargs shorthand — same result:
  action :submit,     on: :click,   modifier: [:once, :prevent]
  action :on_key,     on: :keydown, keyboard: "ctrl+a"
  action :on_resize,  on: :resize,  window: true
  action :save,       on: :click,   call_method: :handle_save

  # conditional inclusion via `.when` / `when:`:
  action(:delete).when { admin? }
end
```

Chain methods: `.on`, `.call_method`, `.modifier`, `.keyboard`, `.window`, `.on_controller`, `.when`. Recognised kwargs: `on:`, `call_method:`, `modifier:` (Symbol or Array), `keyboard:`, `window:`, `on_controller:`, `when:`. Unknown kwargs or modifier symbols raise `ArgumentError`.

**Controller aliases.** Declare a short alias with `controller "path", as: :sym`, then reference it from action entries via the fluent `.on_controller(:sym)` or the `on_controller: :sym` kwarg:

```ruby
stimulus do
  controller "admin/users", as: :admin

  action(:save).on(:click).on_controller(:admin)     # click->admin--users#save
  action :save, on: :click, on_controller: :admin    # same, kwargs form
end
```

Unknown aliases raise `Vident::DeclarationError` at render time.

**Legacy Hash form.** Still accepted for compat — `actions({event: :click, method: :submit, options: [:once, :prevent]})` parses the same way. The Hash descriptor is folded directly into `Vident::Stimulus::Action` — pass a Hash and it is parsed in place. Accepted keys: `method:`, `event:`, `controller:`, `options:`, `keyboard:`, `window:`.

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

Procs have access to instance variables and component methods. They run at render time (Phlex `before_template` / ViewComponent `before_render`), so they can reach the view context:

- **Phlex**: `helpers` is deprecated in phlex-rails. Opt in per Rails helper by including the matching adapter — e.g. `include Phlex::Rails::Helpers::NumberWithPrecision` — and call the helper bare (`number_with_precision(@amount, precision: 2)`) inside the proc. Vident ships a `phlex_helpers :number_with_precision, :t, :l` class macro on `Vident::Phlex::HTML` that does the right include for each name. See [phlex.fun/rails/helpers](https://www.phlex.fun/rails/helpers) for the full list of adapters.
- **ViewComponent**: call `helpers.<method>` or `view_context.<method>` directly.

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

**Nil values.** Returning `nil` from a value proc (or setting a static `nil`) omits the data attribute entirely, so Stimulus uses its per-type default. Don't rely on `nil` becoming empty-string — that silently reads as `true` for Boolean values. If you genuinely need to emit a JS `null` (only meaningful for Object/Array-typed Stimulus values), return the `Vident::StimulusNull` sentinel, which serializes to the literal string `"null"` for JSON.parse.

```ruby
values current_user_id: -> { @user&.id },          # nil → attribute omitted
       config: -> { @user ? @config : Vident::StimulusNull }  # nil object → JSON null
```

### Action Parameters

Stimulus action parameters — `data-<controller>-<name>-param="value"` — are read inside an action handler as `event.params.<name>` (auto-typecast to Number / String / Object / Boolean). Params are **element-scoped**: every action attached to the same element sees the same params.

Vident mirrors the `values` entry points:

```ruby
# In the DSL (component root element)
stimulus do
  actions [:click, :promote]
  params release_id: -> { @release_id }, kind: "promote"
end

# As a prop at render time
render MyComponent.new(stimulus_params: { release_id: 42 })

# Cross-controller (Array form) — both as a prop and in the DSL
stimulus_params: [
  [:release_id, 42],                # implied-release-id-param="42"
  ["other/ctrl", :scope, "full"],   # other--ctrl-scope-param="full"
]

# On a child element (co-located with the action it informs)
card.child_element(:button,
  stimulus_action: [:click, :promote],
  stimulus_params: { release_id: @release_id })
```

Inline helpers: `as_stimulus_param(:name, value)` / `as_stimulus_params({name: value, ...})`.

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
    
    # For window events, this generates: :"my-component:dataLoaded@window" 
    puts stimulus_scoped_event_on_window(:data_loaded)
  end
end

# Available as both class and instance methods:
MyComponent.stimulus_scoped_event(:data_loaded)      # => :"my-component:dataLoaded"
MyComponent.new.stimulus_scoped_event(:data_loaded)  # => :"my-component:dataLoaded"
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

All stimulus props accept Symbol paths as well as Strings (e.g. `stimulus_controllers: [:custom, :"admin/users"]`). `stimulus_values:` and `stimulus_classes:` additionally accept Array entries (for cross-controller: `[["admin/users", :name, "value"]]`) and pre-built `Vident::Stimulus::Value` / `Vident::Stimulus::ClassMap` instances, so you can compose attribute sets outside the component and pass them in.

or you can use tag helpers to generate HTML with Stimulus attributes:

```erb
  <%= content_tag(:input, type: "text", class: "...", data: {**greeter.stimulus_target(:name)}) %>
  <%= content_tag(:button, @cta, class: "...", data: {**greeter.stimulus_action([:click, :greet])}) do %>
    <%= @cta %>
  <% end %>
  <%= content_tag(:span, class: "...", data: {**greeter.stimulus_target(:output)}) %>

  <%# OR use the vident child_element helper  %>

  <%= greeter.child_element(:input, stimulus_target: :name, type: "text", class: "...") %>
  <%= greeter.child_element(:button, stimulus_action: [:click, :greet], class: "...") do %>
    <%= @cta %>
  <% end %>
  <%= greeter.child_element(:span, stimulus_target: :output, class: "...") %>
```

or in your Phlex templates:

```ruby
root_element do |greeter|
  input(type: "text", data: {**greeter.stimulus_target(:name)}, class: %(...))
  trigger_or_default(greeter)
  greeter.child_element(:span, stimulus_target: :output, class: "ml-4 #{greeter.class_list_for_stimulus_classes(:pre_click)}") do
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

Inline helpers emit pre-built `data-*` fragments you can drop into any tag. Both singular and plural forms exist; pass one or many arguments accordingly.

```erb
<%= render root do |component| %>
  <div <%= component.as_stimulus_target(:content) %>>
    Content here
  </div>

  <button <%= component.as_stimulus_action(:click, :toggle) %>>Toggle</button>

  <input <%= component.as_stimulus_targets(:input, :field) %>
         <%= component.as_stimulus_actions([:input, :validate], [:change, :save]) %>>

  <%# Or build a whole element with the child_element helper: %>
  <%= component.child_element(:div, stimulus_target: :output, class: "mt-4") do %>
    Output here
  <% end %>
<% end %>
```

Parallel helpers exist for every attribute kind: `as_stimulus_controller(s)`, `as_stimulus_value(s)`, `as_stimulus_class(es)`, `as_stimulus_outlet(s)`.

### Stimulus Outlets

[Stimulus outlets](https://stimulus.hotwired.dev/reference/outlets) let one controller hold references to other controllers matched by a CSS selector. Vident has a few forms for declaring them.

**On the component's root element** — via the DSL:

```ruby
class DashboardComponent < Vident::ViewComponent::Base
  stimulus do
    # kwarg form: outlet name is the implied controller's identifier
    outlets modal: ".modal", user_status: ".online-user"

    # positional-hash form: required when the outlet identifier contains "--"
    # (e.g. cross-namespace controllers) because Ruby kwarg keys can't have dashes
    outlets({"admin--users" => ".admin-users"})
  end
end
```

Or via the `stimulus_outlets:` prop / `root_element_attributes`:

```ruby
stimulus_outlets: [
  [:modal, ".modal"],                     # [name, selector] on implied controller
  ["admin/users", :row, ".user-row"],     # [controller_path, name, selector] for cross-controller
  :user_status,                           # single symbol → auto-selector (see below)
  other_component                         # component instance → reuses its stimulus_identifier + id
]
```

**Auto-generated selectors.** Pass just a name (symbol or string) and the selector becomes `[data-controller~=<name>]`. Pass a component instance and the selector additionally scopes to the component's id (`#<id> [data-controller~=...]`), which is what lets you target a specific instance rather than every matching controller on the page.

**Self-registration via `stimulus_outlet_host`.** A built-in prop on every Vident component. When set to another component, the child registers itself as an outlet on that host at initialization — the host doesn't need to know about the child in its DSL:

```ruby
render DashboardComponent.new do |dashboard|
  render ModalComponent.new(stimulus_outlet_host: dashboard)
end
```

The modal now appears on the dashboard's root element as `data-dashboard-component-modal-component-outlet="#<modal-id>"` without the dashboard declaring it upfront.

**On child elements** — `child_element` accepts `stimulus_outlet:` (singular) and `stimulus_outlets:` (plural / Enumerable) exactly like the target/action kwargs, so a nested `<div>` can carry its own outlet declarations.


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

This creates a nested component that once clicked triggers the parent components `handleTrigger` action. The same pattern works for cross-controller `stimulus_values:`, `stimulus_classes:`, and `stimulus_outlets:` — build the entries with the parent's helpers (`parent.stimulus_value(...)`, etc.) and pass them down.

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
  def root_element_classes
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
  
  def root_element_classes
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

### Element IDs and request-scoped seeding

Every Vident component generates an element `id` at construction time (e.g. `button-component-abc123-0`). The IDs are produced by a deterministic sequence so the same render produces the same markup — which is what lets HTTP `ETag` caching return `304 Not Modified` for unchanged pages.

Because the IDs are deterministic, **the sequence has to be keyed on something that identifies the logical content of the request**. If two unrelated renders share the same seed, the same sequence indices produce the same IDs, and Ajax-inserted fragments can collide with IDs already on the page.

The `vident:install` generator wires this up for you. It writes `config/initializers/vident.rb`:

```ruby
# config/initializers/vident.rb
Vident::StableId.strategy = if Rails.env.test?
  Vident::StableId::RANDOM_FALLBACK
else
  Vident::StableId::STRICT
end
```

and patches `ApplicationController`:

```ruby
class ApplicationController < ActionController::Base
  before_action do
    Vident::StableId.set_current_sequence_generator(seed: request.fullpath)
  end
  after_action do
    Vident::StableId.clear_current_sequence_generator
  end
end
```

**Why `request.fullpath`?** It includes the query string, so `/items/1?page=2` and `/items/1?page=3` get different seeds and different IDs — which is what you want, because they are different pages from a caching perspective. Requests to the same fullpath get identical IDs, so `ETag` matches work unchanged.

#### Strategies

- `Vident::StableId::STRICT` (production/development default). Raises `Vident::StableId::GeneratorNotSetError` if a component renders on a thread that has no generator set. Use this in any environment where missing the `before_action` is a bug — the loud failure tells you immediately.
- `Vident::StableId::RANDOM_FALLBACK` (test default). Emits a random hex id when no generator is set. Tests, ViewComponent previews, and ad-hoc renders work without any extra wiring. You can still call `set_current_sequence_generator(seed:)` when you want to assert on deterministic IDs.

You can point `strategy` at any callable of your own, e.g. to log every generation or route through a different generator entirely.

#### Rendering outside a request

Mailers, jobs, previews, and scripts run outside the controller callback cycle, so there's no `before_action` to seed the generator. Under `STRICT` they will raise. Two options:

1. **Wrap the render in a scoped generator:**
   ```ruby
   Vident::StableId.with_sequence_generator(seed: "daily-digest-#{Date.today}") do
     render_component(DigestComponent.new(...))
   end
   ```
   The block sets the generator, yields, and restores whatever was on the thread before (including `nil`) in an `ensure`.
2. **Run in a context where `RANDOM_FALLBACK` is fine.** If you don't care about id stability for that particular render (no caching, no snapshot comparison), either swap the strategy for that block or just accept random IDs.

#### The collision bug in earlier versions

Before 1.0.0 `set_current_sequence_generator` hard-coded the seed to `42`, so every request that called it got the same deterministic sequence. When two independent renders shipped in one browser session — e.g. a server-rendered page and an Ajax fragment loaded into it — both started from index 0 and produced colliding `id` attributes. This surfaced as duplicate IDs in the DOM, broken `label[for=...]` associations, and Stimulus controllers attaching to the wrong element. Upgrading and running `bin/rails generate vident:install` seeds from `request.fullpath` instead, so each render gets its own sequence space.

### Claude Code skill

Vident ships a [Claude Code](https://docs.claude.com/claude-code) skill at `skills/vident/SKILL.md` that teaches the model the gem's conventions: the `stimulus do` DSL, `child_element`, outlets (including `stimulus_outlet_host` self-registration), the `nil` / `Vident::StimulusNull` value rules, the per-request StableId setup, and the Ruby↔JS dispatch handshake. It covers the foot-guns ahead of time so the model doesn't repeat them.

`bin/rails generate vident:install` copies the file into `.claude/skills/vident/SKILL.md` of the host app (skipped if already present). Claude Code picks it up automatically via skill discovery; no further wiring needed. If you want to update the skill later, delete the file and re-run the generator.


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