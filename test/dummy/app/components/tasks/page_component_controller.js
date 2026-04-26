import { Controller } from "@hotwired/stimulus"

// Host for task-card outlets. Cards self-register via `stimulus_outlet_host:`
// on the Ruby side, so this controller just uses the outlet name declared in
// `static outlets` — no manual mapping.
export default class extends Controller {
  static values = {
    activeFilter: String,
    count: Number,
  }

  static outlets = ["tasks--task-card-component"]

  handleFilterChanged(event) {
    const { filter, query } = event.detail ?? {}
    if (filter !== undefined) this.activeFilterValue = filter
    this.lastQuery = query ?? ""
    this.#applyFilter(this.lastQuery)
  }

  // Gotcha: do not iterate the plural outlet getter inside
  // `tasksTaskCardComponentOutletConnected` — Stimulus connects the card
  // controllers one at a time, and the getter warns for each selector match
  // that hasn't had its controller attached yet. Initial visibility is correct
  // from the server render, so we only need to iterate on actual filter changes.

  #applyFilter(query) {
    const filter = this.activeFilterValue
    const q = query.trim().toLowerCase()
    let visible = 0
    for (const card of this.tasksTaskCardComponentOutlets) {
      const matchesFilter = filter === "all" || card.statusValue === filter
      const matchesQuery = q === "" || card.titleValue.toLowerCase().includes(q)
      const show = matchesFilter && matchesQuery
      card.setVisible(show)
      if (show) visible += 1
    }
    this.countValue = visible
    this.dispatch("filterApplied", {
      detail: { count: visible },
      target: window,
    })
  }
}
