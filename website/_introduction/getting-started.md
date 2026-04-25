---
title: Getting started
nav_order: 1
---

# Getting started

Vident is a small set of gems that builds typed, Stimulus-wired components on
top of [Phlex](https://www.phlex.fun/) or
[ViewComponent](https://viewcomponent.org/). One declarative DSL replaces the
hand-typed data attributes for `data-controller`, `data-action`,
`data-target`, and friends — and because the controller's identifier lives in
Ruby, renames are safe and typos fail fast.

## Install

Add the core gem and at least one engine adapter:

```ruby
# Gemfile
gem "vident"
gem "vident-phlex"            # Phlex
gem "vident-view_component"   # ViewComponent
```

Then run the install generator:

```bash
bundle install
bin/rails g vident:install
```

The generator writes:

- `config/initializers/vident.rb` — configures per-request stable ID seeding so
  IDs are deterministic within a request but never collide across requests.
- An `ApplicationController` patch that sets the seed in a `before_action`.
- (Optional) `.claude/skills/vident/SKILL.md` — a Claude Code skill that
  teaches the model Vident's conventions. Re-run the generator with
  `--force` to refresh it on upgrades.

See the [generator reference](/reference/generator/) for flags and the full
list of files it creates.

## Your first component

```ruby
# app/components/greeter_component.rb
class GreeterComponent < Vident::Phlex::HTML
  prop :cta, String, default: "Greet"

  stimulus do
    actions :greet
    targets :name, :output
  end

  def view_template
    root_element do |greeter|
      input(type: "text", data: greeter.stimulus_target(:name).to_h)
      button(data: greeter.stimulus_action(:click, :greet).to_h) { @cta }
      span(data: greeter.stimulus_target(:output).to_h)
    end
  end
end
```

Render it the way you'd render any Phlex/ViewComponent component:

```erb
<%= render GreeterComponent.new(cta: "Say hi") %>
```

Drop a matching Stimulus controller in `app/javascript/controllers/` (or
beside the component if you use the
[sidecar layout](/reference/sidecar-controllers/)) and the component is live.

## Where to next

- [Why Vident?](/introduction/why-vident/) — what problem this solves.
- [Components guide](/guides/components/) — props, root element, hooks.
- [Stimulus integration](/guides/stimulus/) — the DSL in depth.
