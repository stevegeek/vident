# frozen_string_literal: true

# Vident needs a strategy for generating component element IDs.
#
# STRICT (production/development): raises if no per-request sequence generator
#   is set on the current thread. Pair with the before_action added to
#   ApplicationController to seed the generator from `request.fullpath` so that
#   identical requests produce identical IDs (etag-stable) while unrelated
#   requests don't collide. Note that `request.fullpath` includes the query
#   string, so /items/1?page=2 and /items/1?page=3 are treated as different
#   pages and get different IDs - usually what you want for pagination or
#   filter-driven views.
#
# RANDOM_FALLBACK (test): generates a unique random id when no generator is
#   set, so tests / previews / mailers don't need to wire up per-request seeding.
Vident::StableId.strategy = if Rails.env.test?
  Vident::StableId::RANDOM_FALLBACK
else
  Vident::StableId::STRICT
end
