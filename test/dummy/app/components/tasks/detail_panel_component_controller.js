import { Controller } from "@hotwired/stimulus"

// `taskValue` starts as JSON `null` because the Ruby DSL defaults it to
// `Vident::StimulusNull` (which serialises to the literal "null" string).
// `handleSelected` is wired to the card's scoped `selected` window event.
export default class extends Controller {
  static targets = ["body"]

  static values = {
    task: Object,
  }

  handleSelected(event) {
    this.taskValue = event.detail
    this.#render()
    this.element.classList.remove("translate-x-full")
  }

  close() {
    this.element.classList.add("translate-x-full")
  }

  #render() {
    const task = this.taskValue
    if (!task || !task.taskId) return
    this.bodyTarget.innerHTML = `
      <p><span class="font-medium">ID:</span> ${task.taskId}</p>
      <p><span class="font-medium">Title:</span> ${task.title}</p>
      <p><span class="font-medium">Status:</span> ${task.status}</p>
    `
  }
}
