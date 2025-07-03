import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    beforeClickedMessage: String,
    afterClickedMessage: String
  }

  changeMessage() {
    this.clicked = !this.clicked;
    console.log("clicked", this.beforeClickedMessageValue)
    this.element.textContent = this.clicked ? this.afterClickedMessageValue : this.beforeClickedMessageValue;
  }
}
