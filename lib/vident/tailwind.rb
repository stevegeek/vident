require "vident/tailwind/version"
require "vident/tailwind/railtie"

require "tailwind_merge"

module Vident
  module Tailwind
    # Adds a utility class merge specifically for Tailwind, allowing you to more easily specify class overrides
    # without having to worry about the specificity of the classes.
    def produce_style_classes(class_names)
      to_merge = dedupe_view_component_classes(class_names)
      ::TailwindMerge::Merger.new.merge(to_merge) if to_merge.present?
    end
  end
end
