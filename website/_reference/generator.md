---
title: Install generator
nav_order: 2
---

# `vident:install` generator

```bash
bin/rails g vident:install
```

The generator does three things, all idempotent.

### 1. `config/initializers/vident.rb`

Configures Vident's request-scoped stable ID strategy and gives you a
single place to override defaults.

### 2. `ApplicationController` patch

Adds a `before_action` that seeds the stable ID generator per request
using a fresh seed. The seed makes element IDs deterministic *within* a
request (so cached fragments rehydrate cleanly) without colliding across
requests.

If your app already has its own `before_action` setup, the generator
inserts the seeding call alongside the existing ones — review the diff
before committing.

### 3. (Optional) `.claude/skills/vident/SKILL.md`

Drops a [Claude Code](https://docs.anthropic.com/en/docs/claude-code)
skill that teaches the model Vident's conventions: typed props, the
`stimulus do` block, `root_element`, and the file layout for sidecar
controllers. Re-run the generator with `--force` when you upgrade Vident
to refresh this file.

## Flags

| Flag                | Behaviour                                            |
| ------------------- | ---------------------------------------------------- |
| `--force`           | Overwrites generated files instead of skipping them. |
| `--skip-skill`      | Don't write the Claude Code skill.                   |
| `--skip-controller` | Don't patch `ApplicationController`.                 |

## Rendering outside a request

If you render Vident components in places without a Rails request — Rake
tasks, ActionMailer previews, scripts that exercise components in
isolation — wrap the render in
`Vident::StableId.with_sequence_generator(seed: "any-string")`. See
[Element IDs and seeding](/reference/element-ids/) for the details.
