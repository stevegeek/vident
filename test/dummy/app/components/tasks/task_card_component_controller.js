import { Controller } from "@hotwired/stimulus"

// Scoped `selected` / `done` / `dismissed` window events are consumed by
// DetailPanel / Toast respectively. `setVisible(...)` is public so PageComponent
// can drive it through the outlet API.
export default class extends Controller {
  static targets = ["doneButton", "dismissButton", "statusText", "titleText"]

  static classes = ["todo", "done", "wontDo"]

  static values = {
    taskId: Number,
    title: String,
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
    const kind = event.params.kind  // "done" | "dismissed"
    const newStatus = kind === "done" ? "done" : "wont_do"
    // Setting the value triggers `statusValueChanged` below, which handles
    // the visual swap. Disabling the buttons stays here so a fresh apply
    // can't re-fire while the controllers downstream are still reacting.
    this.statusValue = newStatus
    this.doneButtonTarget.disabled = true
    this.dismissButtonTarget.disabled = true
    this.dispatch(kind, { detail: this.#payload(), target: window })
  }

  setVisible(show) {
    this.element.classList.toggle("hidden", !show)
  }

  // Stimulus calls this whenever statusValue changes — including the initial
  // load. We use `oldStatus` to know which class set to remove; on the first
  // call it's an empty string, so the conditional skips the no-op remove.
  statusValueChanged(newStatus, oldStatus) {
    if (oldStatus && oldStatus !== newStatus) {
      this.#removeStatusClasses(oldStatus)
    }
    this.#addStatusClasses(newStatus)

    if (this.hasStatusTextTarget) {
      this.statusTextTarget.textContent = newStatus.replace("_", " ")
    }
    if (this.hasTitleTextTarget) {
      this.titleTextTarget.classList.toggle("line-through", newStatus === "wont_do")
      this.titleTextTarget.classList.toggle("text-gray-500", newStatus === "wont_do")
    }
  }

  #classesFor(status) {
    if (status === "done") return this.doneClasses
    if (status === "wont_do") return this.wontDoClasses
    return this.todoClasses
  }

  #removeStatusClasses(status) {
    this.element.classList.remove(...this.#classesFor(status))
  }

  #addStatusClasses(status) {
    this.element.classList.add(...this.#classesFor(status))
  }

  #payload() {
    return {
      taskId: this.taskIdValue,
      title: this.titleValue,
      status: this.statusValue,
    }
  }
}
