# Vident API reference

Public surface of `vident`, `vident-view_component`, and `vident-phlex`, verified against
the current code in `lib/vident/`. Every method's argument shapes, return shape, and
raise-conditions are documented here — SKILL.md is the tutorial; this file is the spec.

If something is missing, it isn't public. `lib/vident/*.rb` is the source of truth.

---

## 1. Base classes

### `Vident::ViewComponent::Base < ::ViewComponent::Base`

Inherits everything from `::ViewComponent::Base` and includes `Vident::Component`.
File: `lib/vident/view_component/base.rb`.

Adds:

- `root_element(**overrides, &block)` — renders the component's root tag. `overrides`
  are passed as HTML options (merged with `root_element_attributes`, `html_options`,
  class precedence rules from SKILL.md §4). Self-closing tags (`:area`, `:br`, `:col`,
  `:embed`, `:hr`, `:img`, `:input`, `:link`, `:meta`, `:param`, `:source`, `:track`,
  `:wbr`) are emitted without children.
- Class-level cache support: `template_path`, `component_path`, `components_base_path`,
  `cache_component_modified_time`, `cache_sidecar_view_modified_time`,
  `cache_rb_component_modified_time` — used by `Vident::Caching` to chain
  template mtimes into a component's cache key.

### `Vident::Phlex::HTML < ::Phlex::HTML`

Includes `Vident::Component`. File: `lib/vident/phlex/html.rb`.

Adds:

- `root_element(**overrides, &block)` — Phlex equivalent. Dispatches to the tag method
  named by `root_element_tag_type` (default `:div`). The block runs first, then the tag
  wraps the captured content so DSL methods called inside the block see resolved state
  before outer tag options are computed.
- Tag whitelist — `check_valid_html_tag!` enforces `STANDARD_ELEMENTS + VOID_ELEMENTS`
  (see file for the full set). Passing an unknown tag to `element_tag:` or to
  `child_element` raises `ArgumentError`.
- Source-file tracking — the class-level `inherited` hook records each subclass's source
  file in `component_source_file_path` so `Vident::Caching` can pick up an mtime.
- `child_element` lifecycle constraint — `child_element` writes to Phlex's render
  buffer, so it is **only valid during the component's own `view_template`**. From
  outside the render lifecycle (an external ERB partial holding a Phlex component
  reference, a helper, `ApplicationController.renderer.render(...)`, etc.) it raises
  `undefined method 'buffer' for nil`. Use the `as_stimulus_*` helpers (see
  `Vident::Component`) or spread `data: { **component.stimulus_target(:name) }` inline
  instead — those don't touch the buffer.

### `Vident::Component` (module)

Included into both base classes. File: `lib/vident/component.rb`.

Public class methods:

- `prop_names` — `Array(Symbol)`, list of every declared prop (including inherited).

Public instance methods:

- `after_component_initialize` — empty override hook. Runs after props are assigned and
  Vident has prepared its stimulus collections. Do not override `after_initialize` unless
  you `super` — Literal calls it to wire everything up.
- `root_element_classes` — override to return `String | Array(String) | nil`. Lower
  precedence than `html_options[:class]` and `root_element_attributes[:classes]`
  (see SKILL.md §4).
- `root_element_attributes` — override to return a Hash. Accepted keys (all optional):
  `:element_tag` (Symbol), `:html_options` (Hash), `:id` (String), `:classes`
  (String | Array), and any of the seven `stimulus_<plural>:` / `stimulus_<singular>:`
  keys documented in section 5.
- `with(overrides = {})` — returns a new instance, `self.class.new(**to_h.merge(overrides))`. `clone(overrides = {})` is a backward-compat alias.
- `inspect(klass_name = "Component")` — formatted debug string with every prop.
- `id` — `String`, auto-generated from `StableId` if `@id` was nil. The generated form
  is `"#{component_name}-#{StableId.next_id_in_sequence}"`.
- `prop_names` — instance-method alias for the class method.
- 14 `as_stimulus_*` helpers + 7 short aliases — return an HTML-safe `String` of raw
  `data-*` attributes, suitable for embedding inside an HTML tag (ERB or Phlex `raw(...)`).
  Signatures match the corresponding `stimulus_*` method (see section 4). Pure transforms
  over `stimulus_*` outputs — they don't write to a render buffer, so they're safe to call
  on a Phlex Vident component from outside its `view_template` (unlike `child_element`).
  - Plural: `as_stimulus_controllers`, `as_stimulus_actions`, `as_stimulus_targets`,
    `as_stimulus_outlets`, `as_stimulus_values`, `as_stimulus_params`, `as_stimulus_classes`.
  - Singular: `as_stimulus_controller`, `as_stimulus_action`, `as_stimulus_target`,
    `as_stimulus_outlet`, `as_stimulus_value`, `as_stimulus_param`, `as_stimulus_class`.
  - Aliases (singular only): `as_controller`, `as_action`, `as_target`, `as_outlet`,
    `as_value`, `as_param`, `as_class`.

Not public (override at your own risk, used internally):

- `root_element(&block)` — raises in the base; the ViewComponent / Phlex subclasses
  implement it.
- `root_element_tag_type` — returns `@element_tag || :div`.
- `random_id` — memoised generator (cached per instance).

### Built-in props (every component)

From `Vident::Component` (`lib/vident/component.rb`):

| Prop           | Type                                | Default        | Notes                                            |
| -------------- | ----------------------------------- | -------------- | ------------------------------------------------ |
| `element_tag`  | `Symbol`                            | `:div`         | Root HTML tag.                                   |
| `id`           | `_Nilable(String)`                  | auto           | Auto-generated via `StableId` when not provided. |
| `classes`      | `_Union(String, _Array(String))`    | `[]`           | Appended on top of all other class sources.      |
| `html_options` | `Hash`                              | `{}`           | Merged onto root; highest class-source precedence. |

From `Vident::Component` via the `StimulusDeclaring` / `StimulusParsing` capability mixins:

| Prop                    | Type                              | Default                              |
| ----------------------- | --------------------------------- | ------------------------------------ |
| `stimulus_controllers`  | `Vident::Types::StimulusControllers` | `[default_controller_path]` unless `no_stimulus_controller`, else `[]` |
| `stimulus_actions`      | `Vident::Types::StimulusActions`  | `[]`                                 |
| `stimulus_targets`      | `Vident::Types::StimulusTargets`  | `[]`                                 |
| `stimulus_outlets`      | `Vident::Types::StimulusOutlets`  | `[]`                                 |
| `stimulus_outlet_host`  | `_Nilable(Vident::Component)`     | `nil`                                |
| `stimulus_values`       | `Vident::Types::StimulusValues`   | `{}`                                 |
| `stimulus_params`       | `Vident::Types::StimulusParams`   | `{}`                                 |
| `stimulus_classes`      | `Vident::Types::StimulusClasses`  | `{}`                                 |

`Vident::Types::*` are the canonical Literal type unions for each prop kind (file: `lib/vident/types.rb`). The unions are:

- `StimulusControllers` → `_Array(_Union(String, Symbol, Vident::Stimulus::Controller))`
- `StimulusActions` → `_Array(_Union(String, Symbol, Array, Hash, Vident::Stimulus::Action))`
- `StimulusTargets` → `_Array(_Union(String, Symbol, Array, Vident::Stimulus::Target))`
- `StimulusOutlets` → `_Array(_Union(String, Symbol, Array, Vident::Stimulus::Outlet))`
- `StimulusValues` → `_Union(_Hash(Symbol, _Any), Array, Vident::Stimulus::Value)`
- `StimulusParams` → `_Union(_Hash(Symbol, _Any), Array, Vident::Stimulus::Param)`
- `StimulusClasses` → `_Union(_Hash(Symbol, _Any), Array, Vident::Stimulus::ClassMap)`

Exposed publicly so user components can reuse them when adding matching props:

```ruby
class MyComponent < Vident::ViewComponent::Base
  prop :extra_actions, Vident::Types::StimulusActions, default: -> { [] }
end
```

---

## 2. Class-level DSL

All of these live on `Vident::Component`'s class body (via included modules).

- `prop(name, type, **literal_options)` — from the Literal gem. See
  https://literal.fun/ for option details. `default:` may be a callable (`lambda/proc`)
  or an immediate value; callable is required when the default is non-frozen (hash, array).
- `no_stimulus_controller` — sets a class ivar that drops the implied controller from
  the `stimulus_controllers` default. Use when the component is purely presentational
  and needs no paired `_controller.js`. Inherited by subclasses.
- `has_stimulus_controller` — the inverse: re-enables the implied controller on a
  subclass whose parent declared `no_stimulus_controller`. Idempotent; order relative
  to `stimulus do` blocks does not matter.
- `stimulus_controller?` — `Boolean`, `true` by default; becomes `false` after a
  `no_stimulus_controller` declaration and `true` again after `has_stimulus_controller`.
- `stimulus_identifier_path` — the `name.underscore` of the class (e.g.
  `"dashboard/release_card_component"`). Falls back to `"anonymous_component"` for
  anonymous classes.
- `stimulus_identifier` — `stimulize_path(stimulus_identifier_path)` — the kebab-cased
  identifier (`"dashboard--release-card-component"`). Also available as an instance method.
- `component_name` — memoised alias for `stimulus_identifier`. Also available as an
  instance method. Used as the first class on the root element and as the outlet name
  seed.
- `stimulus_scoped_event(event)` — `Symbol` of the form `:"<component_name>:<jsName>"`.
  E.g. `FooComponent.stimulus_scoped_event(:data_ready)` →
  `:"foo-component:dataReady"`. Also an instance method.
- `stimulus_scoped_event_on_window(event)` — same, with `@window` suffix. Also an
  instance method.
- `stimulus(&block)` — the DSL entry point. Opens a `Vident::Internals::DSL` block
  evaluator. See section 3.

Not intended for application code:

- `declarations` — frozen `Vident::Internals::Declarations` aggregate (own + inherited);
  `protected`, consumed by the Resolver at render time.

---

## 3. `stimulus do ... end` block

Evaluated by `Vident::Internals::DSL` (`lib/vident/internals/dsl.rb`). Multiple
`stimulus do` blocks on the same class accumulate. A subclass's blocks are merged with
every parent's blocks on first access (subclass entries appended to positional kinds;
subclass wins on conflicts for keyed kinds).

Every DSL method returns `self` (for the singular primitives `action`/`target`, the
fluent **builder** is returned instead — chain methods also return self). All DSL
entries may use a `Proc` anywhere a value is expected; procs are evaluated via
`instance_exec` on the component instance at render time (or at `after_initialize`
for purely static entries).

### Methods on the builder

**Controllers.** Primary form is the singular `controller`; plural `controllers`
accumulates paths without the `as:` alias.

- `controller(path, as: alias_sym = nil)` — declare a cross-controller path on
  the root element. Optional `as:` registers an alias looked up by
  `action(...).on_controller(alias_sym)` / `on_controller: alias_sym`. Paths
  may be `String` (`"admin/users"`) or `Symbol` (`:admin_users`).
- `controllers(*paths)` — one entry per path. Array entries splat into the
  singular parser (so `[path, as: sym]` tuples work when building
  programmatically).
- `no_stimulus_controller` — class-level, **not** inside the block. Suppresses
  the implied controller. Raises `Vident::DeclarationError` if any DSL entries
  were subsequently added.

**Actions.** Primary form is the singular `action(*args, **meta)` which returns
an `Internals::ActionBuilder`. Chain methods pre-applied via kwargs are equivalent
to calling the setters explicitly.

- `action(*args, **meta) -> ActionBuilder` — builder state:
  - Positional `*args` shapes (`base_descriptor` pattern-matches):
    - `(Symbol)`                     → method on implied (no event)
    - `(Symbol, Symbol)`             → `(event, method)` on implied
    - `(Symbol, String, Symbol)`     → `(event, controller_path, method)`
    - `(Hash)`                       → full descriptor (`:method`, `:event`, `:controller`, `:options`, `:keyboard`, `:window`)
  - Kwargs `**meta` (equivalent to the fluent chain methods):
    - `on:` (Symbol/String)          → event
    - `call_method:` (Symbol/String) → override the method name
    - `modifier:` (Symbol or Array)  → Stimulus options whitelist (see §4.2)
    - `keyboard:` (String)           → `keydown.<key>` filter suffix
    - `window:` (Boolean)            → `@window` suffix
    - `on_controller:` (Symbol)      → resolve against a `controller ..., as: sym` alias
    - `when:` (Proc / callable)      → render-time predicate; `false`/`nil` drops the entry
  - Unknown kwargs raise `ArgumentError`.
- Chain methods on the returned builder: `.on(event)`, `.call_method(name)`,
  `.modifier(*opts)`, `.keyboard(str)`, `.window`, `.on_controller(sym)`,
  `.when(callable = nil, &block)`. Each returns the builder.
- `actions(*entries)` — legacy plural form, still accepted. Each entry is one of:
  - `Symbol`                         → `implied#<jsSymbol>`
  - `[Symbol, Symbol]`               → `<event>-><implied>#<jsMethod>`
  - `[Symbol, String, Symbol]`       → `<event>-><stimulized-path>#<jsMethod>`
  - `String` containing `#`          → parsed literally (pass-through).
  - `Hash`                           → descriptor keys as above.
  - `Proc`                           → evaluated at render time; `nil`/`false` drops.

**Alias resolution.** When an action descriptor's `:controller` is a `Symbol`, the
resolver looks it up in the class's declared alias map (`controller X, as: sym`
entries) and substitutes the full path before parsing. Unknown alias →
`Vident::DeclarationError`. Alias resolution also runs on runtime inputs
(`stimulus_actions:` prop, `root_element_attributes[:stimulus_actions]`) that
carry a Hash with a `Symbol` `:controller`.

**Targets.** Singular `target` returns a `TargetBuilder` whose only chain method
is `.when`; plural `targets` accepts the same positional shapes as before.

- `target(*args) -> TargetBuilder` — chain `.when(callable = nil, &block)` for
  conditional inclusion; without a chain, the builder passes `*args` through.
- `targets(*entries)` — each entry is one of:
  - `Symbol`                         → target on the implied controller
  - `String`                         → pass-through target name
  - `[String, Symbol]`               → target on the named cross-controller
  - `Proc` — `nil` return drops the entry.

**Keyed primitives.** `values`, `params`, `classes`, `outlets` keep the plural
kwargs form and add singular `value`/`param`/`class_map`/`outlet` that take
`(name, *args, **meta)`:

- `values(**kvs)` / `value(name, *args, **meta)` — keyed. Values may be
  `String`/`Number`/`Boolean` (stringified), `Array`/`Hash` (JSON-serialised),
  `Vident::StimulusNull` (emits literal `"null"`), or a `Proc` resolving to
  any of the above. A resolved `nil` omits the attribute. Singular supports
  `value :count, static: 0` and `value :clicked_count, from_prop: true` meta
  forms.
- `params(**kvs)` / `param(name, *args, **meta)` — same serialisation rules.
- `classes(**kvs)` / `class_map(name, *args, **meta)` — value is `String` or
  `Array(String)`; array joined with single space.
- `outlets(positional_hash = nil, **kvs)` / `outlet(name, *args, **meta)` —
  value is a `String` CSS selector, a `Proc` returning one, or a pre-built
  outlet value object. `outlets({"admin--users" => ".sel"})` accepts a
  positional Hash so identifiers containing `--` (not valid Ruby kwarg keys)
  work.
- `values_from_props(*prop_names)` — keyed, sidecar to `values`. Mirrors each
  prop's current `@ivar` value at render time. Prop names are Symbols.

### What the builder emits

`to_declarations` (called on the `Vident::Internals::DSL` instance when the block
closes) returns a frozen `Vident::Internals::Declarations` struct. The struct is a
`Data.define(...)` value object with these fields — all frozen arrays:

| Field              | Content                                                                    |
| ------------------ | -------------------------------------------------------------------------- |
| `controllers`      | `Array` of `Declaration` entries (each wraps a path + optional `as:` alias). |
| `actions`          | `Array` of `Declaration` entries, one per `action(...)` call.              |
| `targets`          | `Array` of `Declaration` entries, one per `target(...)` call.              |
| `outlets`          | `Array` of `[key, Declaration]` pairs (keyed; last-write-wins on same key).|
| `values`           | `Array` of `[key, Declaration]` pairs.                                     |
| `params`           | `Array` of `[key, Declaration]` pairs.                                     |
| `class_maps`       | `Array` of `[key, Declaration]` pairs.                                     |
| `values_from_props`| `Array(Symbol)` — prop names listed via `values_from_props`.              |

The struct supports `merge(other)` (subclass block merged over superclass) and
`any?`. Entries remain as raw `Declaration` tuples — parsing into
`Vident::Stimulus::*` value objects is deferred to the Resolver at render time.
Application code does not call `to_declarations` directly.

---

## 4. Instance-level Stimulus helpers (`Vident::Capabilities::StimulusParsing`)

Included into every component via `Vident::Component`. File:
`lib/vident/capabilities/stimulus_parsing.rb`.

### 4.1 Plural parsers `stimulus_<plural>(*args)`

Seven methods: `stimulus_controllers`, `stimulus_actions`, `stimulus_targets`,
`stimulus_outlets`, `stimulus_values`, `stimulus_params`, `stimulus_classes`.

Each returns a collection object (`Vident::Stimulus::Collection`, etc.) whose `#to_h`
serialises to a `Hash` of `data-*` keys → values. Arg handling per input:

- no args or all-blank         → empty collection
- single pre-built collection  → returned as-is
- `Array`                      → splatted into the singular builder
- `Hash` (for **keyed** primitives: outlets, values, params, classes)
  → expanded per-pair, each pair becomes one value object
- `Hash` (for **positional** primitives: controllers, actions, targets)
  → passed as a single-arg descriptor (Action's `{event:, method:, ...}` form)
- pre-built value object        → preserved

### 4.2 Singular builders `stimulus_<singular>(*args)`

Each singular builder delegates to the corresponding value class's `.parse(*args, implied:, component_id:)`
class method. Raises `ArgumentError` (or `Vident::ParseError`) on unsupported shape or arity.

- `stimulus_controller(*)` — 0 or 1 arg. 0 args returns the implied controller; 1 arg
  is a controller path `String`/`Symbol`.
- `stimulus_action(*)` — 1/2/3 args. See `Vident::Stimulus::Action.parse` for all
  accepted forms. `options:` whitelist (raises otherwise):
  `[:once, :prevent, :stop, :passive, :"!passive", :capture, :self]`.
- `stimulus_target(*)` — 1 or 2 args. `(Symbol)` / `(String)` → implied controller;
  `(String, Symbol)` → cross-controller + name.
- `stimulus_outlet(*)` — 1/2/3 args.
  - `(Symbol)` or `(String)` → identifier, auto-generated selector
    `"#<component_id> [data-controller~=<identifier>]"`.
  - `(Array[identifier, selector])` — explicit selector.
  - `(component_instance)` — instance responding to `#stimulus_identifier` or
    `#implied_controller_name`; auto-selector built from its identifier.
  - `(String|Symbol, String)` → outlet-name + selector on implied controller.
  - `(String, Symbol, String)` → cross-controller + outlet-name + selector.
- `stimulus_value(name, value)` or `stimulus_value(controller_path, name, value)` —
  2 or 3 args.
- `stimulus_param(name, value)` or `stimulus_param(controller_path, name, value)` —
  2 or 3 args.
- `stimulus_class(name, classes)` or `stimulus_class(controller_path, name, classes)` —
  2 or 3 args; `classes` is `String` or `Array(String)`.

### 4.3 Mutators `add_stimulus_<plural>(input)`

Seven methods, one per primitive. Merge new attributes into the per-kind collection
ivar (e.g. `@stimulus_actions_collection`). Typical use: inside
`after_component_initialize`, compute runtime attributes and add them.

**Array input is one entry.** `add_stimulus_actions([:click, :handle])` treats the
Array as *one* action descriptor (event + method pair), matching the DSL's
`actions [:click, :handle]` semantics. The V1 splat asymmetry — where the mutator
treated the Array as two separate symbol actions — was fixed in V2. To pass a
pre-built action object, construct it first:
`add_stimulus_actions(stimulus_action(:click, :handle))`.

### 4.4 Value serialisation

`Array` and `Hash` → JSON. Everything else → `to_s`. `Vident::StimulusNull.to_s`
returns the literal string `"null"`. A `nil` reaches the DSL/prop layer and
is dropped by the Resolver before serialisation, so the data attribute is omitted
(not emitted as empty).

### 4.5 Name-shaping helpers

`Vident::Stimulus::Naming` is a `module_function` module — call its methods directly:

- `Vident::Stimulus::Naming.stimulize_path(path)` — `"admin/users"` → `"admin--users"`;
  each path segment is `dasherize`d and segments joined with `--`.
- `Vident::Stimulus::Naming.js_name(name)` — `camelize(:lower)`; `:my_thing` → `"myThing"`.

### 4.6 Scoped events

- Class method `stimulus_scoped_event(event)` — returns `Symbol`
  `:"<component_name>:<jsName>"`. **Call on the dispatcher's class**, not on the
  listener's.
- Class method `stimulus_scoped_event_on_window(event)` — same with `@window` suffix.
- Both also exist as instance methods that delegate to the class method.

### 4.7 Class-level builders

Class methods parallel to the instance singulars, useful when you need a
Stimulus value object without a component instance (Turbo-Stream partials,
JSON responses, system-test selectors).

- `MyComponent.stimulus_controller` — no args; returns the implied `Vident::Stimulus::Controller`.
- `MyComponent.stimulus_target(Symbol|String)` — returns `Vident::Stimulus::Target`.
- `MyComponent.stimulus_action(*args)` — same grammar as the instance singular, but cross-controller forms (`[String, Symbol]`, `[Symbol, String, Symbol]`) raise `Vident::ParseError`.
- `MyComponent.stimulus_value(name, value)` — two-arg form only; the three-arg cross-controller form raises.
- `MyComponent.stimulus_param(name, value)` — same constraint.
- `MyComponent.stimulus_class(name, css)` — same constraint.
- `MyComponent.stimulus_outlet(name, selector)` — **selector required**; single-arg auto-selector form raises `Vident::ParseError` (no `component_id` at class level). For cross-controller outlets, call `Vident::Stimulus::Outlet.parse(...)` directly.

Class-level output matches instance-level where both apply:

```ruby
ButtonComponent.stimulus_target(:submit).to_h ==
  ButtonComponent.new.stimulus_target(:submit).to_h   # => true
```

The implied controller is memoised per-class on the singleton; subclasses inherit the identifier path but get their own memo.

### 4.8 Root-element composition helpers

Two instance methods that return what `root_element(...)` would emit — for components that render their root tag via a third-party helper (e.g. `InlineSvg::inline_svg_tag`).

- `root_element_class_list(extra_classes = nil)` — returns a `String`. Applies the full 6-tier class cascade (`component_name`, `root_element_classes`, `root_element_attributes[:classes]`, `html_options[:class]`, `@classes` prop, then `extra_classes`) plus Tailwind-merging.
- `root_element_data_attributes` — returns a `Hash` with Symbol keys. Seals the Draft into a Plan (idempotent) and runs the AttributeWriter, yielding the same `data-controller` / `data-action` / `data-*-target` / etc. hash that `root_element(...)` would emit.

```ruby
def svg_attributes
  {
    id: @id,
    class: root_element_class_list,
    data: root_element_data_attributes
  }
end
```

Both honour `no_stimulus_controller` (no `data-controller` in the hash; component-identifier CSS class still emitted, matching `root_element`).

---

## 5. `root_element_attributes` accepted keys

Override `root_element_attributes` (instance method on your component) to return any
subset of:

| Key                   | Type                                                  | Effect                                                                  |
| --------------------- | ----------------------------------------------------- | ----------------------------------------------------------------------- |
| `:element_tag`        | `Symbol`                                              | Overrides the root element tag.                                         |
| `:html_options`       | `Hash`                                                | Merged onto the root; highest-precedence source for `:class`.           |
| `:classes`            | `String \| Array(String)`                             | Second-highest `:class` source (see SKILL.md §4).                       |
| `:id`                 | `String`                                              | Sets the root element's id.                                             |
| `:stimulus_controllers`| Same shape as `stimulus_controllers` prop            | Merged into the controllers collection.                                 |
| `:stimulus_actions`   | Same shape as `stimulus_actions` prop                 | Merged into the actions collection.                                     |
| `:stimulus_targets`   | Same shape as `stimulus_targets` prop                 | Merged into the targets collection.                                     |
| `:stimulus_outlets`   | Same shape as `stimulus_outlets` prop                 | Merged into the outlets collection.                                     |
| `:stimulus_values`    | Same shape as `stimulus_values` prop                  | Merged into the values collection.                                      |
| `:stimulus_params`    | Same shape as `stimulus_params` prop                  | Merged into the params collection.                                      |
| `:stimulus_classes`   | Same shape as `stimulus_classes` prop                 | Merged into the classes collection.                                     |

Precedence (lower wins if both set):

1. `stimulus do` DSL
2. `stimulus_*` props (the `render Foo.new(stimulus_actions: ...)` path)
3. `root_element_attributes` return value
4. `add_stimulus_*` called after those (e.g. in `after_component_initialize`)

---

## 6. `child_element`

Renders a single child tag with `stimulus_*` kwargs compiled into `data-*` attributes.

```ruby
def child_element(tag_name,
                  stimulus_controllers: nil, stimulus_controller: nil,
                  stimulus_actions: nil,     stimulus_action: nil,
                  stimulus_targets: nil,     stimulus_target: nil,
                  stimulus_outlets: nil,     stimulus_outlet: nil,
                  stimulus_values: nil,      stimulus_value: nil,
                  stimulus_params: nil,      stimulus_param: nil,
                  stimulus_classes: nil,     stimulus_class: nil,
                  **options, &block)
```

- Plural kwargs take an `Enumerable`; passing a non-Enumerable raises
  `ArgumentError` with a message pointing at the singular name.
- Singular kwargs take a single entry.
- `**options` passes through as HTML options.
- For ViewComponent's renderer, self-closing tags are emitted without the block.
- For Phlex's renderer, the tag name is validated against
  `Vident::Phlex::HTML::VALID_TAGS`; unknown tags raise `ArgumentError`. Phlex's
  `child_element` writes to the component's render buffer, so it is **only valid
  during the component's own `view_template`**. Calling it from outside the render
  lifecycle (an external ERB partial, a helper, `ApplicationController.renderer.render`)
  raises `undefined method 'buffer' for nil`. Use `as_stimulus_*` helpers there
  instead — those have no buffer dependency.

---

## 7. `Vident::Internals::DSL` primitives

For use in advanced cases (passing typed descriptors across components, building
reusable shared helpers). Value classes live under `lib/vident/stimulus/`.

### Hash descriptor form

There is no separate `Descriptor` class in V2. The Hash form accepted by `actions`
(and `stimulus_actions:`) is parsed directly into `Vident::Stimulus::Action`. Accepted keys:

| Key           | Type                                  | Default |
| ------------- | ------------------------------------- | ------- |
| `method:`     | `Symbol \| String`                    | required |
| `event:`      | `Symbol \| String \| nil`             | `nil`   |
| `controller:` | `String \| nil`                       | `nil`   |
| `options:`    | `Array(Symbol)` — see §4.2 whitelist  | `[]`    |
| `keyboard:`   | `String \| nil`                       | `nil`   |
| `window:`     | `Boolean`                             | `false` |

### `Vident::StimulusNull`

Frozen singleton object. `inspect` → `"Vident::StimulusNull"`; `to_s` → `"null"`.
See SKILL.md §1.4 for the usage contract.

### Collection class

All primitive kinds share one parametric class: `Vident::Stimulus::Collection`,
parametrised on a `Kind` record from `Vident::Internals::Registry`.

- Methods: `each`, `to_a`, `size`, `length`, `empty?`, `any?`, `to_h`, `to_hash`,
  `merge(other)` (single same-kind Collection; raises `ArgumentError` on mismatch).
- `#to_h` shape per kind:
  - `actions` → `{action: "…"}` with entries joined by space.
  - `controllers` → `{controller: "…"}` with non-empty entries joined by space.
  - `targets` → one key per controller-target attribute; multiple targets on
    the same controller joined with a single space.
  - `values`, `params`, `class_maps` → merged per-data-attribute Hash.
  - `outlets` → same.

---

## 8. `Vident::Caching`

Opt-in: `include Vident::Caching` + `with_cache_key(...)` in the component class.
File: `lib/vident/caching.rb`.

### Class methods

- `with_cache_key(*attrs, name: :_collection)` — declares which attributes feed into
  `cache_key`. The call appends `:component_modified_time` and `:to_h` (when
  available) to the given attrs, then calls `named_cache_key_includes(name, *attrs.uniq)`.
- `depends_on(*klasses)` — chains other Vident components' `component_modified_time`
  into this class's `component_modified_time`, so sub-component edits bust the
  parent's cache.
- `component_modified_time` — memoised in `Rails.env.production?`, otherwise recomputed
  on every call. Raises `Vident::ConfigurationError` if the host class has no
  `cache_component_modified_time` (base classes provide it).

### Instance methods

- `component_modified_time` — delegates to the class method.
- `cacheable?` — `respond_to?(:cache_key)`.
- `cache_key` — defined when `with_cache_key` has been called; returns
  `"#{class.name}/#{cache_keys_for_sources(...).join("/")}"`, optionally suffixed with
  `ENV["RAILS_CACHE_ID"]`. Raises `Vident::ConfigurationError` if the computed key is blank.
- `cache_key_modifier` — returns `ENV["RAILS_CACHE_ID"]` (may be nil).

`with_cache_key` without any attrs is valid — the call still appends
`:component_modified_time` and `:to_h`, so the cache key reflects the template mtime
plus the component's full prop hash.

### Fragment-caching the render: `cache_component`

Available on both adapter base classes (`Vident::Phlex::HTML` and `Vident::ViewComponent::Base`). Wraps a block of render output with Rails.cache using the Vident-computed `cache_key`:

- `cache_component(*extra_keys, **options, &block)` — on Phlex, delegates to `Phlex::SGML#cache([cache_key, *extra_keys], **options, &block)`. On ViewComponent, uses `Rails.cache.fetch([cache_key, *extra_keys], **options) { capture(&block) }`.
- Raises `Vident::ConfigurationError` if the component is not cacheable (no `with_cache_key` declared).
- `extra_keys` let the caller add per-render state to the cache key without modifying `with_cache_key`.
- Phlex usage: inside `view_template`. ViewComponent usage: inside a `def call` method; sidecar ERB templates can use Rails' native `<% cache cache_key do %> ... <% end %>` instead.

---

## 9. `Vident::StableId`

File: `lib/vident/stable_id.rb`.

### Errors

- `Vident::StableId::GeneratorNotSetError` — raised by `STRICT` when no per-thread
  sequence generator is set.
- `Vident::StableId::StrategyNotConfiguredError` — raised when any component calls
  `next_id_in_sequence` before `StableId.strategy=` has been set.

### Strategies (both callables accepting `(generator_or_nil) -> String`)

- `STRICT` — raises `GeneratorNotSetError` if the generator is nil. Use in
  development/production paired with the `before_action` seed in `ApplicationController`.
- `RANDOM_FALLBACK` — returns `Random.hex(16)` when the generator is nil; otherwise
  returns `generator.next.join("-")`. Use in test/previews/jobs/mailers.

### Class methods

- `strategy` / `strategy=` — get/set the configured callable.
- `set_current_sequence_generator(seed:)` — seeds a per-thread generator. Raises
  `ArgumentError` on `seed: nil`. Seed is MD5-hashed then fed to `Random.new`, so any
  `String`-coercible seed works.
- `clear_current_sequence_generator` — clears the per-thread generator.
- `with_sequence_generator(seed:) { ... }` — scoped seed for a block (used by jobs,
  mailers, Metal endpoints). Restores the previous generator on exit.
- `next_id_in_sequence` — delegates to the configured `strategy`.

### Installation

`bin/rails generate vident:install` (file:
`lib/generators/vident/install/install_generator.rb`):

1. Writes `config/initializers/vident.rb` setting `strategy` to `RANDOM_FALLBACK` in
   test and `STRICT` everywhere else.
2. Injects `before_action` + `after_action` into `ApplicationController` (idempotent —
   skips if a previous install patched it).
3. Copies `skills/vident/SKILL.md` from the gem to `.claude/skills/vident/SKILL.md`
   in the host app (skipped if already present).

---

## 10. `Vident::Tailwind`

Included into every component. File: `lib/vident/tailwind.rb`.

- `tailwind_merger` — returns a thread-cached `::TailwindMerge::Merger` instance if
  the `tailwind_merge` gem is loaded; otherwise returns `nil`.
- `tailwind_merge_available?` — `true` iff `::TailwindMerge::Merger` is defined.

`Vident::Internals::ClassListBuilder` invokes `tailwind_merger.merge(class_string)` automatically
at the final stage of its `call(...)` when a merger is provided. No per-component
opt-in is required beyond adding the gem to the Gemfile.

---

## 11. `class_list_for_stimulus_classes`

Instance method on every component. File: `lib/vident/capabilities/class_list_building.rb`.

```ruby
class_list_for_stimulus_classes(*names) -> String
```

Returns the resolved `data-*-class` values for the named stimulus-class entries,
deduplicated and (when `tailwind_merger` is available) Tailwind-merged. Intended
for inlining into `class=` on SSR so the first render has the same visual state the
JS controller will toggle on/off.

Names may be `Symbol` or `String`; both are normalised via `dasherize`.

---

## 12. Rails engine hooks

- `Vident::Engine` (`lib/vident/engine.rb`) — autoloaded when Rails is defined.
  Registers Zeitwerk inflections for Vident's non-standard file names (`"dsl"` →
  `"DSL"`, `"html"` → `"HTML"`) so `Vident::Internals::DSL` and
  `Vident::Phlex::HTML` resolve correctly. It does not load any generators at
  engine init — `Vident::Generators::InstallGenerator` is autoloaded on demand
  when `bin/rails generate vident:install` is invoked.

---

## 13. What's not in the public API

The following show up in `lib/vident/` but are explicitly internal:

- `Vident::Internals::Registry::KINDS` / `Vident::Internals::Registry::Kind` — the
  registry that drives every plural parser, mutator, and DSL primitive. Don't rely on
  these in application code.
- `Vident::Stimulus::Naming` — pure naming helpers (`stimulize_path`, `js_name`)
  consumed by value classes. The two `module_function` methods documented in §4.5
  are callable directly (`Vident::Stimulus::Naming.stimulize_path(...)`) but the
  module itself is not designed for subclassing or further extension.
- `Vident::Internals::AttributeWriter` — used internally by `root_element_attributes`
  resolution and `child_element`. Takes a collection-per-primitive kwarg hash and
  merges their `to_h` outputs.
- `Vident::Internals::ClassListBuilder` — invoked internally by
  `Vident::Capabilities::ClassListBuilding#class_list_for_stimulus_classes`.
- `Vident::Capabilities::ChildElementRendering`, `Vident::Capabilities::RootElementRendering`,
  `Vident::Capabilities::StimulusMutation`, `Vident::Capabilities::StimulusDraft` —
  included into components; their private/internal methods are not API.
- `Vident::Stimulus::Naming.stimulize_path(path)` — the canonical path → identifier
  helper. (V1's `stimulus_identifier_from_path` on `Vident::Component` was removed in V2.)
