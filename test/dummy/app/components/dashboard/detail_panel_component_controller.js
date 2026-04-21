import { Controller } from "@hotwired/stimulus"

// `releaseValue` starts as JSON `null` because the Ruby DSL defaults it to
// `Vident::StimulusNull` (which serialises to the literal "null" string).
// `handleSelected` is wired to the card's scoped `selected` window event.
export default class extends Controller {
  static targets = ["body"]

  static values = {
    release: Object,
  }

  handleSelected(event) {
    this.releaseValue = event.detail
    this.#render()
    this.element.classList.remove("translate-x-full")
  }

  close() {
    this.element.classList.add("translate-x-full")
  }

  #render() {
    const release = this.releaseValue
    if (!release || !release.releaseId) return
    this.bodyTarget.innerHTML = `
      <p><span class="font-medium">ID:</span> ${release.releaseId}</p>
      <p><span class="font-medium">Name:</span> ${release.name}</p>
      <p><span class="font-medium">Status:</span> ${release.status}</p>
    `
  }
}
