import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "name", "output" ]

  nameTargetConnected(element) {
    console.log(`Name target connected: ${element}`)
  }

  nameTargetDisconnected(element) {
    console.log(`Name target disconnected: ${element}`)
  }

  greet() {
    this.outputTarget.textContent =
      `Hello, ${this.nameTarget.value}!`
  }
}
