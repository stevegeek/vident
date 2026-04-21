
# Change Log
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).


## [2.0.0] - 2026-04-21

Vident 2.0 is a ground-up rearchitecture of the DSL, attribute resolution, and composition model. The public shape of `stimulus do ... end`, `root_element`, `child_element`, outlets, props, and the `stimulus_*:` prop/kwarg API is preserved for common cases, but several internals and a handful of edge-case behaviours changed. See `doc/reviews/v1-gotchas.md` for the full list of fixed gotchas; the highlights are below.

### Breaking

- **Namespace consolidation.** The `Vident2::*` namespace used during side-by-side development has been removed. Everything now lives under `Vident::*` directly: `Vident::Component`, `Vident::Capabilities::*`, `Vident::Phlex::HTML`, `Vident::ViewComponent::Base`, `Vident::Stimulus::*` (value classes), `Vident::Internals::*` (DSL/Resolver/Plan). Upgrade path is a `s/Vident2::/Vident::/g` on project code.
- **Legacy collection classes removed.** `Vident::StimulusAction`, `StimulusTarget`, `StimulusController`, `StimulusValue`, `StimulusParam`, `StimulusOutlet`, `StimulusClass`, and each of their `*Collection` companions (plus `StimulusBuilder`, `StimulusDataAttributeBuilder`, `StimulusAttributeBase`, `StimulusAttributes`, `StimulusAction::Descriptor`) are gone. The 2.0 equivalents live under `Vident::Stimulus::*` (`Action`, `Target`, `Controller`, `Value`, `Param`, `Outlet`, `ClassMap`, `Collection`). `#to_h` now uses **Symbol keys** uniformly; V1 returned String keys for some primitives.
- **`child_element` strictness.** Passing both `stimulus_<singular>:` and `stimulus_<plural>:` kwargs now raises `ArgumentError` (`"mutually exclusive — pass one or the other."`). V1 silently dropped the singular when the plural was an empty array (latent since 1.0.0, see "Fixed" below). Workaround at call sites that relied on the V1 shape: `stimulus_targets: [:input, *control_targets]`.
- **`stimulus_controllers:` prop appends instead of replacing.** V1 replaced the implied controller when you passed `stimulus_controllers:` at render time; V2 appends, so the root element carries `data-controller="implied extra"`. Migration: if you wanted to *replace*, add `no_stimulus_controller` at the class level.
- **Outlet DSL procs now resolve.** V1 silently passed a proc through as the outlet selector string, emitting literal `#<Proc:0x...>`. V2 evaluates the proc in the instance binding and emits the returned string. This turns previously broken code into working code, but if you relied on the proc-as-identity string for some reason, you'll now see a different data attribute.
- **`nil` vs `false` drop rule.** V1 dropped both `nil` and `false` proc returns silently via a `blank?` filter. V2 drops only `nil`; `false` reaches the parser and raises `Vident::ParseError`. Fix: return `nil` (not `false`) to mean "don't emit this entry."
- **`no_stimulus_controller` + DSL body now raises loudly.** V1 raised a bare `StandardError` at instance init. V2 raises `Vident::DeclarationError` at `stimulus do ... end` time with the offending class name and caller location in the message.
- **StableId strategy.** Unchanged from 1.0, but reiterated here because it's the biggest gotcha during upgrade. `Vident::StableId` requires an explicit `strategy` and per-request seed — `bin/rails generate vident:install` sets both up correctly.

### Added

- **Fluent action DSL.** Inside `stimulus do ... end`, the singular `action(...)` call returns a chainable builder: `action(:escape).on(:keydown).keyboard("esc").window`, `action(:save).modifier(:prevent, :stop)`, `action(:delete).when { admin? }`. Chain methods: `.on`, `.call_method`, `.modifier`, `.keyboard`, `.window`, `.on_controller`, `.when`.
- **Kwargs shorthand for actions.** `action :save, on: :click, modifier: [:prevent, :stop], keyboard: "ctrl+s", window: true, on_controller: :admin, call_method: :handle_save, when: -> { ... }` — equivalent to the fluent chain, pick whichever reads better. Unknown kwargs raise `ArgumentError`.
- **Controller aliases.** `controller "admin/users", as: :admin` inside `stimulus do` declares a short alias; `action(...).on_controller(:admin)` or `action(..., on_controller: :admin)` then routes through it. Unknown alias refs raise `Vident::DeclarationError`. Runtime inputs (`stimulus_actions: [{method: :save, controller: :admin}]`) resolve the same map.
- **Capability mixin composition.** `Vident::Component` is a composition root that includes twelve focused capability mixins (`Tailwind`, `Declarable`, `Identifiable`, `StimulusDeclaring`, `StimulusParsing`, `StimulusMutation`, `StimulusDraft`, `StimulusDataEmitting`, `ClassListBuilding`, `RootElementRendering`, `ChildElementRendering`, `Inspectable`), plus an opt-in `Caching` mixin (thirteen in total, including Caching). Mixin order mirrors capability dependencies.
- **Singular DSL primitives.** `value(:name, *, **)`, `param(:name, *, **)`, `outlet(:name, *, **)`, `class_map(:name, *, **)`, `controller(path, as: nil)`, `controllers(*paths)`, `target(:name).when { ... }` — full set of singular entry points alongside the plural forms.
- **Draft → Plan seal pattern.** Internal: `after_component_initialize` mutators (e.g. `add_stimulus_actions`) still work against a mutable Draft; the Draft seals into an immutable Plan once rendering begins. Prevents the V1 "mutator silently ignored post-render" class of bug.
- **Phase-split proc resolution.** DSL procs are evaluated in two phases: static (after_initialize, no `view_context`) and procs (`before_template` / `before_render`, `view_context`/`helpers` wired). Procs can now call Rails helpers (`number_with_precision`, url helpers, `t`, `l`, etc.) safely — already backported to 1.0.2.

### Fixed

- `child_element` no longer silently drops a `stimulus_<singular>:` kwarg when `stimulus_<plural>:` is also passed with an empty array. The V1 helper returned early on an empty-but-truthy plural, losing the singular and emitting no data attribute — latent since 1.0.0, surfaced by call sites like `child_element(:input, stimulus_target: :input, stimulus_targets: control_targets)` where `control_targets` defaulted to `[]`. V2 raises `ArgumentError` on both-set (see Breaking); workaround on 1.x is `stimulus_targets: [:input, *control_targets]` (also works on 2.x).
- Outlet DSL procs now resolve instead of being treated as identity strings (see Breaking).
- `add_stimulus_actions([:click, :handle])` now treats the Array as *one* action descriptor (event + method pair) rather than splatting it into two separate `:click` and `:handle` actions. Matches the DSL's `actions [:click, :handle]` semantics — the V1 asymmetry is gone.

### Removed

- `Vident::StimulusAction::Descriptor` typed data class. The V2 equivalent is `Vident::Stimulus::Action` itself — the Hash shape accepted by the DSL (`{event:, method:, controller:, options:, keyboard:, window:}`) parses directly into the value class now. Callers that instantiated `Descriptor` explicitly should swap to `Vident::Stimulus::Action.parse(hash, implied: ...)` or just pass the Hash.
- Legacy top-level requires like `require "vident/stimulus_action"`. The main `require "vident"` loads the whole surface; deep requires for individual value classes still work (`require "vident/stimulus/action"`) but are no longer the documented path.


## [1.0.2] - 2026-04-21

### Changed

- Stimulus DSL procs (`values foo: -> { ... }`, `actions -> { ... }`, etc.) now resolve at **render time** — Phlex's `before_template` for `Vident::Phlex::HTML`, ViewComponent's `before_render` for `Vident::ViewComponent::Base` — instead of in `after_initialize`. Procs can now reach `helpers` / `view_context`, so they can call Rails helpers (`number_with_precision`, `t`, `l`, url helpers, etc.). Non-proc DSL entries still land in the collections at init time, so `after_component_initialize` mutators and external readers see them in the same order as before.

### Added

- `phlex_helpers :name1, :name2, ...` class macro on `Vident::Phlex::HTML` — opts the component into Phlex's per-helper Rails adapters (`Phlex::Rails::Helpers::<CamelCase>`) so DSL procs can call helpers bare (`number_with_precision(@amount, precision: 2)`) instead of via the deprecated `helpers.<method>`. Unknown helper names raise `ArgumentError` at class definition.


## [1.0.0] - 2026-04-19

### Breaking

- `nil` stimulus values (static or returned from a proc) are now filtered out of the rendered data attributes instead of being serialized to an empty string. The previous behaviour silently turned Boolean-typed Stimulus values on, because Stimulus parses empty strings as `true`. To explicitly emit the JS `null` literal (for Object/Array values), return the new `Vident::StimulusNull` sentinel (#24).
- `Vident::StableId` now requires an explicit strategy and an explicit per-request seed (#14). Run `bin/rails generate vident:install` to create an initializer that picks `STRICT` outside tests and wires a `before_action` in `ApplicationController` seeding the generator from `request.fullpath`. `set_current_sequence_generator` now requires `seed:` (nil raises `ArgumentError`); calling `next_id_in_sequence` with no strategy configured raises `Vident::StableId::StrategyNotConfiguredError`; in `STRICT` mode, missing the per-request seeding raises `Vident::StableId::GeneratorNotSetError`. The previous hard-coded seed of `42` (which produced identical IDs across unrelated requests and caused DOM collisions when Ajax fragments were grafted into server-rendered pages) is gone, and the `new_current_sequence_generator` alias has been removed.

### Added

- `Vident::StimulusNull` sentinel. Assign or return it from a value proc to emit `data-...-value="null"`, which Stimulus's Object/Array parser reads as JSON `null`.
- `Vident::StableId.with_sequence_generator(seed:) { ... }` block helper for scoping a generator to a render outside the normal request flow (mailers, jobs, previews) (#14).
- `bin/rails generate vident:install` installer that writes `config/initializers/vident.rb` and patches `ApplicationController` with the per-request seed hook (#14).
- Claude Code skill at `skills/vident/SKILL.md` shipped with the gem. The install generator drops it into `.claude/skills/vident/SKILL.md` in the host app so Claude Code picks up the gem's conventions automatically.
- Action descriptor support. The `stimulus_actions:` prop, `stimulus do ... actions(...)` DSL, and `child_element(stimulus_action(s): ...)` now accept a `Hash` (`{event:, method:, controller:, options:, keyboard:, window:}`) or a typed `Vident::StimulusAction::Descriptor` instance, allowing the `:once`/`:prevent`/`:stop`/`:passive`/`:"!passive"`/`:capture`/`:self` event-option modifiers, `.ctrl+a`-style keyboard filters, and `@window` in a structured Ruby form rather than a hand-typed descriptor string.
- Stimulus action parameters. New `Vident::StimulusParam` / `StimulusParamCollection`, a `stimulus_params:` prop, a `params` DSL entry (mirrors `values`), a `stimulus_params:`/`stimulus_param:` kwarg on `child_element`, and inline `as_stimulus_param(s)` helpers. Emits `data-<controller>-<name>-param` attributes readable via `event.params.<name>` in the JS controller; element-scoped to match Stimulus's own semantics.

### Changed

- Internal refactor: introduced a `Vident::Stimulus::PRIMITIVES` registry (`lib/vident/stimulus.rb`) as the single source of truth for the seven Stimulus primitive kinds (controllers, actions, targets, outlets, values, params, classes). `StimulusDataAttributeBuilder`, the seven `stimulus_<kind>s(...)` plural parsers, and the seven `add_stimulus_<kind>s(...)` mutators are now generated from that registry, so adding a future primitive is a one-line registry addition plus a Value/Collection class pair — no per-kind edits in the resolver, builder, child-element helper, or data-attribute builder. No user-visible API change.
- `serialize_value` lives on `StimulusAttributeBase` and is shared across `StimulusValue` / `StimulusParam` (was duplicated).
- `StimulusAttributeBase.stimulize_path` is the canonical path → identifier helper (`stimulus_identifier_from_path` on `StimulusComponent` now delegates); both accept Symbol input consistently.
- `StimulusBuilder`'s two nil-filter methods collapsed into one `resolve_hash_filtering_nil`.
- Uniform shape matrix across all seven plural parsers: every kind now consistently accepts pre-built `<Kind>` instances, pre-built `<Kind>Collection`s, Arrays, and (where meaningful) Hashes in its variadic input.

### Fixed

- `stimulus_controllers:` prop and the `stimulus_controllers(...)` helper now accept Symbol paths (e.g. `:my_controller`, `:"admin/users"`) instead of raising `NoMethodError: undefined method 'split' for an instance of Symbol` (#15).
- `Vident::StimulusController`'s `implied_controller_path` / `implied_controller_name` overrides now raise the same `ArgumentError` as the base when `implied_controller` is nil, instead of a confusing `NoMethodError`.
- `stimulus_values:` and `stimulus_classes:` props now accept cross-controller entries. The type unions include `Array` (matching `stimulus_actions:`/`stimulus_targets:`), and the collection parsers pass through pre-built `StimulusValue`/`StimulusValueCollection` (and class equivalents) instead of re-wrapping them into the single-value constructor and raising `ArgumentError: Invalid number of arguments` (#23).
- `Vident::ComponentClassLists#class_list_builder` no longer memoises the `ClassListBuilder` instance. The first caller's `root_element_html_class:` was previously latched into the cached builder, which silently dropped the `class:` argument passed to a later `root_element(class: …)` whenever `class_list_for_stimulus_classes(:name)` ran first. The underlying `TailwindMerge::Merger` is still thread-cached, so the re-construction cost is negligible.
- `Vident::ComponentClassLists#class_list_for_stimulus_classes` no longer leaks root element classes (component name, `root_element_classes`, etc.) into its return value. It previously reused the shared `class_list_builder`, whose `ClassListBuilder` is initialised with all root-element class sources baked in; `build` always prepends those, so child elements received the full root class soup instead of just the named Stimulus class CSS. Fix: build from a fresh `ClassListBuilder` with no root-element sources.

## [1.0.0.beta2] - 2026-04-16

### Breaking

- Renamed the `tag(...)` helper to `child_element(...)` (and the internal `Vident::TagHelper` module to `Vident::ChildElementHelper`). The old name shadowed Rails' own `tag(name, options)` positional API, which breaks Rails helpers like `hidden_field_tag` and `image_tag` when called inside vident components (#22). Rename any `component.tag(...)` calls to `component.child_element(...)`.

### Fixed

- `stimulus_outlet` parser now accepts `(String, String)` arguments so string-keyed outlets produced by the DSL actually render.

## [1.0.0.beta1] - 2026-04-16

### Fixed

- `tag(...)` singular stimulus kwargs (e.g. `stimulus_action: [:click, :foo]`) no longer splat `[event, handler]` tuples into two bare handlers (#19).
- `vident-view_component`'s `tag(...)` now emits void elements (`:input`, `:img`, `:br`, etc.) without a closing tag (#19).
- `vident-view_component`'s `tag(...)` without a block no longer renders the options hash as element content (#19).
- `stimulus_targets:` prop now accepts `Array` entries (e.g. `[[controller_path, :name]]`), matching `stimulus_actions:` (#20).
- `stimulus do ... outlets(...)` DSL now accepts a positional `Hash`, allowing string keys (e.g. stimulus identifiers containing `--`) that cannot be Ruby kwarg keys (#21).

## [1.0.0.alpha4] - 2025-12-12

- Update to `view_component` 4

## [1.0.0.alpha3] - 2025-07-21

### Breaking
- `element_classes` is now `root_element_classes` to make more consistent with the other root element methods.

### Added

-`.prop_names` and `#prop_values` methods to `Vident::Component` to return the names and values of the component's properties.

## [1.0.0.alpha2] - 2025-07-08

### Breaking
- `nil` values in Stimulus values are ok, but `nil` for an action/target/outlet makes no sense so is ignored.

### Fixed

- `stimulus_scoped_event` must return a Symbol to work with `stimulus_action` and `stimulus_target` methods etc.

## [1.0.0.alpha1] - 2025-07-08

This release is a major overhaul of the Vident library, and introduces a new API for defining components and Stimulus attributes. The new API is designed to be more consistent and easier to use.

### Breaking

Basically, everything.

- The `Vident::RootComponent` class has been removed, and the `Vident::Component` class is now the base class for all components.
- `Vident::Component` now uses `Literal::Properties` to define attributes, and the vident typed attributes modules have been removed.
- Parameters for stimulus attributes now are named with `stimulus_` prefix, eg `stimulus_controllers`
- Components now render their root element using the `root_element` method which does not need to be `render`ed.
  `render root_element do` -> `root_element do`
- The data attribute string creation methods `with_` now only exist on ViewComponent components and have been renamed to
  prefix with `as_` to avoid confusion with the ViewComponents slots API.
- The methods used to define Stimulus attributes have been changed, and now provides a more consistent API for defining Stimulus attributes across all components. They also return instances of classes such as `StimulusAction` or `StimulusActionCollection`, 
  which can be used to generate the Stimulus data attributes. eg `data: {**stimulus_controllers('foo')}`

Also:

- Vident `view_component` components now required **version 4.0** or later.
- Vident `phlex` components now required **version 2.0** or later.
- The gems `vident-better_html` and `vident-typed-*` gems have been removed
- The gem `vident-tailwind` has been removed, and the `Vident::Tailwind` module is now part of the core `vident` gem.

## [0.13.0] - 2024-04-07

### Breaking

- `data_maps` has been renamed to `values` and support has been added for the Stimulus 2+ Values API.
- `root`/`parent_element` no longer takes options, to define attributes for it, you can use `root_element_attributes` or the view component helper `root_component_attributes`. This change means
  that root elements can be instantiated outside of `render` which is useful if you refer to the instance in the components body block 

### Added

- New monorepo structure for the Vident project, retaining the separate gems however.
- All gems now have the same version and are released together.

### Changed

### Fixed

## [0.12.1] - 2024-06-12

### Fixed

- parsing of targets where the controller is also specified

## [0.12.0] - 2024-02-25

### Added

- `outlet` DSL methods updated so that the selector is scoped to the component's root element by default. This 
  is probably the most common use case, and it's now the default.
- `with_outlets` DSL method added to generate the data-* attributes for the outlets and return as a fragment  
  of HTML


## [0.11.0] - 2024-02-21

### Added

- `outlet_host` DSL method to support components hooking themselves into a host component's outlets



## [0.10.1] - 2024-02-21

### Added

- `outlets` option now accepts either a string stimulus controller identifier, a component instance, or a tuple of 
  identifier and CSS selector for the outlet.


## [0.10.0] - 2024-02-21

### Added

- `outlets` option for components, used to specify Stimulus outlets 

## [0.9.0] - 2023-08-11

### Added

- `#cache_key` support is now part of the core gem, and can be added to components using `Vident::Caching` module

## [0.8.0] - 2023-03-31

### Added

- new gems for Vident related functionality, eg `vident-typed` and `vident-tailwind`
- `vident` is now the core gem which can be used with any component system. Gems for Phlex and ViewComponent are available, `vident-phlex` and `vident-view_component`, and `vident-typed-phlex` and `vident-typed-view_component` are available with typed attributes support.

### Changed

- removed functionality for `better_html`, `dry-types`, `view_component`, and `phlex` from the core gem
- gem is now a Rails Engine and supports eager and autoloading

### Fixed

- Fix untyped attributes inheritance

## [0.7.0] - 2023-03-08  

### Added

- new `Vident::Tailwind` module which uses [tailwind_merge](https://github.com/gjtorikian/tailwind_merge) to merge TailwindCSS classes

### Changed

- Removed a dependency on intenal constants from `phlex`

## [0.6.3] - 2023-03-03

### Fixed

- Fix for changes to HTML tag collection in Phlex


## [0.6.2] - 2023-02-23

### Fixed

- Element tag options are not set when no ID is provided


## [0.6.1] - 2023-02-20

### Fixed

- `better_html` support fix for aliased dsl methods


## [0.6.0] - 2023-02-20

### Added

- Experimental support for `better_html` in the root components (the stimulus attributes are generated with `html_attributes`)



## [0.5.1] - 2023-02-17

### Added

- N/A

### Changed

- N/A

### Fixed

- Typed attributes was not always using custom coercion methods if they were defined 

### Removed

- N/A

### Deprecated

- N/A

### Security

- N/A

---

# Package Changelogs

## vident-better_html

### [0.6.0] - 2023-02-20

#### Added

- Experimental support for `better_html` in the root components (the stimulus attributes are generated with `html_attributes`)

### [0.6.1] - 2023-02-20

#### Fixed

- `better_html` support fix for aliased dsl methods

## vident-tailwind

### [0.1.1] - 2023-04-02

#### Fixed

- `tailwind_merge` should only take a non-nil value, and since it uses the class string as a cache key, it should not be blank.

## vident-typed-view_component

### [0.3.0] - 2023-08-12

- Update to depend on `vident-view_component` v0.3.0
- Adds support for new `Vident::Caching` module
- Update examples to support view_component v3

### [0.1.0] - 2023-04-01

- Initial release, extracted from `vident`

## vident-view_component

### [0.3.0] - 2023-08-12

- Update to depend on `vident` v0.9.0
- Adds support for new `Vident::Caching` module
- Update examples to support view_component v3

### [0.1.0] - 2023-04-01

- Initial release, extracted from `vident`

## vident-phlex

### [0.3.0] - 2023-08-12

- Update to depend on `vident` v0.9.0
- Adds support for new `Vident::Caching` module

### [0.1.0] - 2023-04-01

- Initial release, extracted from `vident`

## vident-typed-phlex

### [0.3.0] - 2023-08-12

- Update to depend on `vident-typed` v0.3.0
- Adds support for new `Vident::Caching` module

### [0.1.0] - 2023-04-01

- Initial release, extracted from `vident`
