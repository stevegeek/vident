# Vident public-API spec suite

A parameterised integration test suite that asserts on **rendered HTML strings**
produced by Vident components. Exists to freeze Vident's documented public
behaviour so the Vident 2.0 synthesis rearchitecture (see
`doc/reviews/wave-4-synthesis.md`) can be validated against a stable
specification.

## Layout

```
test/public_api_spec/
  README.md                 — this file
  support.rb                — PhlexAdapter + ViewComponentAdapter helpers
  specs/                    — one file per API surface, each a Ruby module
    core_dsl.rb             — stimulus do: actions/targets/values/params/classes/outlets
    controllers.rb          — implied controller, no_stimulus_controller
    props.rb                — stimulus_* props
    mutators.rb             — add_stimulus_*
    outlet_host.rb          — stimulus_outlet_host: pattern
    root_element.rb         — root_element + precedence
    child_element.rb        — child_element kwargs
    inheritance.rb          — parent/child stimulus do merging
    scoped_events.rb        — stimulus_scoped_event(_on_window)
    stimulus_null.rb        — StimulusNull sentinel + nil-drop rule
    class_list.rb           — class_list_for_stimulus_classes precedence
    stable_id.rb            — StableId strategies
    caching.rb              — with_cache_key / depends_on
    errors.rb               — what raises what (locks current shapes)
    vc_as_stimulus.rb       — VC-only: 14 as_stimulus_* helpers
  phlex_v1_test.rb          — runs adapter-agnostic specs against Phlex v1
  view_component_v1_test.rb — runs adapter-agnostic specs against VC v1
```

Each spec file defines a Minitest mixin module under
`Vident::PublicApiSpec::<SpecName>`. The test runner classes include the
adapter helpers and the spec modules. When Vident 2.0 lands, add
`phlex_v2_test.rb` and `view_component_v2_test.rb` that include the same
spec modules against the new classes — no spec changes required.

## Assertions

All assertions are against **rendered HTML strings**. Byte-exact matches
where Vident's output is deterministic; regex where Vident includes a
run-of-the-mill StableId or similar known-variable piece. If you reach
for Nokogiri, ask first — tolerance to whitespace/ordering is usually
masking a regression worth seeing.

## Test components

Each test builds its own anonymous component class via
`define_component(name: "X") { ... }`. Anonymous to avoid class-state
leaking across tests (Vident's `StimulusBuilder` and Literal both hold
class ivars). The `name:` kwarg gives a predictable stimulus
identifier.

## Running

```
bundle exec rake test TEST=test/public_api_spec
```

…or just `rake test` (Rails picks up `test/**/*_test.rb` automatically).

## Known accidental-behaviour notes

Any comment tagged `# SPEC-NOTE:` marks an observation made during
extraction — a Vident behaviour that was not obviously intentional but
is being locked here as spec. The wave-4 migration should revisit each
and decide: keep as canonical, or document as a 2.0 behaviour change.
