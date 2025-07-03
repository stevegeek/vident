# frozen_string_literal: true

module Vident
  # Adds Tailwind CSS class merging functionality to components
  # This module provides methods to create and manage TailwindMerge::Merger instances
  module Tailwind
    # Get or create a thread-safe Tailwind merger instance
    def tailwind_merger
      return unless tailwind_merge_available?

      return @tailwind_merger if defined?(@tailwind_merger)

      @tailwind_merger = Thread.current[:vident_tailwind_merger] ||= ::TailwindMerge::Merger.new
    end

    # Check if TailwindMerge gem is available
    def tailwind_merge_available?
      defined?(::TailwindMerge::Merger) && ::TailwindMerge::Merger.respond_to?(:new)
    rescue NameError
      false
    end
  end
end
