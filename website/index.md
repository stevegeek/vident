---
layout: home
title: Vident
permalink: /
hero:
  name: Vident
  text: Build type-safe Rails components with first-class Stimulus
  tagline: One declarative DSL for Phlex or ViewComponent — no more hand-crafted data attributes, no more refactor anxiety.
  image:
    src: /assets/img/vident-logo.svg
    alt: Vident logo
  actions:
    - theme: brand
      text: Get started
      link: /introduction/getting-started/
    - theme: alt
      text: View on GitHub
      link: https://github.com/stevegeek/vident
features:
  - title: Two engines, one API
    details: "Drop into a Phlex or ViewComponent codebase without changing how you build views. Pick the engine that fits your app or preferred framework."
  - title: Stimulus without the boilerplate
    details: "Declare actions, targets, values, and classes in Ruby. The data attributes are generated for you, and renames stay safe."
  - title: Typed props
    details: "Components use the Literal gem for typed properties, so a wrong-shape arg fails loudly the moment a component is built."
  - title: Tailwind class merging
    details: "Override base classes from the call site. The built-in merger resolves conflicts the way Tailwind users expect."
  - title: Component caching
    details: "A cache_component helper scopes Rails fragment caching to the component, so expensive renders only happen once."
  - title: First-class generators
    details: "bin/rails g vident:install wires the per-request ID seeding and (optionally) drops a Claude Code skill in your repo."
---

## See it in action

Three release cards from a small deploy dashboard. Each card carries typed
props (`environment` is `_Union(:production, :staging, :preview)`, `status`
is `_Union(:pending, :deployed, :failed)`), a `stimulus do` block that maps
those props straight to Stimulus values, and dynamic `classes` that pick
the border colour from `@status` at render time.

Click a card or its **Promote** / **Cancel** buttons to see the same
controller code that runs in the dummy Rails app fire here too. The
**Vident source** tab shows the entire component — under 70 lines, no
hand-typed `data-*` attributes. The **Rendered HTML** tab shows what the
browser actually receives, with every attribute the DSL generated.

{% include demo.html slug="release_card" title="Deploy dashboard release card" %}

The Ruby file is the only source of truth for the controller identifier
(`dashboard--release-card-component`). Rename the class, and every
`data-action`, `data-target`, and `data-value` attribute moves with it —
no string-chasing across `.erb`/`.js`/`.rb` files.

## Installation

```ruby
# Gemfile
gem "vident"

# Pick at least one rendering engine
gem "vident-phlex"           # Phlex
gem "vident-view_component"  # ViewComponent
```

```bash
bundle install
bin/rails g vident:install
```

## Where to next

- **[Getting started →](/introduction/getting-started/)** — the 5-minute walkthrough.
- **[Components guide →](/guides/components/)** — the DSL, in depth.
- **[Stimulus DSL reference →](/reference/stimulus-dsl/)** — every actions/targets/values form.
