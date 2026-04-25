// Bootstraps the live demos on the docs site. We load Stimulus from a CDN so
// the static site needs no build pipeline, then register a controller under
// the exact identifier the rendered component uses. The HTML fragment
// embedded on the page is byte-for-byte what the dummy app produces, so the
// same wiring reaches the same elements here.
import { Application, Controller } from "https://cdn.jsdelivr.net/npm/@hotwired/stimulus@3.2.2/dist/stimulus.js"

class ReleaseCardController extends Controller {
  static targets = ["promoteButton", "cancelButton"]
  static values  = { releaseId: Number, name: String, status: String }

  select(event) {
    if (event.target.closest("button")) return
    flash(this.element, `Selected ${this.nameValue}`, "info")
  }

  // event.params.kind comes from the button's `data-…-kind-param` attribute,
  // which the Vident `stimulus_params: { kind: "promote" }` declaration
  // emits. Stimulus auto-camelCases these into `event.params.<name>`.
  apply(event) {
    const kind = event.params.kind
    this.promoteButtonTarget.disabled = true
    this.cancelButtonTarget.disabled = true
    flash(this.element, `${this.nameValue} ${kind === "promote" ? "promoted" : "cancelled"}`, kind)
  }
}

// Tiny ephemeral toast pinned to the upper-right of the demo container, so
// clicks feel responsive without us having to ship a real toast component.
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
    "background:" + ({promote: "#16a34a", cancel: "#dc2626", info: "#2563eb"}[kind] || "#374151"),
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
application.register("dashboard--release-card-component", ReleaseCardController)
window.Stimulus = application
