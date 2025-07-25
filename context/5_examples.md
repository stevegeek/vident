# Examples

### 1. Interactive Form Component

A form with real-time validation and dynamic field visibility:

```ruby
# app/components/user_form_component.rb
class UserFormComponent < Vident::ViewComponent::Base
  prop :user_id, _Nilable(Integer)
  prop :show_advanced, _Boolean, default: false
  prop :api_validation_endpoint, String, default: "/api/validate"
  
  stimulus do
    actions [:submit, :handle_submit]
    
    targets :form
    
    values api_endpoint: -> { @api_validation_endpoint },
           show_advanced: -> { @show_advanced && @user_id.present? }
    
    values_from_props :user_id
    
    classes valid: "border-green-500",
            invalid: "border-red-500",
            loading: "opacity-50 cursor-wait"
  end
  
  private
  
  def root_element_classes
    ["max-w-2xl", "mx-auto", "p-6", "bg-white", "rounded-lg", "shadow"]
  end
end
```

```erb
<!-- app/components/user_form_component.html.erb -->
<%= root_element do |component| %>
  <%= form_with model: @user do |form| %>
 
    <div class="mb-4">
      <%= form.label :email, class: "block text-sm font-medium text-gray-700" %>
      <%= form.email_field :email, 
        class: "mt-1 block w-full rounded-md border-gray-300",
        data: {
            **component.stimulus_target(:email_field),
            **component.stimulus_action(:input, :validate_field) 
        } %>
    </div>
    
    <div <%= component.as_target(:errors) %> class="hidden text-red-600 text-sm mb-4">
      <!-- Validation errors inserted here -->
    </div>
    
    <div class="mb-4">
      <%= form.check_box :advanced_mode,
        **component.stimulus_action(:click, :toggle_advanced),
        class: "mr-2" %>
      <%= form.label :advanced_mode, "Show advanced options" %>
    </div>
    
    <%= component.tag(stimulus_targets: [:advanced_section]) do %> 
         class="<%= @show_advanced ? 'block' : 'hidden' %> p-4 bg-gray-50 rounded mb-4">
      <!-- Advanced fields -->
      <%= form.label :preferences, class: "block text-sm font-medium text-gray-700" %>
      <%= form.text_area :preferences, 
        rows: 4,
        class: "mt-1 block w-full rounded-md border-gray-300" %>
    <% end %>
    
    <%= form.submit "Save User", 
      data: {**component.stimulus_target(:submit_button)},
      class: "bg-blue-500 text-white px-4 py-2 rounded hover:bg-blue-600" %>
  <% end %>
<% end %>
```

```javascript
// app/components/user_form_component_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { 
    apiEndpoint: String, 
    showAdvanced: Boolean,
    userId: Number
  }
  static targets = ["form", "emailField", "advancedSection", "submitButton", "errors"]
  static classes = ["valid", "invalid", "loading"]
  
  connect() {
    this.toggleAdvancedSection()
  }
  
  async handleSubmit(event) {
    event.preventDefault()
    
    this.setLoading(true)
    this.hideErrors()
    
    // ...
  }
  
  async validateField(event) {
    const field = event.target
    const fieldName = field.name
    const value = field.value
    
    // Skip if empty
    if (!value) {
      this.clearFieldValidation(field)
      return
    }
    
    // ...
  }
  

  
  markFieldValid(field) {
    field.classList.remove(this.invalidClass)
    field.classList.add(this.validClass)
  }
  
  markFieldInvalid(field, error) {
    field.classList.remove(this.validClass)
    field.classList.add(this.invalidClass)
    
    if (error) {
      this.showErrors({ [field.name]: [error] })
    }
  }
  
  clearFieldValidation(field) {
    field.classList.remove(this.validClass, this.invalidClass)
  }
  
  showErrors(errors) {
    const errorMessages = Object.entries(errors)
      .map(([field, messages]) => `${field}: ${messages.join(', ')}`)
      .join('<br>')
    
    this.errorsTarget.innerHTML = errorMessages
    this.errorsTarget.classList.remove('hidden')
  }
  
  hideErrors() {
    this.errorsTarget.classList.add('hidden')
    this.errorsTarget.innerHTML = ''
  }
  
  setLoading(loading) {
    if (loading) {
      this.element.classList.add(this.loadingClass)
      this.submitButtonTarget.disabled = true
    } else {
      this.element.classList.remove(this.loadingClass)
      this.submitButtonTarget.disabled = false
    }
  }
}
```

### 2. Modal Component with Phlex

```ruby
# app/components/modal_component.rb
class Modal < PhlexComponent
  prop :initial_content, _Nilable(String)
  prop :content_href, _Nilable(String)
  prop :start_shown, _Boolean, default: false
  prop :close_on_overlay_click, _Boolean, default: false

  stimulus do
    targets :overlay, :modal
    actions -> { [stimulus_scoped_event_on_window(:open), :handle_open_event] },
            -> { [stimulus_scoped_event_on_window(:close), :handle_close_event] }
    values_from_props :close_on_overlay_click, :content_href
    values show_initial: -> { @start_shown }
  end

  def view_template
    root_element do
      # Modal content box
      div(
        id: "#{id}-content",
        class: "modal-box",
        data: {**stimulus_target(:modal)}
      ) do
        if @initial_content.present?
          plain(@initial_content)
        else
          render ::Decor::Spinner.new(html_options: {class: "mx-auto w-8 h-8"})
        end
      end

      # Modal backdrop - clicking outside closes if enabled
      form(
        method: "dialog",
        class: "modal-backdrop",
        data: {
          **stimulus_action(:click, :overlay_clicked),
          **stimulus_target(:overlay)
        }
      ) do
        button { "" }
      end
    end
  end

  private

  def root_element_attributes
    {
      element_tag: :dialog,
      html_options: {
        aria_describedby: "#{id}-content"
      }
    }
  end

  def root_element_classes
    "modal"
  end
end
```

```javascript
export default class extends Controller {
    static targets = ["overlay", "modal"];
    static values = {
        showInitial: {type: Boolean, default: false},
        contentHref: {type: String, default: null},
        closeOnOverlayClick: {type: Boolean, default: false}
    };

    connect() {
        this.modalVisible = false;
        this.closeOnOverlayClick = false;
        this.pendingCloseReason = null;
        // ...
    }
```