import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  changeMessage() {
    this.clicked = !this.clicked;
    this.element.textContent = this.clicked ? this.data.get("afterClickedMessage") : this.data.get("beforeClickedMessage");
  }
}
