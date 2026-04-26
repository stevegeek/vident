---
title: Why Vident?
nav_order: 2
---

# Why Vident?

Stimulus.js is fantastic for sprinkling interactivity onto server-rendered
HTML, but the seams show in the templates. Every controller name appears in
two or three places — `data-controller`, `data-action`,
`data-<controller>-target`, `data-<controller>-<value>-value`. Rename a
controller and you're chasing strings across `.erb`/`.rb`/`.js` files. Add a
new target and there's no signal that a typo killed it; the click handler
just silently no-ops.

Vident moves that wiring into the component class:

```ruby
class GreeterComponent < Vident::Phlex::HTML
  stimulus do
    actions :greet
    targets :name, :output
  end
end
```

The component knows its own controller identifier
(`greeter` here, derived from the class name), so every helper —
`stimulus_action`, `stimulus_target`, `stimulus_value` — emits the right
`data-*` attribute, automatically. Rename the class and the data attributes
follow.

## What Vident adds on top of Phlex / ViewComponent

- **Typed props** via the [Literal gem](https://github.com/joeldrapper/literal),
  with built-in `String`/`Integer`/`_Union(...)`/`_Nilable(...)` types.
- **A declarative `stimulus do` block** that captures actions, targets,
  values, classes, and outlets in one place — including dynamic values
  computed at render time from procs.
- **`root_element` helper** that renders the component's outer element with
  the right tag, ID, classes, and stimulus attributes — no manual
  bookkeeping.
- **Tailwind class merging** so callers can override base classes from the
  call site without specificity wars.
- **Component caching** via `cache_component` that scopes Rails fragment
  caching to the component's slots.
- **Stable, request-scoped element IDs** so cached fragments don't clash
  when re-rendered later in the same request.

Vident is deliberately small: it doesn't replace Phlex or ViewComponent,
doesn't ship a UI kit, and doesn't try to be Reactive. It removes the
boilerplate around the one thing both engines leave to you — wiring up
Stimulus.
