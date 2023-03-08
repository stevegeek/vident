# frozen_string_literal: true


module Vident
  module Tailwind
    # Adds a utility class merge specifically for Tailwind, allowing you to more easily specify class overrides
    # without having to worry about the specificity of the classes.
    def produce_style_classes(class_names)
      ::TailwindMerge::Merger.new.merge(dedupe_view_component_classes(class_names))
    end
  end
end
