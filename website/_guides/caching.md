---
title: Component caching
nav_order: 5
---

# Component caching

Vident exposes a `cache_component` helper on both the Phlex and
ViewComponent adapters. It's a thin wrapper around Rails' fragment
caching that scopes the cache key to the component, so expensive renders
become a single cache lookup once warmed.

```ruby
class ProductCardComponent < Vident::ViewComponent::Base
  prop :product, Product

  def call
    cache_component(@product) do
      root_element do |card|
        # …expensive markup…
      end
    end
  end
end
```

The cache key is composed from the component class, its props (or an
explicit dependency you pass in), and the request-scoped ID seed, so:

- Two requests rendering the same component with the same props share a
  cache entry.
- Within a single request, repeated renders of a cached fragment keep
  consistent element IDs (the seed makes them deterministic), so
  Stimulus controllers wire up correctly to the rehydrated HTML.

### Tips

- Pass an explicit cache dependency (`cache_component([@product, @user])`)
  when the component reads things outside its props.
- Stimulus values that read from procs evaluate **before** the cache lookup,
  so they're stable across cache hits.
- For per-user output that should not be cached together, include the user
  (or their role) in the cache key.

For the broader cache key story and the seeding rationale, see
[Element IDs and seeding](/reference/element-ids/).
