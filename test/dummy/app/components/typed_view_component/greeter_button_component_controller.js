import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    afterClickedMessage: String,
    beforeClickedMessage: String,
  }

  changeMessage() {
    this.clicked = !this.clicked;
    this.element.textContent = this.clicked ? this.afterClickedMessageValue : this.beforeClickedMessageValue;
  }
}
