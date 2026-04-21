# frozen_string_literal: true

module Vident2
  # Thin Tailwind CSS merge integration — exposes a lazy per-thread merger
  # instance so the ClassListBuilder can collapse conflicting utilities
  # when ::TailwindMerge::Merger is available.
  module Tailwind
    def tailwind_merger
      return unless tailwind_merge_available?
      return @tailwind_merger if defined?(@tailwind_merger)

      @tailwind_merger = Thread.current[:vident2_tailwind_merger] ||= ::TailwindMerge::Merger.new
    end

    def tailwind_merge_available?
      defined?(::TailwindMerge::Merger) && ::TailwindMerge::Merger.respond_to?(:new)
    end
  end
end
