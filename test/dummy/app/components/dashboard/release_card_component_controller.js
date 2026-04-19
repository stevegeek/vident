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

  // event.params.kind comes from the button's stimulus_params (see the Ruby
  // side). Stimulus auto-reads `data-<controller>-<name>-param` attributes on
  // the action's element into event.params.<camelName>.
  apply(event) {
    const kind = event.params.kind  // "promote" | "cancel"
    this.#disable()
    this.dispatch(`${kind}d`, { detail: this.#payload(), target: window })
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
