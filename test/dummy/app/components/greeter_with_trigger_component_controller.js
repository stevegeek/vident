import GreeterVidentComponentController from './greeter_vident_component_controller';

export default class extends GreeterVidentComponentController {
  static classes = [ "preClick", "postClick" ]

  greet() {
    this.clicked = !this.clicked;
    this.outputTarget.classList.toggle(this.preClickClasses, !this.clicked);
    this.outputTarget.classList.toggle(this.postClickClasses, this.clicked);

    if (this.clicked)
      super.greet();
    else
      this.clear();
  }

  clear() {
    this.outputTarget.textContent = '...';
    this.nameTarget.value = '';
  }
}
