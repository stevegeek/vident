# frozen_string_literal: true

Vident::StableId.strategy = if Rails.env.test?
  Vident::StableId::RANDOM_FALLBACK
else
  Vident::StableId::STRICT
end
