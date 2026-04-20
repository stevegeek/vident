---
name: Vident
description: This skill should be used when writing or editing Rails view components in a project that depends on `vident`, `vident-view_component`, or `vident-phlex` — i.e. any class inheriting from `Vident::ViewComponent::Base` or `Vident::Phlex::HTML`, any paired `*_component_controller.js` Stimulus file next to such a component, or the `stimulus_*` props / `stimulus do ... end` DSL / `child_element` / `root_element` / `class_list_for_stimulus_classes` / `Vident::StimulusNull` / `Vident::StableId` APIs. It also covers the `bin/rails generate vident:install` initializer and the per-request ID seeding it installs on `ApplicationController`.
version: 0.2.0
---

# Vident

Vident is a thin layer on top of ViewComponent / Phlex that gives a component three things Stimulus alone does not: **typed props** (via Literal), a **declarative Ruby DSL** that compiles down to the `data-*` attributes Stimulus expects, and **first-class outlets** including a host/child self-registration pattern. Every component also comes with a **stable, deterministic element id** system so HTML output is etag-stable across requests.

A Vident component is always a class with props, a single `root_element`, and (optionally) a `stimulus do ... end` block that declares the controllers, actions, targets, values, classes and outlets its paired JavaScript file needs.

> **Going deeper.** This file is the everyday reference. For end-to-end walkthroughs (dashboard, forms, slot-based parent/child wiring, ERB helper comparisons), read [`examples.md`](examples.md). For the exhaustive public-API spec (every signature, raise-condition, and argument shape), read [`api-reference.md`](api-reference.md).

---

## 1. Stimulus → Vident mapping

For each Stimulus primitive: first the Stimulus contract, then the Ruby declaration that produces it, then the HTML it emits.

Identifier conventions used throughout this doc:

- A component class `Foo::BarComponent` has **stimulus identifier** `foo--bar-component` (namespace separators become `--`, CamelCase becomes kebab-case).
- The **implied controller** inside a component's DSL is that component's own identifier. Every DSL entry binds to it unless explicitly redirected.
- A Ruby symbol name is `.camelize(:lower)`-d before being emitted (so `:my_thing` → `myThing` in JS).
- A Ruby `"path/to/thing"` string is `stimulize_path`-d before being emitted (so `"admin/users"` → `admin--users`).

### 1.1 Controllers / identifiers

Stimulus: `data-controller="foo bar"` attaches one instance each of `foo` and `bar` to the element and its subtree.

Vident: every component attaches *itself* as a controller on its root element by default. Extra controllers come from the `stimulus_controllers:` prop or `root_element_attributes`.

```ruby
class Admin::UserCardComponent < Vident::Phlex::HTML
  # No DSL needed for the implied controller — it's automatic.
end
```

```html
<div class="admin--user-card-component" data-controller="admin--user-card-component" id="...">…</div>
```

To attach extra controllers, or to opt out:

```ruby
class Foo::BarComponent < Vident::ViewComponent::Base
  no_stimulus_controller                          # don't emit the implied `data-controller`

  # or keep the implied one AND add more:
  def root_element_attributes
    { stimulus_controllers: ["other/widget", :tooltip] }
  end
end
```

Cross-controller references elsewhere (actions/targets/values/classes/outlets) use the `"path/to/controller"` **string** form — Vident stimulizes it for you.

### 1.2 Actions

Stimulus descriptor: `event->controller#method`, with optional modifiers (`:once`, `:prevent`, `keydown.ctrl+a`, `@window`, etc.). Stimulus encodes them as space-separated tokens in `data-action="..."`.

Vident `actions` DSL entries (all of these work inside `stimulus do ... end`):

| Ruby                                        | Emits                                              |
| ------------------------------------------- | -------------------------------------------------- |
| `:my_thing`                                 | `implied#myThing` (no explicit event)              |
| `[:click, :my_thing]`                       | `click->implied#myThing`                           |
| `[:click, "other/ctrl", :my_thing]`         | `click->other--ctrl#myThing`                       |
| `"click->other--ctrl#myThing"`              | pass-through, parsed into its parts                |
| `{event: :click, method: :submit, options: [:once, :prevent]}` | `click:once:prevent->implied#submit` |
| `Vident::StimulusAction::Descriptor.new(event: :click, method: :submit, options: [:once])` | same — typed data object, Hash is sugar |
| `-> { [:click, :my_thing] if @editable }`   | proc, evaluated in component instance; `nil`/`false` returns drop the entry |

**Modifiers via the Hash / Descriptor form.** Accepted keys on the hash (and the `Descriptor` data class):

| Key          | Type              | Emits                                    |
| ------------ | ----------------- | ---------------------------------------- |
| `event:`     | Symbol / String   | prepends `event->`                       |
| `method:`    | Symbol / String   | the `#method` part (required)            |
| `controller:`| String path       | routes to another controller             |
| `options:`   | `Array<Symbol>` from `:once`, `:prevent`, `:stop`, `:passive`, `:"!passive"`, `:capture`, `:self` | `:once:prevent…` suffix on event |
| `keyboard:`  | String like `"ctrl+a"` | `.ctrl+a` suffix on event filter    |
| `window:`    | Boolean           | `@window` suffix on event                |

Unknown option symbols raise `ArgumentError`. Use the Hash form for the common case; use `Vident::StimulusAction::Descriptor.new(...)` when you want a typed, passable value object (reusable across components, shared helpers).

```ruby
actions({event: :keydown, method: :on_escape, keyboard: "esc", options: [:prevent]})
# => keydown.esc:prevent->implied#onEscape

actions({event: :click, method: :handle, controller: "dialog/open", window: true})
# => click@window->dialog--open#handle
```

```ruby
stimulus do
  actions :toggle                                     # implied#toggle
  actions [:click, :submit], [:input, :on_input]      # multiple entries
  actions [:click, "dialog/open", :show]              # cross-controller
end
```

Emits (combined on one element):

```html
data-action="implied#toggle click->implied#submit input->implied#onInput click->dialog--open#show"
```

The same shapes are accepted by the `stimulus_actions:` prop, `child_element(stimulus_action: …)`, and the `as_stimulus_action(s)` ERB helpers.

**Scoped events on window.** To listen for an event *dispatched by another component*, reference the dispatcher's class:

```ruby
actions -> { [OtherComponent.stimulus_scoped_event_on_window(:data_ready), :handle_ready] }
```

`OtherComponent.stimulus_scoped_event_on_window(:data_ready)` returns the symbol `:"other-component:dataReady@window"`. The action parser treats the whole symbol as the event name, so this yields `data-action="other-component:dataReady@window->implied#handleReady"`. On the dispatcher's JS side, `this.dispatch("dataReady", { target: window })` produces exactly that event type because Stimulus prefixes dispatches with the dispatcher's identifier. **Always call the class method on the dispatcher, never on the listener.**

There is also `stimulus_scoped_event(:name)` (no `@window`) when the event bubbles naturally and doesn't need a global listener.

### 1.3 Targets

Stimulus: `data-<identifier>-target="name"` on an element exposes `this.nameTarget` / `this.nameTargets` / `this.hasNameTarget` in the JS controller. CamelCase names in JS / kebab-case in HTML.

Vident `targets` DSL:

| Ruby                           | Emits                                              |
| ------------------------------ | -------------------------------------------------- |
| `:button`                      | `data-implied-target="button"` on the root         |
| `["other/ctrl", :row]`         | `data-other--ctrl-target="row"` on the root        |
| Same shapes on `child_element` | `data-implied-target="..."` on the child           |

```ruby
stimulus do
  targets :body, :footer
end

# and in the view:
card.child_element(:button, stimulus_target: :promote_button) { "Promote" }
# => <button data-implied-target="promoteButton">Promote</button>
```

A proc form `-> { cond ? :foo : nil }` is supported; returning `nil` drops the entry.

### 1.4 Values

Stimulus: `data-<identifier>-<name>-value="..."` with types `String | Number | Boolean | Object | Array`. In JS: `this.nameValue` / `this.nameValue=` / `this.hasNameValue`. Name is camelCase in JS, kebab-case in HTML.

Vident has three entry points, all composable:

**(a) `values(key: value, …)` in the DSL.** Static values, or procs evaluated in the component instance at render time:

```ruby
stimulus do
  values initial_open: false,
         status_label: -> { @status.to_s.capitalize }
end
```

**(b) `values_from_props :a, :b, …` in the DSL.** Mirrors a typed prop straight through — the emitted value is the prop's current `@ivar`.

```ruby
prop :release_id, Integer
stimulus do
  values_from_props :release_id
end
# => data-implied-release-id-value="42"
```

**(c) `stimulus_values:` prop / `child_element(stimulus_value(s): …)`.** Array form required for cross-controller:

```ruby
stimulus_values: [
  [:foo, "bar"],                        # implied-foo-value="bar"
  ["other/ctrl", :baz, 42],             # other--ctrl-baz-value="42"
]
```

Serialization: Booleans/Numbers stringify directly; `Array` / `Hash` serialize as JSON. `String` stringifies.

**The nil rule.** A `nil` resolved value (from a proc or static) **omits the data attribute entirely**, letting Stimulus use its per-type default. Never rely on `nil` becoming `""`. If you need explicit JSON `null` on the JS side for an `Object`- or `Array`-typed value, return the `Vident::StimulusNull` sentinel, which serializes to the literal string `"null"` that Stimulus's Object parser feeds to `JSON.parse`:

```ruby
values release: -> { @selected ? @selected.to_h : Vident::StimulusNull }
```

Use `StimulusNull` *only* for Object/Array values — for `String`/`Number`/`Boolean` it reads as garbage ("null" / NaN / truthy).

### 1.5 Value-change callbacks

Stimulus: defining `fooValueChanged(newValue, previousValue)` on a controller fires once on connect and on every subsequent change to `this.fooValue`.

Vident: **pure JS, no Ruby-side hook.** Vident only emits the attribute — the callback is written in the paired `_controller.js`. See section 7.

### 1.6 Classes

Stimulus: `data-<identifier>-<name>-class="foo bar"` exposes `this.nameClass` (first token) / `this.nameClasses` (array) in the controller. Classes are applied manually via `classList` in JS.

Vident `classes` DSL:

```ruby
stimulus do
  classes loading: "opacity-50 cursor-wait",          # static
          status: -> {                                # proc
            case @status
            when :deployed then "border-green-500 bg-green-50"
            when :failed   then "border-red-500 bg-red-50"
            else                "border-yellow-400 bg-yellow-50"
            end
          }
end
```

Emits:

```html
data-implied-loading-class="opacity-50 cursor-wait"
data-implied-status-class="border-green-500 bg-green-50"
```

These only tell the JS controller *which* classes to toggle; they do **not** apply them to the first render. For SSR initial state, inline the resolved value into `class=` via `class_list_for_stimulus_classes(:status, :loading)` (see section 4).

### 1.7 Outlets

Stimulus: `data-<identifier>-<outlet-name>-outlet="<css-selector>"` attaches matching controller instances as `this.nameOutlet` / `this.nameOutlets` / `this.nameOutletElement(s)` / `this.hasNameOutlet`. Outlet names are the kebab-case *identifier* of the outlet controller.

Vident has three forms.

**(a) DSL on the root:**

```ruby
stimulus do
  outlets modal: ".modal", user_status: ".online-user"
  outlets({"admin--users" => ".admin-user"})   # positional-hash for names containing `--`
end
```

**(b) `stimulus_outlets:` prop / `root_element_attributes` / `child_element(stimulus_outlet(s): …)`:**

```ruby
stimulus_outlets: [
  [:modal, ".modal"],                       # implied controller
  ["admin/users", :row, ".user-row"],       # cross-controller
  :user_status,                             # auto-selector: [data-controller~=user-status]
  other_component_instance,                 # #<id> [data-controller~=<other identifier>]
]
```

**(c) Child self-registers on a host via `stimulus_outlet_host:`.** Every Vident component inherits a `stimulus_outlet_host` prop. Passing a parent component at render time calls `host.add_stimulus_outlets(self)` in `prepare_stimulus_collections`, so the host's root gets the outlet attribute without enumerating children in its DSL:

```ruby
render PageComponent.new do |page|
  @releases.each do |r|
    render ReleaseCardComponent.new(**r, stimulus_outlet_host: page)
  end
end
```

The host's JS still declares the outlet name in `static outlets = ["release-card-component"]`.

Emits on host root (example):

```html
data-page-component-release-card-component-outlet="#page-123 [data-controller~=release-card-component]"
```

### 1.8 Lifecycle callbacks

Stimulus: `initialize()`, `connect()`, `disconnect()`, `<name>TargetConnected(el)`, `<name>TargetDisconnected(el)`, `<name>OutletConnected(ctrl, el)`, `<name>OutletDisconnected(ctrl, el)`.

Vident: **pure JS, no Ruby-side hook.** Write them in the paired `_controller.js`. Vident's `after_component_initialize` is a Ruby-side post-props-assigned hook on the component — unrelated to the Stimulus lifecycle.

### 1.9 Action params

Stimulus: `data-<identifier>-<name>-param="value"` lives on an element. Any action handler whose event fires on or bubbles through that element reads the values as `event.params.<name>` (auto-typecast to Number/String/Object/Boolean).

Vident has three entry points, all mirroring `values`:

**(a) `params(key: value, …)` in the DSL.** Static values or procs evaluated in the component instance:

```ruby
stimulus do
  actions [:click, :promote]
  params release_id: -> { @release_id }, kind: "promote"
end
# => data-implied-release-id-param="42" data-implied-kind-param="promote"
```

**(b) `stimulus_params:` prop / `child_element(stimulus_params: …)`.** The common "one button, one action, params for that action" case lives here — co-located with the `stimulus_action:` it informs:

```ruby
card.child_element(:button,
  stimulus_action: [:click, :promote],
  stimulus_params: { release_id: @release_id, kind: "promote" })
```

**(c) Array form on the prop for cross-controller:**

```ruby
stimulus_params: [
  [:release_id, 42],              # implied-release-id-param="42"
  ["other/ctrl", :scope, "full"], # other--ctrl-scope-param="full"
]
```

**Element-scoped, not action-scoped.** In Stimulus, params live on the element, not on an individual action. Multiple actions on the same element share the same params. Vident's DSL matches this: `params` is a sibling of `actions`, not nested inside it.

Inline helper (ERB): `as_stimulus_param(:release_id, 42)` / `as_stimulus_params({release_id: 42})`.

---

## 2. Component scaffolding

Pick the right base class:

- **ViewComponent:** `class Foo::BarComponent < Vident::ViewComponent::Base`
- **Phlex:** `class Foo::BarComponent < Vident::Phlex::HTML`

Both include `Vident::Component`, which brings in the Stimulus DSL, class-list builder, caching, and child-element helper.

### Props

Defined with the Literal DSL:

```ruby
prop :title, String                                   # required
prop :count, Integer, default: 0                      # with default
prop :url, _Nilable(String)                           # optional / nilable
prop :variant, _Union(:primary, :secondary), default: :primary
prop :items, _Array(Hash), default: -> { [] }         # callable defaults must be lambdas
prop :open, _Boolean, default: false                  # generates an `open?` predicate
```

Props become `@ivar`s at init time. To also expose a reader method, declare the prop with `reader: :public`.

### Built-in props every component inherits

From `Vident::Component`:

- `element_tag` — `Symbol`, root tag type, default `:div`.
- `id` — `String?`. Auto-generated via `StableId` if omitted. The generated form is `<component-name>-<sequence>`.
- `classes` — `String | Array(String)`. Appended to the root element's `class=`.
- `html_options` — `Hash`. Merged onto the root element; highest precedence.

From `Vident::StimulusComponent`:

- `stimulus_controllers` — `Array(String | Symbol | StimulusController | Collection)`. Defaults to `[default_controller_path]` unless `no_stimulus_controller` is declared.
- `stimulus_actions`, `stimulus_targets`, `stimulus_values`, `stimulus_classes`, `stimulus_outlets` — Array / Hash props matching the shapes described in section 1.
- `stimulus_outlet_host` — optional `Vident::Component`; activates child→host outlet self-registration.

### `root_element` and `root_element_attributes`

Every component renders **exactly one** root element via `root_element`. Override `root_element_attributes` (returns a Hash) to set the tag, add HTML options, or push stimulus attributes declaratively:

```ruby
private

def root_element_attributes
  {
    element_tag: @url ? :a : :button,          # default :div
    html_options: { href: @url }.compact,
    # stimulus_actions:, stimulus_targets:, stimulus_values:, stimulus_classes:,
    # stimulus_controllers:, stimulus_outlets: — all accepted here.
  }
end
```

`root_element_attributes` attributes have **higher precedence** than `stimulus do ... end` DSL entries, so a hardcoded `html_options[:class]` wins over `classes:` passed at render.

Phlex template:

```ruby
def view_template
  root_element(class: "space-y-4") do |component|
    h2 { @title }
    component.child_element(:button, stimulus_action: [:click, :promote]) { "Promote" }
  end
end
```

ViewComponent template (`.html.erb`):

```erb
<%= root_element(class: "space-y-4") do |component| %>
  <h2><%= @title %></h2>
  <%= component.child_element(:button, stimulus_action: [:click, :promote]) { "Promote" } %>
<% end %>
```

### `child_element`

Renders a child tag with `stimulus_*` kwargs compiled into `data-*` attributes. Singular (`stimulus_action:`, `stimulus_target:`, etc.) take one entry; plural (`stimulus_actions:`, etc.) take an Enumerable. Passing a non-Enumerable to a plural raises. Other kwargs pass through as HTML options.

```ruby
component.child_element(
  :button,
  stimulus_action: [:click, :submit],
  stimulus_target: :submit_button,
  stimulus_value: [:label, "Go"],
  type: "button",
  class: "rounded bg-blue-600 text-white"
) { "Go" }
```

### Inline `as_stimulus_*` helpers (ViewComponent / ERB)

When handwriting HTML inside ERB instead of using `child_element`, emit just the data attributes with the inline helpers on the component:

```erb
<input <%= component.as_stimulus_target(:search) %> type="search">
<button <%= component.as_stimulus_action([:click, :greet]) %>>Greet</button>
<div <%= component.as_stimulus_values(%i[count label]) %>></div>
```

Plural (`as_stimulus_targets`, `as_stimulus_actions`, `as_stimulus_values`, `as_stimulus_classes`, `as_stimulus_outlets`, `as_stimulus_controllers`) and singular variants exist for every attribute kind. These helpers are defined on `Vident::ViewComponent::Base`; for Phlex, use `child_element` or compose directly.

---

## 3. `stimulus do ... end` block

Opens a `Vident::StimulusBuilder` instance scoped to the class. It supports `actions`, `targets`, `values`, `values_from_props`, `classes`, `outlets`. Multiple `stimulus do` blocks on the same class are merged; a subclass's block is merged with its superclass's (subclass entries appended, values/classes/outlets merged by key, subclass wins on conflicts).

Procs passed anywhere in the DSL are evaluated via `instance_exec` on the **component instance** at render time, so they see `@ivars` and public/private instance methods.

---

## 4. Classes and SSR initial state

The `classes` DSL only writes `data-*-class` attributes for the JS to read. The initial DOM is still whatever you pass to `class:`. To inline the resolved stimulus-class values into the first render, call `class_list_for_stimulus_classes(*names)` from the view and interpolate it:

```ruby
# On the root element:
root_element(class: "base-classes #{class_list_for_stimulus_classes(:status)}")

# On a child element:
card.child_element(:span, class: "ml-4 #{class_list_for_stimulus_classes(:status)}")
```

It returns a space-joined String of the resolved classes for the named stimulus-class entries only. The builder deduplicates and (if `tailwind_merge` is available) Tailwind-merges the whole class list on the root element.

### Class-list precedence on root

From lowest to highest:

1. `component_name` is always included as the first class (so every instance carries `foo--bar-component` for CSS hooks).
2. `root_element_classes` (override on the class) — only if no `root_element_attributes[:classes]` / `html_options[:class]`.
3. `root_element_attributes[:classes]` — only if no `html_options[:class]`.
4. `root_element(class: …)` — passed in the template.
5. `html_options[:class]` (from the prop) — **highest**.
6. `classes:` (the prop) is **always** appended on top.

---

## 5. StableId: deterministic element IDs

`Vident::StableId.strategy` is a callable that takes the current-thread's sequence generator and returns the next id. Two built-in strategies:

- `Vident::StableId::STRICT` — raises if no generator is set. Use in development/production.
- `Vident::StableId::RANDOM_FALLBACK` — falls back to `Random.hex(16)` when no generator is set. Use in test/previews/mailers.

`bin/rails generate vident:install` writes `config/initializers/vident.rb`:

```ruby
Vident::StableId.strategy = Rails.env.test? ?
  Vident::StableId::RANDOM_FALLBACK :
  Vident::StableId::STRICT
```

…and patches `ApplicationController`:

```ruby
before_action { Vident::StableId.set_current_sequence_generator(seed: request.fullpath) }
after_action  { Vident::StableId.clear_current_sequence_generator }
```

Same URL → same seed → same IDs across requests, so etags are stable.

### Rendering outside a request

Jobs, mailers, script previews, and Metal endpoints don't hit `ApplicationController`. Wrap with:

```ruby
Vident::StableId.with_sequence_generator(seed: "some-unique-key") { render ... }
```

…or set the strategy to `RANDOM_FALLBACK` for that context. A bare `StableId::GeneratorNotSetError` in production means the `before_action` was bypassed.

---

## 6. Component-level extras

- **`after_component_initialize`** — override in your component; runs after props are assigned and Vident has prepared its stimulus collections. Don't override `after_initialize` unless you `super` — Literal calls it to wire everything up.
- **`component_name` / `stimulus_identifier`** — class method and instance method; the kebab-case/`--`-separated identifier. Used for outlet auto-selectors, scoped event names, and the default class on the root.
- **Caching** (`include Vident::Caching` + `with_cache_key :attr1, :attr2`) — declares attributes that feed `cache_key`. Combined with a template mtime so edits bust the cache. `depends_on(OtherComponent, …)` chains subcomponent mtimes into the key.
- **`clone(overrides = {})`** — returns a new instance with merged props.
- **Phlex tag safety** — `Vident::Phlex::HTML` validates every `child_element` tag name against a whitelist; passing an unknown tag raises.

---

## 7. JavaScript side of the handshake

Each component has a paired `_controller.js` sitting next to the Ruby file:

```
app/components/dashboard/card_component.rb
app/components/dashboard/card_component_controller.js
```

Stimulus auto-registration (`eagerLoadControllersFrom("app_components", application)` in your `application.js`) maps the file's location under `app/components/` to the identifier Vident uses: `dashboard--card-component`. Subclasses of `Vident::ViewComponent::Base` / `Vident::Phlex::HTML` don't need any extra wiring.

Typical controller:

```js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { name: String, releaseId: Number, status: String }
  static targets = ["promoteButton", "cancelButton"]
  static outlets = ["dashboard--release-card-component"]
  static classes = ["status"]

  // Lifecycle
  connect()                        { /* element in DOM */ }
  disconnect()                     { /* element removed */ }
  statusValueChanged(n, prev)      { /* reactive */ }
  promoteButtonTargetConnected(el) { /* target appeared */ }
  dashboardReleaseCardComponentOutletConnected(ctrl, el) { /* outlet attached */ }

  promote() {
    this.promoteButtonTarget.disabled = true
    this.dispatch("promoted", {
      target: window,
      detail: { releaseId: this.releaseIdValue },
    })
  }
}
```

### Dispatch / scoped event mapping

`this.dispatch("foo", { target: window, detail: … })` emits an event of type `<this-identifier>:foo` on `window`. The matching Ruby-side listener is:

```ruby
actions -> { [OtherComponent.stimulus_scoped_event_on_window(:foo), :handle_foo] }
```

…where `OtherComponent` is the *dispatching* component class. If the event doesn't need `@window` (it bubbles naturally through the DOM), use `stimulus_scoped_event(:foo)` instead.

### Outlet lifecycle gotcha

Inside `<name>OutletConnected`, **do not iterate `this.<name>Outlets`**. Stimulus attaches outlet controllers one at a time, and the plural getter warns for every selector match whose controller hasn't yet attached. Iterate on explicit events (filter changes, user actions) by which time all siblings have connected.

---

## 8. Recipes

One-liners per task. For worked end-to-end versions (dashboard with outlets, slot trigger, ERB variants) see [`examples.md`](examples.md).

**Click handler on the root** — `stimulus do; actions [:click, :select]; end` + `select(event) {…}` in JS.

**Click handler on a child button** — `card.child_element(:button, stimulus_action: [:click, :promote]) { "Promote" }`.

**Expose a prop to JS**:
```ruby
prop :release_id, Integer
stimulus do
  values_from_props :release_id
end
```
```js
static values = { releaseId: Number }
promote() { console.log(this.releaseIdValue) }
```

**Toggle a class from JS**:
```ruby
stimulus do
  classes hidden: "opacity-0 pointer-events-none"
end
```
```js
static classes = ["hidden"]
hide() { this.element.classList.add(...this.hiddenClasses) }
```
SSR initial state: `root_element(class: class_list_for_stimulus_classes(:hidden))`.

**Connect two components via outlets** — parent declares the outlet name, child self-registers via `stimulus_outlet_host: parent` at render time. Parent JS: `static outlets = ["child-component"]` + `childComponentConnected(ctrl, el) {…}`.

**Write a value on a different controller** — DSL: `values([["other/ctrl", :foo, "bar"]])`. Prop: `stimulus_values: [["other/ctrl", :foo, "bar"]]`.

**React to another component's dispatched event**:
```ruby
stimulus do
  actions -> { [DispatcherComponent.stimulus_scoped_event_on_window(:updated), :on_updated] }
end
```
```js
// in dispatcher_controller.js
this.dispatch("updated", { target: window, detail: { /*…*/ } })
// in listener_controller.js
onUpdated(event) { /* event.detail */ }
```

**Render outside a request** — `Vident::StableId.with_sequence_generator(seed: job.id) { render … }`.

**Opt out of the implied controller** — declare `no_stimulus_controller` in the class body.

**Change the root tag conditionally**:
```ruby
def root_element_attributes
  {
    element_tag: @url ? :a : :button,
    html_options: { href: @url, type: @url ? nil : "button" }.compact,
  }
end
```

---

## 9. Key source files

For the exhaustive public-API listing (every method signature, argument shape, and raise-condition, verified against current code), see [`api-reference.md`](api-reference.md). The files below are useful when you need to read the implementation itself.

- `lib/vident/stimulus_builder.rb` — DSL evaluator.
- `lib/vident/stimulus_attributes.rb` — parser for every `stimulus_*` input shape + `as_stimulus_*` helpers' backing.
- `lib/vident/stimulus_{action,target,value,outlet,class,controller}.rb` — value objects; read `parse_arguments` to learn the argument shapes.
- `lib/vident/child_element_helper.rb` — `child_element` kwargs and validation.
- `lib/vident/component_attribute_resolver.rb` — how DSL, props, and `root_element_attributes` compose at render time.
- `lib/vident/component_class_lists.rb` — `class_list_for_stimulus_classes` / `render_classes`.
- `lib/vident/stable_id.rb` — the StableId strategy system.
- `lib/vident/stimulus_null.rb` — the StimulusNull sentinel.
- `lib/vident/view_component/base.rb` / `lib/vident/phlex/html.rb` — framework-specific `root_element` / `child_element` backings and (ViewComponent only) `as_stimulus_*` helpers.
- `test/dummy/app/components/dashboard/` — canonical multi-component example (outlets, scoped events, `StimulusNull`, dynamic classes, `values_from_props`, `class_list_for_stimulus_classes`, full JS side).
