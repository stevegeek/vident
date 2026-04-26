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
    details: "bin/rails g vident:install sets up your app and base components. bin/rails g vident:component scaffolds a component, its Stimulus controller, and a unit test in one go."
---

## See it in action

Three task cards from the gem's own dummy app. Each carries typed props
(`list` is `_Union(:today, :this_week, :backlog)`, `status` is
`_Union(:todo, :done, :wont_do)`), a `stimulus do` block that maps the
status straight to a Stimulus value, and three named class lists that
the controller swaps when the card transitions between states.

Click **Mark done** or **Won't do** — the buttons disable, the border
colour swaps, the status text updates, and the title strikes through on
dismiss. Same Ruby class that ships in `test/dummy/app/components/tasks/`,
same Stimulus controller, just pre-rendered for the static site.

{% include demo.html slug="task_card" title="Task card" %}

The Ruby file is the only source of truth for the controller identifier
(`tasks--task-card-component`). Rename the class, and every
`data-action`, `data-target`, and `data-value` attribute moves with it —
no string-chasing across `.erb`/`.js`/`.rb` files. Prefer ViewComponent?
The same component lives [in either engine](/guides/view-component/) on
top of one DSL.

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
