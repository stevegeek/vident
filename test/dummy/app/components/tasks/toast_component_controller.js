import { Controller } from "@hotwired/stimulus"

// `messageValue` starts as JSON `null` (Ruby DSL uses `Vident::StimulusNull`)
// until the first `done`/`dismissed` card event fills it in.
export default class extends Controller {
  static targets = ["container", "message"]

  static values = {
    autoDismissMs: Number,
    message: Object,
  }

  handleDone(event) {
    this.#show(`${event.detail.title} marked done`)
  }

  handleDismissed(event) {
    this.#show(`${event.detail.title} dismissed`)
  }

  dismiss() {
    this.#hide()
  }

  #show(text) {
    this.messageTarget.textContent = text
    this.containerTarget.classList.remove("opacity-0", "translate-y-4")
    this.containerTarget.classList.add("opacity-100", "translate-y-0")
    clearTimeout(this.timer)
    this.timer = setTimeout(() => this.#hide(), this.autoDismissMsValue || 4000)
  }

  #hide() {
    this.containerTarget.classList.remove("opacity-100", "translate-y-0")
    this.containerTarget.classList.add("opacity-0", "translate-y-4")
  }
}
