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

**Related: V2 constructors take kwargs, not positional args.** After the rename in the table above, the next error you'll see at render time is:

```
ArgumentError: wrong number of arguments (given 2, expected 0; required keywords: controller, name)
```

V1 `Vident::StimulusAction.new(:click, "ctrl/path", :method)` (and the same positional pattern for `Target`, `Value`, `Outlet`, etc.) called the Literal-generated `.new` directly with positional args that mapped to props. V2's `Literal::Data` classes take kwargs — `.new(controller:, method_name:, event: nil, ...)` — and will not accept the V1 positional form.

Three ways to fix each call site:

1. **Prefer the Array form at prop boundaries.** Any `stimulus_*:` prop, `control_*` prop, or `child_element(stimulus_*: …)` kwarg accepts Array forms directly and parses them at render time:

   ```ruby
   # Target
   ::Vident::StimulusTarget.new("ctrl/path", :name)
   # → as prop value:
   ["ctrl/path", :name]

   # Action with event
   ::Vident::StimulusAction.new(:click, "ctrl/path", :method)
   # → as prop value:
   [:click, "ctrl/path", :method]

   # Action without event
   ::Vident::StimulusAction.new("ctrl/path", :method)
   # → as prop value:
   ["ctrl/path", :method]
   ```

   Idiomatic V2 and the shortest diff.

2. **Use `.parse(positional, ..., implied:)`** when you need a typed object for reuse or passing through a typed interface. `Vident::Stimulus::{Action,Target,Controller,...}.parse` is the V2 entry point that accepts the V1-style positional args. `implied:` is required — pass `nil` when every call site supplies an explicit controller path:

   ```ruby
   ::Vident::Stimulus::Action.parse(:click, "ctrl/path", :method, implied: nil)
   ::Vident::Stimulus::Target.parse("ctrl/path", :name, implied: nil)
   ```

3. **Construct with kwargs directly** when you're staying inside Vident internals:

   ```ruby
   ::Vident::Stimulus::Action.new(
     controller: ::Vident::Stimulus::Controller.parse("ctrl/path", implied: nil),
     method_name: :method,
     event: "click"
   )
   ```

**Related: `implied_controller:` kwarg is gone.** V1 accepted `StimulusAction.new(..., implied_controller: …)` as an eager-resolution hatch. V2 has no equivalent kwarg — use `.parse(..., implied: …)` or the Array form above, and the resolution happens at render time.

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

## 8. `Vident::StimulusAction::Descriptor` removed

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

## 9. Fluent action DSL (optional — new in V2)

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

## 10. `stimulus_identifier_from_path` removed

**Symptom:**

```
NoMethodError: undefined method `stimulus_identifier_from_path`
```

…on any component or in any template that used it to turn a controller path into its kebab-case `--`-separated identifier (e.g. `"entities/entity_user_form"` → `"entities--entity-user-form"`).

**Fix:** the helper moved and was renamed. Use `Vident::Stimulus::Naming.stimulize_path(path)`:

```ruby
# Before
stimulus_identifier_from_path(form_control_controller_path)

# After
::Vident::Stimulus::Naming.stimulize_path(form_control_controller_path)
```

Accepts the same `String`-or-`Symbol` input and returns the same identifier format.

---

## Moving forward

- `CHANGELOG.md` has the full [2.0.0] entry if you want the terse list.
- `skills/vident/SKILL.md` is the V2 tutorial; `skills/vident/api-reference.md` is the spec.
- `doc/reviews/v1-gotchas.md` documents each V1 gotcha that V2 fixes, with before/after semantics.

If you hit a migration case not covered here, open an issue and we'll add it.
