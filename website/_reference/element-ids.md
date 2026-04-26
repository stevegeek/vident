---
title: Element IDs and seeding
nav_order: 3
---

# Element IDs and request-scoped seeding

Vident gives every component a stable DOM ID derived from a per-request
seed. The seed is set in a `before_action` (the install generator wires
it up); the result is:

- **Deterministic within a request** — re-rendering the same component in
  the same request produces the same ID, so cached fragments rehydrate
  cleanly and Stimulus targets/outlets keep referring to the right
  elements.
- **Distinct across requests** — two concurrent requests rendering the
  same component get different IDs, so if one happens to spill into a
  shared cache it doesn't poison the other.

## Strategies

The default strategy is a counter seeded from the request UUID. Other
strategies are pluggable via the initializer:

```ruby
Vident.configure do |config|
  config.stable_id_strategy = :counter # default
  # config.stable_id_strategy = :uuid  # one fresh UUID per element
end
```

## Rendering outside a request

In Rake tasks, mailer previews, or scripts that render components in
isolation, set the seed yourself:

```ruby
Vident::StableId.with_sequence_generator(seed: "my-task") do
  puts ProductCardComponent.new(product: p).call
end
```

Or, for one-off use:

```ruby
Vident::StableId.set_current_sequence_generator(seed: "my-task")
```

`with_sequence_generator` is preferable in long-lived processes — it
restores the previous generator on exit.

## The collision bug in earlier versions

Before request-scoped seeding (Vident <= 1.x), two concurrent requests
could share the in-process counter and emit the same DOM ID, which broke
Stimulus targeting on cached pages. The current strategy makes this
impossible. If you're upgrading from 1.x and have any custom `id`
overrides, audit them — fixed-string IDs still collide and you should
move them onto the seeded path.
