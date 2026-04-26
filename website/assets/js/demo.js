// Bootstraps the live demo on the docs site. We load Stimulus from a CDN so
// the static site needs no build pipeline. The controller registered here is
// the same one the dummy Rails app uses at /components/tasks — same identifier,
// same targets, same logic. The HTML embedded on the page is byte-for-byte
// what the dummy app produces.
import { Application, Controller } from "https://cdn.jsdelivr.net/npm/@hotwired/stimulus@3.2.2/dist/stimulus.js"

class TaskCardController extends Controller {
  static targets = ["doneButton", "dismissButton", "statusText", "titleText"]
  static classes = ["todo", "done", "wontDo"]
  static values  = { taskId: Number, title: String, status: String }

  select(event) {
    if (event.target.closest("button")) return
    flash(this.element, `Selected: ${this.titleValue}`, "info")
  }

  apply(event) {
    const kind = event.params.kind  // "done" | "dismissed"
    const newStatus = kind === "done" ? "done" : "wont_do"
    this.statusValue = newStatus
    this.doneButtonTarget.disabled = true
    this.dismissButtonTarget.disabled = true
    flash(this.element, `${this.titleValue} ${kind === "done" ? "marked done" : "dismissed"}`, kind)
  }

  statusValueChanged(newStatus, oldStatus) {
    if (oldStatus && oldStatus !== newStatus) this.#removeClasses(oldStatus)
    this.#addClasses(newStatus)
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
  #removeClasses(status) { this.element.classList.remove(...this.#classesFor(status)) }
  #addClasses(status)    { this.element.classList.add(...this.#classesFor(status)) }
}

// Tiny ephemeral toast pinned to the upper-right of the demo container, so
// clicks feel responsive without us having to ship the dummy app's full
// Toast component on the static site.
function flash(card, message, kind) {
  const host = card.closest(".vident-demo__live") || card.parentElement
  if (!host) return
  if (getComputedStyle(host).position === "static") host.style.position = "relative"
  const el = document.createElement("div")
  el.textContent = message
  el.style.cssText = [
    "position:absolute", "top:0.5rem", "right:0.5rem",
    "padding:0.4rem 0.7rem", "border-radius:0.375rem",
    "font-size:0.8rem", "font-weight:600",
    "color:#fff",
    "background:" + ({done: "#16a34a", dismissed: "#6b7280", info: "#2563eb"}[kind] || "#374151"),
    "box-shadow:0 6px 16px -8px rgba(0,0,0,0.4)",
    "transition:opacity 200ms ease, transform 200ms ease",
    "transform:translateY(-4px)", "opacity:0", "z-index:10"
  ].join(";")
  host.appendChild(el)
  requestAnimationFrame(() => { el.style.opacity = "1"; el.style.transform = "translateY(0)" })
  setTimeout(() => {
    el.style.opacity = "0"
    el.style.transform = "translateY(-4px)"
    setTimeout(() => el.remove(), 250)
  }, 1800)
}

const application = Application.start()
application.debug = false
application.register("tasks--task-card-component", TaskCardController)
window.Stimulus = application
