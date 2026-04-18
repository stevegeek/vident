# frozen_string_literal: true

module PhlexGreeters
  # Demonstrates:
  #   - inherited stimulus config: parent's `stimulus do` is kept and this subclass's
  #     block is merged in, so the rendered controller has both action sets
  #   - Symbol-form `stimulus_controllers:` (mirror of the String form, just less quoting)
  #   - `Vident::Tailwind` class merging: the user-supplied `:classes` prop can override
  #     conflicting Tailwind utilities from the base classes without css specificity games
  class InheritedGreeterComponent < GreeterVidentComponent
    include ::Vident::Tailwind

    # Second stimulus block: the parent's actions/targets are preserved and this
    # block is merged in. The extra :status target just exists to prove the
    # merge — it needs no JS handler.
    stimulus do
      targets :status
    end

    private

    def root_element_attributes
      super.merge(
        # Symbol-form path is accepted alongside String.
        stimulus_controllers: [:"phlex_greeters/greeter_vident_component"],
        html_options: {class: merged_classes}
      )
    end

    def merged_classes
      base = "px-3 py-2 bg-gray-100 text-gray-700"
      override = Array(@classes).join(" ")
      return "#{base} #{override}".strip unless tailwind_merger
      tailwind_merger.merge([base, override].reject(&:empty?).join(" "))
    end
  end
end
