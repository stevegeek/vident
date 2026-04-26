import { Controller } from "@hotwired/stimulus"

// `this.dispatch("filterChanged", { target: window, ... })` produces the event
// name `tasks--filter-bar-component:filterChanged` (identifier-prefixed by
// default). Paired with `target: window` it matches the `@window`-suffixed
// action string that Vident's `stimulus_scoped_event_on_window(:filter_changed)`
// expands to on the Ruby side of PageComponent.
export default class extends Controller {
  static targets = ["search", "count"]

  static values = {
    activeFilter: String,
  }

  filterSelect(event) {
    this.activeFilterValue = event.target.value
    this.#dispatchFilterChanged()
  }

  searchInput() {
    // Read through the declared target rather than event.target — keeps the
    // handler decoupled from where the event fired and exercises Stimulus's
    // target API.
    this.query = this.searchTarget.value
    this.#dispatchFilterChanged()
  }

  handleFilterApplied(event) {
    const { count } = event.detail ?? {}
    if (this.hasCountTarget && typeof count === "number") {
      this.countTarget.textContent = count
    }
  }

  #dispatchFilterChanged() {
    this.dispatch("filterChanged", {
      detail: { filter: this.activeFilterValue, query: this.query ?? "" },
      target: window,
    })
  }
}
