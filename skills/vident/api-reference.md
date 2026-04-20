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
- 14 `as_stimulus_*` helpers — return an HTML-safe `String` of raw `data-*` attributes
  suitable for embedding inside an HTML tag in ERB. Signatures match the corresponding
  `stimulus_*` method (see section 4):
  - Plural: `as_stimulus_controllers`, `as_stimulus_actions`, `as_stimulus_targets`,
    `as_stimulus_outlets`, `as_stimulus_values`, `as_stimulus_params`, `as_stimulus_classes`.
  - Singular: `as_stimulus_controller`, `as_stimulus_action`, `as_stimulus_target`,
    `as_stimulus_outlet`, `as_stimulus_value`, `as_stimulus_param`, `as_stimulus_class`.
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
- No `as_stimulus_*` helpers — Phlex has its own tag DSL; use `child_element` or spread
  `data: { **component.stimulus_target(:name) }` inline.

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
- `clone(overrides = {})` — returns a new instance, `self.class.new(**to_h.merge(**overrides))`.
- `inspect(klass_name = "Component")` — formatted debug string with every prop.
- `id` — `String`, auto-generated from `StableId` if `@id` was nil. The generated form
  is `"#{component_name}-#{StableId.next_id_in_sequence}"`.
- `prop_names` — instance-method alias for the class method.

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

From `Vident::StimulusComponent` (`lib/vident/stimulus_component.rb`):

| Prop                    | Type                                                                                                   | Default                              |
| ----------------------- | ------------------------------------------------------------------------------------------------------ | ------------------------------------ |
| `stimulus_controllers`  | `_Array(_Union(String, Symbol, StimulusController, StimulusControllerCollection))`                     | `[default_controller_path]` unless `no_stimulus_controller`, else `[]` |
| `stimulus_actions`      | `_Array(_Union(String, Symbol, Array, Hash, StimulusAction, StimulusAction::Descriptor, StimulusActionCollection))` | `[]`                                 |
| `stimulus_targets`      | `_Array(_Union(String, Symbol, Array, Hash, StimulusTarget, StimulusTargetCollection))`                | `[]`                                 |
| `stimulus_outlets`      | `_Array(_Union(String, Symbol, StimulusOutlet, StimulusOutletCollection))`                             | `[]`                                 |
| `stimulus_outlet_host`  | `_Nilable(Vident::Component)`                                                                          | `nil`                                |
| `stimulus_values`       | `_Union(_Hash(Symbol, _Any), Array, StimulusValue, StimulusValueCollection)`                           | `{}`                                 |
| `stimulus_params`       | `_Union(_Hash(Symbol, _Any), Array, StimulusParam, StimulusParamCollection)`                           | `{}`                                 |
| `stimulus_classes`      | `_Union(_Hash(Symbol, String), Array, StimulusClass, StimulusClassCollection)`                         | `{}`                                 |

---

## 2. Class-level DSL

All of these live on `Vident::Component`'s class body (via included modules).

- `prop(name, type, **literal_options)` — from the Literal gem. See
  https://literal.fun/ for option details. `default:` may be a callable (`lambda/proc`)
  or an immediate value; callable is required when the default is non-frozen (hash, array).
- `no_stimulus_controller` — sets a class ivar that drops the implied controller from
  the `stimulus_controllers` default. Use when the component is purely presentational
  and needs no paired `_controller.js`.
- `stimulus_controller?` — `Boolean`, `true` by default; becomes `false` after a
  `no_stimulus_controller` declaration.
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
- `stimulus(&block)` — the DSL entry point. Opens a `Vident::StimulusBuilder` block
  evaluator. See section 3.

Not intended for application code:

- `stimulus_dsl_attributes(component_instance)` — returns the DSL's emitted attribute
  hash for a specific instance (so procs resolve against it).
- `stimulus_dsl_builder` — the builder accessor; `protected`, used only by inheritance
  merging.

---

## 3. `stimulus do ... end` block

Evaluated by `Vident::StimulusBuilder` (`lib/vident/stimulus_builder.rb`). Multiple
`stimulus do` blocks on the same class accumulate. A subclass's blocks are merged with
every parent's blocks on first access (subclass entries appended to positional kinds;
subclass wins on conflicts for keyed kinds).

Every DSL method returns `self` so calls chain — but there's no real reason to chain
inside a `do ... end` block. All methods accept procs anywhere a value is expected;
procs are evaluated via `instance_exec` on the component instance at render time.

### Methods on the builder

- `actions(*entries)` — positional. Each entry is one of:
  - `Symbol`                         → `implied#<jsSymbol>`
  - `[Symbol, Symbol]`               → `<event>-><implied>#<jsMethod>`
  - `[Symbol, String, Symbol]`       → `<event>-><stimulized-path>#<jsMethod>`
  - `String` containing `#`          → parsed literally (pass-through); `event->ctrl#method`
    or `ctrl#method` supported.
  - `Hash` (desugared to a `Descriptor`) — keys: `:method` (required), `:event`,
    `:controller`, `:options` (`Array<Symbol>`), `:keyboard` (`String`),
    `:window` (`Boolean`). See section 4.2 for the `options:` whitelist.
  - `Vident::StimulusAction::Descriptor` — typed equivalent of the Hash form.
  - `Proc` — evaluated at render time; `nil` / `false` return drops the entry.
- `targets(*entries)` — positional. Each entry is one of:
  - `Symbol`                         → target on the implied controller
  - `String`                         → pass-through target name
  - `[String, Symbol]`               → target on the named cross-controller
  - `Proc` — evaluated at render time; `nil` drops the entry.
- `values(**kvs)` — keyed. Values may be `String`/`Number`/`Boolean` (stringified),
  `Array`/`Hash` (JSON-serialised), `Vident::StimulusNull` (emits literal `"null"`),
  or a `Proc` resolving to any of the above. A resolved `nil` omits the attribute.
- `params(**kvs)` — keyed. Same serialisation rules as `values`.
- `classes(**kvs)` — keyed. Value is `String` or `Array(String)`; array joined with
  single space. A `Proc` may resolve to either. A resolved `nil` omits the attribute.
- `outlets(positional_hash = nil, **kvs)` — keyed. Value is a `String` CSS selector.
  `outlets({"admin--users" => ".sel"})` accepts a positional Hash so identifiers
  containing `--` (not valid Ruby kwarg keys) work. Procs are **not** supported here
  — the builder skips proc resolution for outlets; pass cross-controller outlets via
  the `stimulus_outlets:` prop or `root_element_attributes` instead.
- `values_from_props(*prop_names)` — keyed, sidecar to `values`. Mirrors each prop's
  current `@ivar` value at render time. Prop names are Symbols.

No `controllers` method exists in the DSL. Controllers are set via the `stimulus_controllers:`
prop, `root_element_attributes[:stimulus_controllers]`, or `no_stimulus_controller`.

### What the builder emits

`to_attributes(component_instance)` returns a Hash keyed by `:stimulus_actions`,
`:stimulus_targets`, `:stimulus_values`, `:stimulus_params`, `:stimulus_classes`,
`:stimulus_outlets`, plus `:stimulus_values_from_props` (an Array of prop-name Symbols)
if `values_from_props` was used. Only primitives with entries are included.

---

## 4. Instance-level Stimulus helpers (`Vident::StimulusAttributes`)

Included into every component via `StimulusComponent`. File:
`lib/vident/stimulus_attributes.rb`.

### 4.1 Plural parsers `stimulus_<plural>(*args)`

Seven methods: `stimulus_controllers`, `stimulus_actions`, `stimulus_targets`,
`stimulus_outlets`, `stimulus_values`, `stimulus_params`, `stimulus_classes`.

Each returns a collection object (`StimulusActionCollection`, etc.) whose `#to_h`
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

Each singular builder accepts the set of argument shapes its `parse_arguments`
implementation supports. Raises `ArgumentError` on unsupported shape or arity.

- `stimulus_controller(*)` — 0 or 1 arg. 0 args returns the implied controller; 1 arg
  is a controller path `String`/`Symbol`.
- `stimulus_action(*)` — 1/2/3 args. See `StimulusAction::parse_arguments` for all
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

**Splat asymmetry vs DSL.** The DSL's `actions [:click, :handle]` treats the Array as
one action descriptor (event + method). The mutator `add_stimulus_actions([:click, :handle])`
splats the Array and treats it as two separate symbol actions. To pass an
Array-shaped single action through the mutator, wrap with a pre-built value
(`stimulus_action(:click, :handle)`) or double-wrap (`[[:click, :handle]]`).

### 4.4 Value serialisation (`StimulusAttributeBase#serialize_value`)

`Array` and `Hash` → JSON. Everything else → `to_s`. `Vident::StimulusNull.to_s`
returns the literal string `"null"`. A `nil` reaches the DSL/prop layer and
is dropped by `StimulusBuilder#resolve_hash_filtering_nil` before serialisation, so
the data attribute is omitted (not emitted as empty).

### 4.5 Name-shaping helpers

- `StimulusAttributeBase.stimulize_path(path)` — `"admin/users"` → `"admin--users"`;
  each path segment is `dasherize`d and segments joined with `--`.
- `StimulusAttributeBase.js_name(name)` — `camelize(:lower)`; `:my_thing` → `"myThing"`.

Both also available as private instance methods on any `StimulusAttributeBase` subclass.

### 4.6 Scoped events

- Class method `stimulus_scoped_event(event)` — returns `Symbol`
  `:"<component_name>:<jsName>"`. **Call on the dispatcher's class**, not on the
  listener's.
- Class method `stimulus_scoped_event_on_window(event)` — same with `@window` suffix.
- Both also exist as instance methods that delegate to the class method.

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
  `Vident::Phlex::HTML::VALID_TAGS`; unknown tags raise `ArgumentError`.

---

## 7. `Vident::StimulusBuilder` primitives

For use in advanced cases (passing typed descriptors across components, building
reusable shared helpers). File: `lib/vident/stimulus_action.rb`.

### `Vident::StimulusAction::Descriptor`

A `::Literal::Data` value object with the same shape as the Hash form accepted by
`actions`:

| Prop          | Type                                  | Default |
| ------------- | ------------------------------------- | ------- |
| `method`      | `_Union(Symbol, String)`              | —       |
| `event`       | `_Nilable(_Union(Symbol, String))`    | `nil`   |
| `controller`  | `_Nilable(String)`                    | `nil`   |
| `options`     | `_Array(Symbol)`                      | `[]`    |
| `keyboard`    | `_Nilable(String)`                    | `nil`   |
| `window`      | `_Boolean`                            | `false` |

### `Vident::StimulusNull`

Frozen singleton object. `inspect` → `"Vident::StimulusNull"`; `to_s` → `"null"`.
See SKILL.md §1.4 for the usage contract.

### Collection classes

Each primitive has a `StimulusXCollection < StimulusCollectionBase`:

- Base methods: `<<(item)`, `to_a`, `to_h` (abstract; each subclass implements),
  `empty?`, `any?`, `merge(*others)`, `self.merge(*collections)`.
- `StimulusActionCollection#to_h` → `{action: "…"}` with entries joined by space.
- `StimulusControllerCollection#to_h` → `{controller: "…"}` with non-empty entries
  joined by space.
- `StimulusTargetCollection#to_h` → one key per controller-target attribute;
  multiple targets on the same controller are joined with a single space.
- `StimulusValueCollection`, `StimulusParamCollection`, `StimulusClassCollection` →
  merged per-data-attribute hash.
- `StimulusOutletCollection` → same.

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
  on every call. Raises `StandardError` if the host class has no
  `cache_component_modified_time` (base classes provide it).

### Instance methods

- `component_modified_time` — delegates to the class method.
- `cacheable?` — `respond_to?(:cache_key)`.
- `cache_key` — defined when `with_cache_key` has been called; returns
  `"#{class.name}/#{cache_keys_for_sources(...).join("/")}"`, optionally suffixed with
  `ENV["RAILS_CACHE_ID"]`. Raises `StandardError` if the computed key is blank.
- `cache_key_modifier` — returns `ENV["RAILS_CACHE_ID"]` (may be nil).

`with_cache_key` without any attrs is valid — the call still appends
`:component_modified_time` and `:to_h`, so the cache key reflects the template mtime
plus the component's full prop hash.

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

`Vident::ClassListBuilder` invokes `tailwind_merger.merge(class_string)` automatically
at the final stage of its `build(...)` call when a merger is provided. No per-component
opt-in is required beyond adding the gem to the Gemfile.

---

## 11. `class_list_for_stimulus_classes`

Instance method on every component. File: `lib/vident/component_class_lists.rb`.

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
  Loads `Vident::Generators::InstallGenerator`.
- `Vident::Phlex::Engine`, `Vident::ViewComponent::Engine` — thin Rails::Engine
  subclasses from the sub-gems; no explicit initializer.

---

## 13. What's not in the public API

The following show up in `lib/vident/*.rb` but are explicitly internal:

- `Vident::Stimulus::PRIMITIVES`, `Vident::Stimulus::Primitive`,
  `Vident::Stimulus::KeyedPrimitive`, `Vident::Stimulus::PositionalPrimitive`,
  `Vident::Stimulus::Naming` — the registry that drives every plural parser,
  mutator, and DSL primitive. Don't rely on these modules in application code.
- `Vident::StimulusDataAttributeBuilder` — used internally by `root_element_attributes`
  resolution and `child_element`. Takes a collection-per-primitive kwarg hash and
  merges their `to_h` outputs.
- `Vident::ClassListBuilder` — invoked internally by `ComponentClassLists#render_classes`.
- `Vident::ComponentAttributeResolver`, `Vident::ComponentClassLists`,
  `Vident::StimulusHelper`, `Vident::ChildElementHelper`, `Vident::StimulusComponent` —
  included into components; their private/internal methods are not API.
- `Vident::StimulusComponent.stimulus_identifier_from_path(path)` — still callable
  but kept only as a back-compat shim for `StimulusAttributeBase.stimulize_path`.
