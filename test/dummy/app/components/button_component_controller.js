// app/javascript/controllers/button_component_controller.js
// Can also be "side-car" in the same directory as the component, see the documentation for details
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { 
    clickedCount: Number, 
    loadingDuration: Number,
    itemCount: Number,
    apiUrl: String
  }
  static classes = ["loading", "size"]
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