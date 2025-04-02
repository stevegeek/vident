require "vident/tailwind/version"
require 'vident/tailwind/railtie' if defined?(Rails)

require "tailwind_merge"

module Vident
  # Adds a utility class merge specifically for Tailwind, allowing you to more easily specify class overrides
  # without having to worry about the specificity of the classes.
  module Tailwind
    def produce_style_classes(class_names)
      to_merge = dedupe_view_component_classes(class_names)
      tailwind_class_merger.merge(to_merge) if to_merge.present?
    end

    private

    # If needed this can be overridden in your component to provide options for the merger.
    def tailwind_class_merger
      return @tailwind_class_merger if defined? @tailwind_class_merger
      @tailwind_class_merger= (Thread.current[:tailwind_class_merger] ||= ::TailwindMerge::Merger.new)
    end
  end
end
