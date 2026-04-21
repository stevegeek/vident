# Vident worked examples

End-to-end walkthroughs. Every example here runs against the public API verified in
`test/public_api_spec/` and the dummy app under `test/dummy/app/components/`. If a pattern
isn't shown below but is referenced in SKILL.md, it almost certainly shows up in
`test/dummy/app/components/dashboard/`.

The examples are grouped by shape:

1. [Dashboard: outlets + scoped events + StimulusNull](#1-dashboard-outlets--scoped-events--stimulusnull) (Phlex)
2. [Greeter with slot trigger: parent-child Stimulus wiring](#2-greeter-with-slot-trigger) (ViewComponent + Phlex)
3. [ERB syntax: three ways to emit data attributes in a template](#3-erb-three-ways-to-emit-data-attributes)
4. [Avatar: conditional root tag + class-list precedence](#4-avatar-conditional-root-tag--class-list-precedence) (Phlex)
5. [Stimulus params on sibling buttons sharing one handler](#5-stimulus-params-on-sibling-buttons)

---

## 1. Dashboard: outlets + scoped events + StimulusNull

A page hosts many release cards; cards are filterable via a filter bar; selecting a card
opens a detail panel; promoting/cancelling a card fires a toast. Full source in
`test/dummy/app/components/dashboard/`.

### Page (host of card outlets)

```ruby
module Dashboard
  class PageComponent < ApplicationComponent
    prop :releases, _Array(Hash), default: -> { [] }
    prop :active_filter, _Union(:all, :pending, :deployed, :failed), default: :all

    stimulus do
      values active_filter: -> { @active_filter.to_s },
             count: -> { @releases.size }

      # Listen to a scoped `filterChanged` event dispatched on window by FilterBar.
      # Ruby side: reference the DISPATCHER's class.
      actions -> { [FilterBarComponent.stimulus_scoped_event_on_window(:filter_changed), :handle_filter_changed] }
    end

    def view_template
      root_element(class: "space-y-6") do |page|
        render FilterBarComponent.new(active_filter: @active_filter, total: @releases.size)

        div(class: "grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4") do
          @releases.each do |release|
            # `stimulus_outlet_host: page` is the child-registers-with-host hook:
            # each card's initialize calls `page.add_stimulus_outlets(self)`, which
            # writes a `data-dashboard--page-component-dashboard--release-card-component-outlet`
            # onto the page root. No need to list cards in the page's `stimulus do`.
            render ReleaseCardComponent.new(**release, stimulus_outlet_host: page)
          end
        end

        render DetailPanelComponent.new
        render ToastComponent.new
      end
    end
  end
end
```

```js
// dashboard/page_component_controller.js
export default class extends Controller {
  static values = { activeFilter: String, count: Number }
  static outlets = ["dashboard--release-card-component"]

  handleFilterChanged(event) {
    const { filter, query } = event.detail ?? {}
    if (filter !== undefined) this.activeFilterValue = filter
    this.#applyFilter(query ?? "")
  }

  // GOTCHA: do not iterate `this.dashboardReleaseCardComponentOutlets` inside
  // dashboardReleaseCardComponentOutletConnected — Stimulus warns for each
  // selector match whose controller hasn't attached yet. Iterate on real events.

  #applyFilter(query) {
    const q = query.trim().toLowerCase()
    let visible = 0
    for (const card of this.dashboardReleaseCardComponentOutlets) {
      const show = (this.activeFilterValue === "all" || card.statusValue === this.activeFilterValue)
                && (q === "" || card.nameValue.toLowerCase().includes(q))
      card.setVisible(show)
      if (show) visible += 1
    }
    this.countValue = visible
    this.dispatch("filterApplied", { detail: { count: visible }, target: window })
  }
}
```

### Release card (self-registers with host, uses `classes` DSL + SSR)

```ruby
module Dashboard
  class ReleaseCardComponent < ApplicationComponent
    prop :release_id, Integer
    prop :name, String
    prop :version, String
    prop :environment, _Union(:production, :staging, :preview), default: :staging
    prop :status, _Union(:pending, :deployed, :failed), default: :pending

    # `stimulus_outlet_host:` is inherited from Vident::Component — no prop
    # declaration needed in this class.

    stimulus do
      values_from_props :release_id, :name, :status

      # Proc sees @status at render time; emits
      # `data-<this-controller>-status-class="..."` for the JS side, AND the same
      # value is inlined via `class_list_for_stimulus_classes(:status)` below
      # for SSR first paint.
      classes status: -> {
        case @status
        when :deployed then "border-green-500 bg-green-50"
        when :failed   then "border-red-500 bg-red-50"
        else                "border-yellow-400 bg-yellow-50"
        end
      }

      actions [:click, :select]
    end

    def view_template
      root_element(
        class: "block cursor-pointer rounded-lg border-2 p-4 shadow-sm #{class_list_for_stimulus_classes(:status)}",
        role: "button",
        tabindex: 0
      ) do |card|
        # Two buttons share one `apply` handler. `event.params.kind` on the JS side
        # tells them apart — see example 5 for the params idiom.
        card.child_element(
          :button,
          stimulus_action: [:click, :apply],
          stimulus_target: :promote_button,
          stimulus_params: { kind: "promote" },
          type: "button", class: "..."
        ) { "Promote" }

        card.child_element(
          :button,
          stimulus_action: [:click, :apply],
          stimulus_target: :cancel_button,
          stimulus_params: { kind: "cancel" },
          type: "button", class: "..."
        ) { "Cancel" }
      end
    end
  end
end
```

```js
// dashboard/release_card_component_controller.js
export default class extends Controller {
  static targets = ["promoteButton", "cancelButton"]
  static values = { releaseId: Number, name: String, status: String }

  select(event) {
    if (event.target.closest("button")) return       // let buttons handle themselves
    this.dispatch("selected", { detail: this.#payload(), target: window })
  }

  apply(event) {
    const kind = event.params.kind                   // "promote" | "cancel"
    this.#disable()
    this.dispatch(`${kind}d`, { detail: this.#payload(), target: window })
  }

  setVisible(show) { this.element.classList.toggle("hidden", !show) }

  #payload() { return { releaseId: this.releaseIdValue, name: this.nameValue, status: this.statusValue } }
  #disable() { this.promoteButtonTarget.disabled = true; this.cancelButtonTarget.disabled = true }
}
```

### Detail panel (StimulusNull + keyboard modifier action + alias resolution)

```ruby
module Dashboard
  class DetailPanelComponent < ApplicationComponent
    stimulus do
      # Vident::StimulusNull emits the literal string "null" as the data attribute
      # value. Stimulus's Object parser runs it through JSON.parse, so `releaseValue`
      # starts as JS `null` instead of the default `{}`. Use ONLY with Object/Array
      # typed Stimulus values — for String/Number/Boolean the "null" string reads
      # as garbage. A bare `nil` would omit the attribute entirely (Stimulus uses
      # its per-type default); StimulusNull is an explicit "emit null" opt-in.
      values release: -> { Vident::StimulusNull }

      classes state: "fixed right-0 top-0 h-full w-80 border-l bg-white p-6 shadow-xl transition-transform duration-200 translate-x-full"

      # Secondary controller stacked on the same root, given a short alias so
      # later action entries can refer to it by `:dismissable` instead of the
      # full path. Emits `data-controller="dashboard--detail-panel-component
      # dashboard--dismissable"`.
      controller "dashboard_v2/dismissable", as: :dismissable

      # 1. Proc + scoped window event — opens the panel when a card emits `selected`.
      actions -> { [ReleaseCardComponent.stimulus_scoped_event_on_window(:selected), :handle_selected] }

      # 2. Kwargs shorthand for the keyboard filter. Equivalent to:
      #    `action(:close).on(:keydown).keyboard("esc").window`.
      #    Emits `keydown.esc@window->dashboard--detail-panel-component#close`.
      action :close, on: :keydown, keyboard: "esc", window: true

      # 3. Fluent chain routed through the `:dismissable` alias. Emits
      #    `keydown.backspace@window->dashboard--dismissable#close` instead of
      #    the implied controller — alias resolved by Internals::Resolver.
      action(:close).on(:keydown).keyboard("backspace").window.on_controller(:dismissable)

      # 4. Plain `:close` — wired to the close button's local click target.
      action :close
    end

    def view_template
      root_element(class: class_list_for_stimulus_classes(:state)) do |panel|
        panel.child_element(:button, stimulus_action: :close, type: "button") { "X" }
        panel.child_element(:div, stimulus_target: :body, class: "mt-4 space-y-2") do
          p(class: "italic text-gray-400") { "Click a release to see details." }
        end
      end
    end
  end
end
```

```js
// dashboard/detail_panel_component_controller.js
export default class extends Controller {
  static targets = ["body"]
  static values = { release: Object }

  handleSelected(event) {
    this.releaseValue = event.detail
    this.#render()
    this.element.classList.remove("translate-x-full")
  }

  close() { this.element.classList.add("translate-x-full") }

  #render() {
    const r = this.releaseValue
    if (!r || !r.releaseId) return
    this.bodyTarget.innerHTML = `<p>${r.name} — ${r.status}</p>`
  }
}
```

Identifier walk:
`Dashboard::ReleaseCardComponent` → class method `stimulus_identifier` returns
`"dashboard--release-card-component"`. `stimulus_scoped_event_on_window(:selected)`
returns the Symbol `:"dashboard--release-card-component:selected@window"`. On the JS
side, the card's `this.dispatch("selected", { target: window })` fires an event of type
`dashboard--release-card-component:selected` on window, matching exactly.

---

## 2. Greeter with slot trigger

Parent exposes a named slot; parent passes its own action descriptor into the slot at
render time so the slot triggers a method on the parent.

### ViewComponent + ERB

```ruby
# app/components/greeters/greeter_with_trigger_component.rb
module Greeters
  class GreeterWithTriggerComponent < Vident::ViewComponent::Base
    renders_one :trigger, GreeterButtonComponent

    def root_element_attributes
      {
        stimulus_classes: {
          pre_click: "text-md text-gray-500",
          post_click: "text-xl text-blue-700"
        }
      }
    end

    # Default fallback — used when the consumer doesn't pass a custom trigger.
    def default_trigger
      GreeterButtonComponent.new(
        before_clicked_message: "Click me to greet.",
        after_clicked_message:  "Greeted! Click to reset.",
        stimulus_actions: [stimulus_action(:click, :greet)]
      )
    end
  end
end
```

```erb
<%= root_element do |greeter| %>
  <input type="text"
         <%= greeter.as_stimulus_target(:name) %>
         class="shadow appearance-none border rounded py-2 px-3">

  <% if trigger? %>
    <%= trigger %>
  <% end %>

  <%= greeter.child_element(:span, stimulus_target: :output,
                            class: "ml-4 #{greeter.class_list_for_stimulus_classes(:pre_click)}") do %>
    ...
  <% end %>
<% end %>
```

At the render site, the consumer can override the trigger while still wiring it to the
parent's action:

```erb
<%= render GreeterWithTriggerComponent.new do |greeter| %>
  <% greeter.with_trigger(
       before_clicked_message: "Custom label",
       stimulus_actions: [greeter.stimulus_action(:click, :greet)]
     ) %>
<% end %>
```

`greeter.stimulus_action(:click, :greet)` returns a `Vident::Stimulus::Action` whose
`controller` is the parent's (greeter's) identifier, so the click handler on the child's
button routes to `greeter-with-trigger-component#greet`, not to the child.

### Phlex version

Same component, Phlex syntax:

```ruby
module PhlexGreeters
  class GreeterWithTriggerComponent < ApplicationComponent
    def trigger(**args)
      @trigger ||= GreeterButtonComponent.new(**args)
    end

    private

    def trigger_or_default(greeter)
      return render(@trigger) if @trigger

      render(trigger(
        before_clicked_message: "Greet",
        stimulus_actions: [greeter.stimulus_action(:click, :greet)]
      ))
    end

    def root_element_attributes
      { stimulus_classes: { pre_click: "text-md text-gray-500", post_click: "text-xl text-blue-700" } }
    end

    def view_template(&)
      vanish(&)   # capture & discard the block content so consumers can call `#trigger` inside it
      root_element do |greeter|
        input(type: "text", data: { **greeter.stimulus_target(:name) })
        trigger_or_default(greeter)
        greeter.child_element(:span, stimulus_target: :output,
                              class: "ml-4 #{greeter.class_list_for_stimulus_classes(:pre_click)}")
      end
    end
  end
end
```

---

## 3. ERB: three ways to emit data attributes

ViewComponent/ERB users have three stylistic choices for attaching Stimulus wiring to
a hand-authored HTML tag. All three are equivalent; pick one per file for consistency.

```erb
<%= root_element do |greeter| %>
  <%# (a) Inline `as_stimulus_*` helpers — embed the raw data-* attributes directly in the HTML tag. %>
  <%#     Most compatible with better_html only if you allow embedded expressions inside tag bodies. %>
  <input type="text"
         <%= greeter.as_stimulus_target(:name) %>
         class="...">
  <button <%= greeter.as_stimulus_action([:click, :greet]) %>
          class="...">
    <%= @cta %>
  </button>

  <%# (b) Rails `content_tag` with `data:` spread — works anywhere `content_tag` does, %>
  <%#     plays nicely with strict HTML linters. Singular helpers return a Hash shape %>
  <%#     like { "data-greeter-target" => "name" }, spread with `**`. %>
  <%= content_tag(:input, nil, type: "text", data: { **greeter.stimulus_target(:name) }) %>
  <%= content_tag(:button, @cta, data: { **greeter.stimulus_action([:click, :greet]) }) %>

  <%# (c) Vident's `child_element` helper — one call, tag + stimulus_* kwargs + block. %>
  <%#     Plural kwargs (`stimulus_actions:`) take an Enumerable; singular take one entry. %>
  <%= greeter.child_element(:input, stimulus_target: :name, type: "text", class: "...") %>
  <%= greeter.child_element(:button, stimulus_action: [:click, :greet], class: "...") do %>
    <%= @cta %>
  <% end %>
<% end %>
```

Phlex users have two choices — `child_element` (identical) and the native Phlex tag
methods with `data: { **component.stimulus_target(:name) }`.

---

## 4. Avatar: conditional root tag + class-list precedence

Shows `element_tag:` varying by prop, `no_stimulus_controller`, `with_cache_key`, and
the full class-list precedence via `root_element_classes`.

```ruby
module Phlex
  class AvatarComponent < ApplicationComponent
    no_stimulus_controller              # don't emit the implied `data-controller`
    with_cache_key                      # relies on ApplicationComponent `include Vident::Caching` — see api-reference.md

    prop :url, _Nilable(String), predicate: :private, reader: :public
    prop :initials, String, reader: :public
    prop :shape, Symbol, default: :circle, reader: :public
    prop :border, _Boolean, default: false, predicate: :private, reader: :public
    prop :size, Symbol, default: :normal, reader: :public

    private

    def view_template
      root_element do
        span(class: "#{text_size_class} font-medium leading-none text-white") { @initials } unless image_avatar?
      end
    end

    # Flip the root to <img> when a URL is given.
    def root_element_attributes
      {
        element_tag: image_avatar? ? :img : :div,
        html_options: default_html_options
      }
    end

    def default_html_options
      if image_avatar?
        { class: "inline-block object-contain", src: @url, alt: "Profile image" }
      else
        { class: "inline-flex items-center justify-center bg-gray-500" }
      end
    end

    # Lower precedence than `html_options[:class]` — wins only when `html_options` has no `:class`.
    def root_element_classes
      [size_classes, shape_class, (@border ? "border" : "")]
    end

    def image_avatar? = @url.present?
    def shape_class   = (@shape == :circle) ? "rounded-full" : "rounded-md"
    def size_classes  = { tiny: "w-6 h-6", small: "w-8 h-8", medium: "w-12 h-12" }[@size] || "w-10 h-10"
    def text_size_class = (@size == :tiny || @size == :small) ? "text-xs" : "text-medium"
  end
end
```

Because this AvatarComponent sets `html_options[:class]` in `root_element_attributes`,
`root_element_classes` is NOT applied — `html_options[:class]` wins per the precedence
rules in SKILL.md §4. If you want the `root_element_classes` values kept AND extra
overrides, merge them yourself (see `PhlexGreeters::InheritedGreeterComponent` in the
dummy app for a `tailwind_merge`-aware merge).

---

## 5. Stimulus params on sibling buttons

Both buttons fire the same `apply` action on the parent card controller; the
per-button `stimulus_params:` tells the handler which one fired via `event.params.kind`:

```ruby
card.child_element(:button,
  stimulus_action: [:click, :apply],
  stimulus_params: { kind: "promote" }) { "Promote" }

card.child_element(:button,
  stimulus_action: [:click, :apply],
  stimulus_params: { kind: "cancel"  }) { "Cancel" }
```

```js
apply(event) {
  const kind = event.params.kind   // "promote" | "cancel"
  this.dispatch(`${kind}d`, { detail: this.#payload(), target: window })
}
```

**Element-scoped, not action-scoped.** In Stimulus, params live on the element, so every
action on the same element sees the same `event.params`. Vident mirrors this: `params`
is a sibling of `actions` in the DSL, not nested inside it. If you need per-action
params, split the buttons. This is usually preferable anyway — the shared-handler
pattern above is a tiny bit RPC-ish and is shown because params are useful to know
about, not because one action/two params is the recommended shape.

---

## Where to read more

- `test/dummy/app/components/dashboard/` — the full dashboard (5 components + JS) is
  Vident's reference example. Every feature in SKILL.md is exercised there.
- `test/public_api_spec/specs/core_dsl.rb` — one locked-behaviour test per input shape
  of every DSL primitive. Useful when unsure about an edge case.
- `test/dummy/app/components/greeters/` (ERB) and `test/dummy/app/components/phlex_greeters/` (Phlex) — side-by-side renditions of the same component in both engines.
