# frozen_string_literal: true

module PhlexGreetersV2
  # Demonstrates V2:
  #   - inherited stimulus config: parent's `stimulus do` is kept and this
  #     subclass's block is merged in, so the rendered controller has both
  #     action sets (V2 Component#inherited preserves parent declarations).
  #   - Symbol-form `stimulus_controllers:` (mirror of the String form).
  #   - `Vident2::Tailwind` class merging via `classes` prop to override
  #     conflicting Tailwind utilities from the base classes without CSS
  #     specificity games.
  class InheritedGreeterComponent < GreeterVidentComponent
    include ::Vident2::Tailwind

    # Lock to a V1-style identifier path — V1 doesn't have this component
    # but we keep the locked-identifier convention consistent with the
    # rest of the V2 family.
    class << self
      def stimulus_identifier_path = "phlex_greeters/inherited_greeter_component"
    end

    # Second stimulus block: the parent's actions/targets are preserved and
    # this block is merged in. The extra :status target just exists to prove
    # the merge — it needs no JS handler.
    stimulus do
      targets :status
    end

    private

    def root_element_attributes
      super.merge(
        # Symbol-form controller path is accepted alongside String.
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
