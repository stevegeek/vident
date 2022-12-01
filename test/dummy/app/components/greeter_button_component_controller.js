import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  changeMessage() {
    this.element.textContent = this.data.get("afterClickedMessage");
  }
}
