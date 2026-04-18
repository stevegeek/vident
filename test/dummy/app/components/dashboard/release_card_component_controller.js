import { Controller } from "@hotwired/stimulus"

// Scoped `selected` / `promoted` / `cancelled` window events are consumed by
// DetailPanel / Toast respectively. `setVisible(...)` is public so PageComponent
// can drive it through the outlet API.
export default class extends Controller {
  static targets = ["promoteButton", "cancelButton"]

  static values = {
    releaseId: Number,
    name: String,
    status: String,
  }

  select(event) {
    // Avoid firing when a button inside the card was the real click target.
    if (event.target.closest("button")) return
    this.dispatch("selected", {
      detail: this.#payload(),
      target: window,
    })
  }

  promote() {
    this.#disable()
    this.dispatch("promoted", { detail: this.#payload(), target: window })
  }

  cancel() {
    this.#disable()
    this.dispatch("cancelled", { detail: this.#payload(), target: window })
  }

  setVisible(show) {
    this.element.classList.toggle("hidden", !show)
  }

  #payload() {
    return {
      releaseId: this.releaseIdValue,
      name: this.nameValue,
      status: this.statusValue,
    }
  }

  #disable() {
    this.promoteButtonTarget.disabled = true
    this.cancelButtonTarget.disabled = true
  }
}
