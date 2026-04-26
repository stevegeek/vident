import { Controller } from "@hotwired/stimulus"

// Demo controller for the V2 alias-resolution feature. Mounted alongside
// tasks--detail-panel-component on the same root so the panel element
// exposes two controllers; the Ruby DSL picks this one via `on_controller(:dismissable)`.
// `close()` mirrors the panel's close so either alias can drive the same UX.
export default class extends Controller {
  close() {
    this.element.classList.add("translate-x-full")
  }
}
