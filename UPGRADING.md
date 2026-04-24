# Upgrading to Vident 2.0

Vident 2.0 is a ground-up rearchitecture. Most 1.x code keeps working, but several edge-case behaviours and a handful of class names changed. This guide walks through each breaking change — *symptom* (what you'll see) → *fix* (what to change).

If you hit something not covered here, the [CHANGELOG entry for 2.0.0](CHANGELOG.md) is the terse source of truth.

---

## 1. Legacy collection classes removed

**Symptom:** `NameError: uninitialized constant Vident::StimulusAction` (or `StimulusTarget`, `StimulusController`, `StimulusValue`, `StimulusParam`, `StimulusOutlet`, `StimulusClass`, any `*Collection`, `StimulusBuilder`, `StimulusDataAttributeBuilder`, `StimulusAttributeBase`, `StimulusAttributes`, `StimulusAction::Descriptor`).

**Fix:** map the name to its V2 equivalent:

| V1 | V2 |
| --- | --- |
| `Vident::StimulusAction` | `Vident::Stimulus::Action` |
| `Vident::StimulusTarget` | `Vident::Stimulus::Target` |
| `Vident::StimulusController` | `Vident::Stimulus::Controller` |
| `Vident::StimulusValue` | `Vident::Stimulus::Value` |
| `Vident::StimulusParam` | `Vident::Stimulus::Param` |
| `Vident::StimulusOutlet` | `Vident::Stimulus::Outlet` |
| `Vident::StimulusClass` | `Vident::Stimulus::ClassMap` |
| any `Stimulus*Collection` | `Vident::Stimulus::Collection` (parametric on kind) |
| `Vident::StimulusAction::Descriptor` | pass a Hash directly — see §8 below |
| `Vident::StimulusBuilder` | `Vident::Internals::DSL` (internal) |
| `Vident::StimulusAttributes` | `Vident::Capabilities::StimulusParsing` (internal) |

**Related: `#to_h` keys are now Symbols.** V1 returned String keys for some primitives (`"form-component-target" => "input"`); V2 returns Symbols (`:"form-component-target" => "input"`) uniformly. If you had code matching String keys (`coll.to_h["foo-target"]`), switch to Symbols (`coll.to_h[:"foo-target"]`).

---

## 2. `child_element` strictness — both-kwargs now raise

**Symptom:**

```
ArgumentError: 'stimulus_targets:' and 'stimulus_target:' are mutually exclusive — pass one or the other.
```

V1 silently dropped the singular when the plural was an empty array (a latent bug since 1.0.0). V2 refuses ambiguous input.

**Fix:** merge the singular into the plural at the call site. Works on both 1.x and 2.x:

```ruby
# Before
child_element(:input, stimulus_target: :input, stimulus_targets: control_targets)

# After
child_element(:input, stimulus_targets: [:input, *control_targets])
```

If `control_targets` is occasionally `nil`, use `*Array(control_targets)`.

---

## 3. `stimulus_controllers:` prop appends, no longer replaces

**Symptom:** The emitted `data-controller` attribute carries *both* the implied controller and the one(s) you passed at render time:

```html
<!-- 1.x -->
<div data-controller="tooltip">

<!-- 2.x -->
<div data-controller="button-component tooltip">
```

**Fix depends on intent:**

| You wanted | Do this |
| --- | --- |
| Additive (append to implied) | Do nothing — V2 matches this directly. |
| Always replace (component is generic) | Add `no_stimulus_controller` at the class level; `stimulus_controllers:` at the prop then becomes the only source. |
| Sometimes replace, sometimes append | Split into two subclasses (one with `no_stimulus_controller`), or file an issue — there's currently no per-render escape. |

```ruby
# Generic component that always takes a controller from the caller
class BaseDialog < Vident::ViewComponent::Base
  no_stimulus_controller
end

# render caller specifies:
render BaseDialog.new(stimulus_controllers: ["dialog/confirm"])
# → data-controller="dialog--confirm"   (no implied BaseDialog ctrl)
```

**Subclass re-enables the implied controller.** If a parent declares `no_stimulus_controller` and a subclass has its own paired JS controller, call `has_stimulus_controller` at the top of the subclass body — it flips the inherited flag back off. Order relative to `stimulus do` does not matter; idempotent on repeat.

```ruby
class ApplicationComponent < Vident::Phlex::HTML
  no_stimulus_controller     # generic shell — no JS controller
end

class DropdownComponent < ApplicationComponent
  has_stimulus_controller    # paired dropdown_component_controller.js
  stimulus { actions :toggle }
end
```

---

## 4. Outlet DSL procs now resolve

**Symptom:** Outlets declared with a proc selector in a `stimulus do` block previously emitted the literal `#<Proc:0x...>` string as the selector value. V2 evaluates the proc and emits the returned string.

If your code relied on the V1 behaviour (unlikely — the broken output was a bug), you'll now see a different, actually-working selector.

**Fix:** usually nothing — V2's behaviour is what you meant. Check the emitted `data-*-outlet=` value; if it was previously ignored JS-side, it now works and may need the JS controller updated.

```ruby
stimulus do
  outlets modal: -> { ".modal-#{@id}" }   # V1: emits "#<Proc:0x...>".  V2: emits ".modal-<id>".
end
```

---

## 5. `nil` vs `false` proc return — drop rule changed

**Symptom:**

```
Vident::ParseError: Action.parse: invalid arguments [false]
```

V1 dropped both `nil` and `false` proc returns silently (via a `blank?` filter). V2 drops only `nil`; `false` reaches the parser and raises.

**Fix:** return `nil` (not `false`) to mean "don't emit this entry":

```ruby
# Before
actions -> { [:click, :handle] if @editable }   # false when !@editable → silently dropped in V1
# Already correct: the implicit else returns nil, not false, so this is fine in V2 too.

# Explicit-false form — change to nil
actions -> { @editable ? [:click, :handle] : false }   # 1.x: dropped silently. V2: raises.
actions -> { @editable ? [:click, :handle] : nil }     # both versions: dropped.
```

---

## 6. `no_stimulus_controller` + DSL body — loud error

**Symptom:**

```
Vident::DeclarationError: cannot add stimulus entries when no_stimulus_controller is declared (MyComponent at app/components/my_component.rb:14)
```

V1 raised a bare `StandardError` at instance init with no class/location info. V2 raises at `stimulus do` time with the offending class and caller location.

**Fix:** the error message names the file and line. Either remove `no_stimulus_controller` or remove the DSL body — they're mutually exclusive by design.

---

## 7. `add_stimulus_actions([:click, :handle])` — Array is now one action

**Symptom:** Previously the mutator splatted the Array into two separate actions (`:click` and `:handle`); V2 treats it as a single `event + method` descriptor matching the DSL's `actions [:click, :handle]` semantics.

**Fix:** if you relied on the V1 splat behaviour, pass two separate arrays or make two calls:

```ruby
# Before (V1): one call, two actions emitted
add_stimulus_actions([:click, :handle])

# After (V2): same output, explicit
add_stimulus_actions(:click)
add_stimulus_actions(:handle)
```

---

## 8. `render_classes` / `stimulus_data_attributes` renamed

**Symptom:** `NoMethodError: undefined method 'render_classes'` or `'stimulus_data_attributes'` on a Vident component — typically in a component that renders its root tag via a third-party helper (`InlineSvg::inline_svg_tag`, custom `tag.*` constructions, etc.) instead of `root_element(...)`.

**Fix:** the V2 equivalents return the same shapes under V2-consistent names:

| V1 | V2 | Returns |
| --- | --- | --- |
| `render_classes(extra_class = nil)` | `root_element_class_list(extra_classes = nil)` | `String` |
| `stimulus_data_attributes` | `root_element_data_attributes` | `Hash` (Symbol keys) |

Both apply the full V2 pipeline (6-tier class cascade + Tailwind merge + sealed-Plan `data-*` expansion), so output matches what `root_element(...)` would emit on the root tag.

```ruby
class MySvg < Vident::Phlex::HTML
  no_stimulus_controller
  prop :name, String

  def view_template
    svg("data-src" => helpers.image_path(file_name), **svg_attributes) {}
  end

  private

  def svg_attributes
    {
      id: @id,
      class: root_element_class_list,         # was render_classes
      data: root_element_data_attributes      # was stimulus_data_attributes
    }
  end
end
```

The `extra_classes` argument to `root_element_class_list` is appended at the lowest-priority tier, so it's never dropped by a cascade winner.

---

## 9. `Vident::StimulusAction::Descriptor` removed

**Symptom:** `NameError: uninitialized constant Vident::StimulusAction::Descriptor`.

**Fix:** pass a Hash directly — `Vident::Stimulus::Action` parses the descriptor form natively now:

```ruby
# Before
actions Vident::StimulusAction::Descriptor.new(event: :click, method: :save, options: [:prevent])

# After
actions({event: :click, method: :save, options: [:prevent]})
```

Accepted Hash keys: `:event`, `:method`, `:controller`, `:options` (Array), `:keyboard`, `:window`.

---

## 10. Fluent action DSL (optional — new in V2)

While you're updating action declarations, V2 adds a fluent builder and kwargs shorthand that many find clearer than the Hash form:

```ruby
stimulus do
  action(:save).on(:click).modifier(:prevent, :stop)
  action :save, on: :click, modifier: [:prevent, :stop]    # kwargs — same thing
  action(:escape).on(:keydown).keyboard("esc").window
  action(:delete).when { admin? }

  # Controller aliases:
  controller "admin/users", as: :admin
  action(:save).on(:click).on_controller(:admin)           # click->admin--users#save
end
```

Chain methods: `.on`, `.call_method`, `.modifier`, `.keyboard`, `.window`, `.on_controller`, `.when`. The plural Array / Hash forms from V1 still work, so you can migrate incrementally.

---

## 11. Class-level Stimulus builders (optional — new in V2)

V2 adds class-method equivalents of the instance-level `stimulus_<kind>` parsers, for cases where you need the value object without a component instance — Turbo-Stream partials, JSON responses, test selectors, sibling ERB slots.

```ruby
ButtonComponent.stimulus_controller                 # implied Controller
ButtonComponent.stimulus_target(:submit)            # Vident::Stimulus::Target
ButtonComponent.stimulus_action(:click)             # implied#click
ButtonComponent.stimulus_action(:submit, :handle)   # submit->implied#handle
ButtonComponent.stimulus_value(:count, 0)
ButtonComponent.stimulus_param(:item_id, 42)
ButtonComponent.stimulus_class(:loading, "opacity-50")
ButtonComponent.stimulus_outlet(:modal, ".js-modal")  # selector required

# Class-level output matches instance-level:
ButtonComponent.stimulus_target(:submit).to_h ==
  ButtonComponent.new.stimulus_target(:submit).to_h   # => true
```

Two constraints at class level:

- **Outlets require an explicit selector.** A class has no `component_id` to auto-scope with, and an unscoped `[data-controller~=foo]` silently matches any sibling. `ButtonComponent.stimulus_outlet(:modal)` raises `Vident::ParseError`.
- **Cross-controller forms are rejected.** `ButtonComponent.stimulus_target("other/ctrl", :row)` reads like "target on the receiver" but silently ignores the receiver's identifier. If you need cross-controller, call the parser directly: `Vident::Stimulus::Target.parse("other/ctrl", :row, implied: ButtonComponent.stimulus_controller)`.

---

## Moving forward

- `CHANGELOG.md` has the full [2.0.0] entry if you want the terse list.
- `skills/vident/SKILL.md` is the V2 tutorial; `skills/vident/api-reference.md` is the spec.
- `doc/reviews/v1-gotchas.md` documents each V1 gotcha that V2 fixes, with before/after semantics.

If you hit a migration case not covered here, open an issue and we'll add it.
