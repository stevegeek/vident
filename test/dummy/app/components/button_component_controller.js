// app/javascript/controllers/button_component_controller.js
// Can also be "side-car" in the same directory as the component, see the documentation for details
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { 
    clickedCount: Number, 
    loadingDuration: Number 
  }
  static classes = ["loading"]
  
  handleClick(event) {
    // Increment counter
    this.clickedCountValue++
    
    // Add loading state
    this.element.classList.add(this.loadingClass)
    this.element.disabled = true
    
    // Use the loading duration from the component
    setTimeout(() => {
      this.element.classList.remove(this.loadingClass)
      this.element.disabled = false
      
      // Update text to show count
      this.element.textContent = `${this.element.textContent} (${this.clickedCountValue})`
    }, this.loadingDurationValue)
  }
}