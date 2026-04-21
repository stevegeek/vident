require "test_helper"
require "vident"

module Vident
  class ValueClassesTest < Minitest::Test
    def setup
      @implied = Vident::Stimulus::Controller.new(
        path: "foo/my_controller",
        name: "foo--my-controller"
      )
    end

    # ---- Naming --------------------------------------------------------

    def test_naming_stimulize_path_dasherizes_and_joins_with_double_dash
      assert_equal "admin--user-card", Vident::Stimulus::Naming.stimulize_path("admin/user_card")
    end

    def test_naming_stimulize_path_accepts_symbol
      assert_equal "foo--bar", Vident::Stimulus::Naming.stimulize_path(:"foo/bar")
    end

    def test_naming_js_name_lower_camel_cases
      assert_equal "myThing", Vident::Stimulus::Naming.js_name(:my_thing)
      assert_equal "handleClick", Vident::Stimulus::Naming.js_name("handle_click")
    end

    # ---- Null ----------------------------------------------------------

    def test_null_sentinel_serialises_to_literal_null_string
      assert_equal "null", Vident::Stimulus::Null.to_s
    end

    def test_null_sentinel_inspect
      assert_equal "Vident::StimulusNull", Vident::Stimulus::Null.inspect
    end

    def test_null_sentinel_is_frozen
      assert_predicate Vident::Stimulus::Null, :frozen?
    end

    def test_stimulus_null_and_namespace_null_are_same_object
      assert_same Vident::StimulusNull, Vident::Stimulus::Null
    end

    # ---- Controller.parse ---------------------------------------------

    def test_controller_parse_no_args_clones_implied
      c = Vident::Stimulus::Controller.parse(implied: @implied)
      assert_equal "foo/my_controller", c.path
      assert_equal "foo--my-controller", c.name
    end

    def test_controller_parse_with_path_string_stimulizes
      c = Vident::Stimulus::Controller.parse("admin/users", implied: @implied)
      assert_equal "admin/users", c.path
      assert_equal "admin--users", c.name
    end

    def test_controller_parse_carries_alias_name
      c = Vident::Stimulus::Controller.parse("admin/users", as: :admin, implied: @implied)
      assert_equal :admin, c.alias_name
    end

    def test_controller_to_data_pair
      c = Vident::Stimulus::Controller.parse("admin/users", implied: @implied)
      assert_equal [:controller, "admin--users"], c.to_data_pair
    end

    def test_controller_to_data_hash_space_joins
      a = Vident::Stimulus::Controller.parse(implied: @implied)
      b = Vident::Stimulus::Controller.parse("admin/users", implied: @implied)
      assert_equal({controller: "foo--my-controller admin--users"},
        Vident::Stimulus::Controller.to_data_hash([a, b]))
    end

    def test_controller_to_data_hash_empty
      assert_equal({}, Vident::Stimulus::Controller.to_data_hash([]))
    end

    # ---- Action.parse -------------------------------------------------

    def test_action_parse_single_symbol_is_implied_method_no_event
      a = Vident::Stimulus::Action.parse(:click, implied: @implied)
      assert_nil a.event
      assert_equal "click", a.method_name
      assert_equal "foo--my-controller", a.controller.name
      assert_equal "foo--my-controller#click", a.to_s
    end

    def test_action_parse_symbol_symbol_is_event_method
      a = Vident::Stimulus::Action.parse(:click, :handle_click, implied: @implied)
      assert_equal "click", a.event
      assert_equal "handleClick", a.method_name
      assert_equal "click->foo--my-controller#handleClick", a.to_s
    end

    def test_action_parse_string_symbol_is_controller_path_method
      a = Vident::Stimulus::Action.parse("admin/users", :show, implied: @implied)
      assert_nil a.event
      assert_equal "admin--users", a.controller.name
      assert_equal "admin--users#show", a.to_s
    end

    def test_action_parse_three_args_event_controller_method
      a = Vident::Stimulus::Action.parse(:hover, "path/to/ctrl", :go, implied: @implied)
      assert_equal "hover", a.event
      assert_equal "path--to--ctrl", a.controller.name
      assert_equal "hover->path--to--ctrl#go", a.to_s
    end

    def test_action_parse_qualified_string_passthrough
      a = Vident::Stimulus::Action.parse("click->admin/users#show", implied: @implied)
      assert_equal "click", a.event
      assert_equal "admin/users", a.controller.name
      assert_equal "show", a.method_name
    end

    def test_action_parse_hash_descriptor
      a = Vident::Stimulus::Action.parse(
        {event: :submit, method: :handle_submit, options: [:prevent]},
        implied: @implied
      )
      assert_equal "submit", a.event
      assert_equal "handleSubmit", a.method_name
      assert_equal [:prevent], a.modifiers
      assert_equal "submit:prevent->foo--my-controller#handleSubmit", a.to_s
    end

    def test_action_parse_hash_keyboard_and_window
      a = Vident::Stimulus::Action.parse(
        {event: :keydown, method: :save, keyboard: "ctrl+s", window: true},
        implied: @implied
      )
      assert_equal "keydown.ctrl+s@window->foo--my-controller#save", a.to_s
    end

    def test_action_parse_hash_invalid_option_raises
      assert_raises(::Vident::ParseError) do
        Vident::Stimulus::Action.parse(
          {method: :save, options: [:not_a_real_option]},
          implied: @implied
        )
      end
    end

    def test_action_parse_invalid_argument_shape_raises
      assert_raises(::Vident::ParseError) do
        Vident::Stimulus::Action.parse(123, implied: @implied)
      end
    end

    def test_action_to_data_pair
      a = Vident::Stimulus::Action.parse(:click, implied: @implied)
      assert_equal [:action, "foo--my-controller#click"], a.to_data_pair
    end

    def test_action_to_data_hash_space_joined_under_single_action_key
      a = Vident::Stimulus::Action.parse(:click, implied: @implied)
      b = Vident::Stimulus::Action.parse(:submit, :handle, implied: @implied)
      assert_equal(
        {action: "foo--my-controller#click submit->foo--my-controller#handle"},
        Vident::Stimulus::Action.to_data_hash([a, b])
      )
    end

    def test_action_to_data_hash_empty
      assert_equal({}, Vident::Stimulus::Action.to_data_hash([]))
    end

    # ---- Target.parse -------------------------------------------------

    def test_target_parse_single_symbol_on_implied
      t = Vident::Stimulus::Target.parse(:input, implied: @implied)
      assert_equal "foo--my-controller", t.controller.name
      assert_equal "input", t.name
    end

    def test_target_parse_camelizes_snake_case_symbol
      t = Vident::Stimulus::Target.parse(:submit_button, implied: @implied)
      assert_equal "submitButton", t.name
    end

    def test_target_parse_string_symbol_cross_controller
      t = Vident::Stimulus::Target.parse("admin/users", :row, implied: @implied)
      assert_equal "admin--users", t.controller.name
      assert_equal "row", t.name
    end

    def test_target_to_data_pair_uses_controller_scoped_symbol_key
      t = Vident::Stimulus::Target.parse(:input, implied: @implied)
      assert_equal [:"foo--my-controller-target", "input"], t.to_data_pair
    end

    def test_target_to_data_hash_same_controller_same_key_concatenates
      a = Vident::Stimulus::Target.parse(:input, implied: @implied)
      b = Vident::Stimulus::Target.parse(:output, implied: @implied)
      assert_equal(
        {"foo--my-controller-target": "input output"},
        Vident::Stimulus::Target.to_data_hash([a, b])
      )
    end

    def test_target_to_data_hash_different_controller_different_key
      a = Vident::Stimulus::Target.parse(:input, implied: @implied)
      b = Vident::Stimulus::Target.parse("admin/users", :row, implied: @implied)
      result = Vident::Stimulus::Target.to_data_hash([a, b])
      assert_equal "input", result[:"foo--my-controller-target"]
      assert_equal "row", result[:"admin--users-target"]
    end

    # ---- Value.parse --------------------------------------------------

    def test_value_parse_two_args_uses_implied_controller
      v = Vident::Stimulus::Value.parse(:url, "https://example.com", implied: @implied)
      assert_equal "foo--my-controller", v.controller.name
      assert_equal "url", v.name
      assert_equal "https://example.com", v.serialized
    end

    def test_value_parse_dasherizes_snake_case_name
      v = Vident::Stimulus::Value.parse(:api_url, "x", implied: @implied)
      assert_equal "api-url", v.name
    end

    def test_value_parse_serializes_array_as_json
      v = Vident::Stimulus::Value.parse(:items, ["a", "b"], implied: @implied)
      assert_equal '["a","b"]', v.serialized
    end

    def test_value_parse_serializes_hash_as_json
      v = Vident::Stimulus::Value.parse(:cfg, {k: 1}, implied: @implied)
      assert_equal '{"k":1}', v.serialized
    end

    def test_value_parse_false_serializes_to_string
      v = Vident::Stimulus::Value.parse(:enabled, false, implied: @implied)
      assert_equal "false", v.serialized
    end

    def test_value_parse_blank_string_preserved
      v = Vident::Stimulus::Value.parse(:label, "", implied: @implied)
      assert_equal "", v.serialized
    end

    def test_value_parse_null_sentinel_serialises_to_literal_null
      v = Vident::Stimulus::Value.parse(:config, Vident::Stimulus::Null, implied: @implied)
      assert_equal "null", v.serialized
    end

    def test_value_parse_nil_raises_caller_must_filter
      assert_raises(::Vident::ParseError) do
        Vident::Stimulus::Value.parse(:name, nil, implied: @implied)
      end
    end

    def test_value_parse_three_args_with_explicit_controller_path
      v = Vident::Stimulus::Value.parse("admin/users", :count, 42, implied: @implied)
      assert_equal "admin--users", v.controller.name
      assert_equal "42", v.serialized
    end

    def test_value_to_data_pair
      v = Vident::Stimulus::Value.parse(:url, "x", implied: @implied)
      assert_equal [:"foo--my-controller-url-value", "x"], v.to_data_pair
    end

    def test_value_to_data_hash_one_entry_per_instance
      a = Vident::Stimulus::Value.parse(:url, "x", implied: @implied)
      b = Vident::Stimulus::Value.parse(:count, 3, implied: @implied)
      assert_equal(
        {
          "foo--my-controller-url-value": "x",
          "foo--my-controller-count-value": "3"
        },
        Vident::Stimulus::Value.to_data_hash([a, b])
      )
    end

    # ---- Param.parse --------------------------------------------------

    def test_param_parse_two_args_uses_implied_controller
      p = Vident::Stimulus::Param.parse(:item_id, 42, implied: @implied)
      assert_equal "foo--my-controller", p.controller.name
      assert_equal "item-id", p.name
      assert_equal "42", p.serialized
    end

    def test_param_to_data_pair
      p = Vident::Stimulus::Param.parse(:item_id, 42, implied: @implied)
      assert_equal [:"foo--my-controller-item-id-param", "42"], p.to_data_pair
    end

    def test_param_to_data_hash
      a = Vident::Stimulus::Param.parse(:item_id, 42, implied: @implied)
      b = Vident::Stimulus::Param.parse(:role, "admin", implied: @implied)
      assert_equal(
        {
          "foo--my-controller-item-id-param": "42",
          "foo--my-controller-role-param": "admin"
        },
        Vident::Stimulus::Param.to_data_hash([a, b])
      )
    end

    def test_param_parse_false_serializes_to_string
      p = Vident::Stimulus::Param.parse(:flag, false, implied: @implied)
      assert_equal "false", p.serialized
    end

    # ---- ClassMap.parse -----------------------------------------------

    def test_class_map_parse_with_string_css
      m = Vident::Stimulus::ClassMap.parse(:loading, "opacity-50 cursor-wait", implied: @implied)
      assert_equal "foo--my-controller", m.controller.name
      assert_equal "loading", m.name
      assert_equal "opacity-50 cursor-wait", m.css
    end

    def test_class_map_parse_with_array_css
      m = Vident::Stimulus::ClassMap.parse(:loading, %w[opacity-50 cursor-wait], implied: @implied)
      assert_equal "opacity-50 cursor-wait", m.css
    end

    def test_class_map_parse_normalises_whitespace_in_string
      m = Vident::Stimulus::ClassMap.parse(:loading, "  opacity-50   cursor-wait  ", implied: @implied)
      assert_equal "opacity-50 cursor-wait", m.css
    end

    def test_class_map_parse_with_cross_controller
      m = Vident::Stimulus::ClassMap.parse("admin/users", :active, "bg-blue", implied: @implied)
      assert_equal "admin--users", m.controller.name
      assert_equal "active", m.name
      assert_equal "bg-blue", m.css
    end

    def test_class_map_parse_invalid_css_type_raises
      assert_raises(::Vident::ParseError) do
        Vident::Stimulus::ClassMap.parse(:loading, 42, implied: @implied)
      end
    end

    def test_class_map_to_data_pair
      m = Vident::Stimulus::ClassMap.parse(:loading, "p-4", implied: @implied)
      assert_equal [:"foo--my-controller-loading-class", "p-4"], m.to_data_pair
    end

    def test_class_map_to_data_hash
      a = Vident::Stimulus::ClassMap.parse(:loading, "op-50", implied: @implied)
      b = Vident::Stimulus::ClassMap.parse(:active, "bg-blue", implied: @implied)
      assert_equal(
        {
          "foo--my-controller-loading-class": "op-50",
          "foo--my-controller-active-class": "bg-blue"
        },
        Vident::Stimulus::ClassMap.to_data_hash([a, b])
      )
    end

    # ---- Outlet.parse -------------------------------------------------

    def test_outlet_parse_single_symbol_auto_selector_with_component_id
      o = Vident::Stimulus::Outlet.parse(:menu, implied: @implied, component_id: "host-1")
      assert_equal "foo--my-controller", o.controller.name
      assert_equal "menu", o.name
      assert_equal "#host-1 [data-controller~=menu]", o.selector
    end

    def test_outlet_parse_single_symbol_auto_selector_no_component_id
      o = Vident::Stimulus::Outlet.parse(:menu, implied: @implied)
      assert_equal "[data-controller~=menu]", o.selector
    end

    def test_outlet_parse_array_pair_explicit_selector
      o = Vident::Stimulus::Outlet.parse([:menu, ".js-menu"], implied: @implied)
      assert_equal "menu", o.name
      assert_equal ".js-menu", o.selector
    end

    def test_outlet_parse_two_args_name_and_selector
      o = Vident::Stimulus::Outlet.parse(:menu, ".js-menu", implied: @implied)
      assert_equal "menu", o.name
      assert_equal ".js-menu", o.selector
    end

    def test_outlet_parse_three_args_ctrl_name_selector
      o = Vident::Stimulus::Outlet.parse("admin/users", :menu, ".x", implied: @implied)
      assert_equal "admin--users", o.controller.name
      assert_equal "menu", o.name
      assert_equal ".x", o.selector
    end

    def test_outlet_parse_component_with_stimulus_identifier
      component = Struct.new(:stimulus_identifier).new("other-component")
      o = Vident::Stimulus::Outlet.parse(component, implied: @implied, component_id: "h")
      assert_equal "other-component", o.name
      assert_equal "#h [data-controller~=other-component]", o.selector
    end

    def test_outlet_auto_selector_escapes_component_id_with_space
      o = Vident::Stimulus::Outlet.parse(:menu, implied: @implied, component_id: "my card")
      assert_equal "#my\\20 card [data-controller~=menu]", o.selector
    end

    def test_outlet_auto_selector_escapes_component_id_with_bracket
      o = Vident::Stimulus::Outlet.parse(:menu, implied: @implied, component_id: "foo[bar")
      assert_equal "#foo\\5b bar [data-controller~=menu]", o.selector
    end

    def test_outlet_auto_selector_escapes_parens
      o = Vident::Stimulus::Outlet.parse(:menu, implied: @implied, component_id: "f(1)")
      assert_equal "#f\\28 1\\29  [data-controller~=menu]", o.selector
    end

    def test_outlet_to_data_pair
      o = Vident::Stimulus::Outlet.parse(:menu, ".x", implied: @implied)
      assert_equal [:"foo--my-controller-menu-outlet", ".x"], o.to_data_pair
    end

    def test_outlet_to_data_hash
      a = Vident::Stimulus::Outlet.parse(:menu, ".a", implied: @implied)
      b = Vident::Stimulus::Outlet.parse(:nav, ".b", implied: @implied)
      assert_equal(
        {
          "foo--my-controller-menu-outlet": ".a",
          "foo--my-controller-nav-outlet": ".b"
        },
        Vident::Stimulus::Outlet.to_data_hash([a, b])
      )
    end

    # ---- Registry -----------------------------------------------------

    def test_registry_kinds_are_all_seven
      assert_equal(
        %i[controllers actions targets outlets values params class_maps],
        Vident::Internals::Registry::KINDS.map(&:name)
      )
    end

    def test_registry_fetch_returns_kind_record
      k = Vident::Internals::Registry.fetch(:actions)
      assert_equal :actions, k.name
      assert_equal Vident::Stimulus::Action, k.value_class
      refute k.keyed
    end

    def test_registry_class_maps_has_plural_classes
      k = Vident::Internals::Registry.fetch(:class_maps)
      assert_equal :classes, k.plural_name
      assert_equal Vident::Stimulus::ClassMap, k.value_class
      assert k.keyed
    end

    def test_registry_fetch_unknown_raises
      assert_raises(KeyError) { Vident::Internals::Registry.fetch(:bogus) }
    end

    def test_registry_each_yields_kind_records
      names = []
      Vident::Internals::Registry.each { |k| names << k.name }
      assert_equal 7, names.size
    end

    # ---- Cross-kind to_data_hash uses Symbol keys throughout ---------

    def test_all_kinds_to_data_hash_returns_symbol_keys
      ctrl = Vident::Stimulus::Controller.parse("foo", implied: @implied)
      act = Vident::Stimulus::Action.parse(:click, implied: @implied)
      tgt = Vident::Stimulus::Target.parse(:x, implied: @implied)
      val = Vident::Stimulus::Value.parse(:n, 1, implied: @implied)
      prm = Vident::Stimulus::Param.parse(:n, 1, implied: @implied)
      cm = Vident::Stimulus::ClassMap.parse(:n, "a", implied: @implied)
      out = Vident::Stimulus::Outlet.parse(:n, ".x", implied: @implied)

      [
        Vident::Stimulus::Controller.to_data_hash([ctrl]),
        Vident::Stimulus::Action.to_data_hash([act]),
        Vident::Stimulus::Target.to_data_hash([tgt]),
        Vident::Stimulus::Value.to_data_hash([val]),
        Vident::Stimulus::Param.to_data_hash([prm]),
        Vident::Stimulus::ClassMap.to_data_hash([cm]),
        Vident::Stimulus::Outlet.to_data_hash([out])
      ].each do |hash|
        assert hash.keys.all? { |k| k.is_a?(Symbol) },
          "expected all-Symbol keys, got: #{hash.keys.map(&:class).inspect}"
      end
    end

    # ---- parse error branches ------------------------------------------

    def test_target_parse_from_string
      t = Vident::Stimulus::Target.parse("my-button", implied: @implied)
      assert_equal "my-button", t.name
      assert_equal @implied, t.controller
    end

    def test_target_parse_invalid_shape_raises
      assert_raises(::Vident::ParseError) { Vident::Stimulus::Target.parse(42, implied: @implied) }
    end

    def test_controller_parse_too_many_args_raises
      assert_raises(::Vident::ParseError) do
        Vident::Stimulus::Controller.parse("a", "b", implied: @implied)
      end
    end

    def test_value_parse_invalid_shape_raises
      assert_raises(::Vident::ParseError) { Vident::Stimulus::Value.parse(:foo, implied: @implied) }
    end

    def test_param_parse_invalid_shape_raises
      assert_raises(::Vident::ParseError) { Vident::Stimulus::Param.parse(:foo, implied: @implied) }
    end

    def test_class_map_parse_invalid_shape_raises
      assert_raises(::Vident::ParseError) { Vident::Stimulus::ClassMap.parse(:foo, implied: @implied) }
    end

    def test_outlet_parse_from_string_uses_auto_selector
      o = Vident::Stimulus::Outlet.parse("my-outlet", implied: @implied, component_id: "h")
      assert_equal "my-outlet", o.name
      assert_equal "#h [data-controller~=my-outlet]", o.selector
    end

    def test_outlet_parse_string_with_underscores_selector_uses_dasherized_name
      o = Vident::Stimulus::Outlet.parse("user_card_component", implied: @implied)
      assert_equal "user-card-component", o.name
      assert_includes o.selector, "user-card-component"
      refute_includes o.selector, "user_card_component"
    end

    def test_outlet_parse_string_string_uses_verbatim_selector
      o = Vident::Stimulus::Outlet.parse("menu", ".js-menu", implied: @implied)
      assert_equal "menu", o.name
      assert_equal ".js-menu", o.selector
    end

    def test_outlet_parse_string_string_dasherizes_name
      o = Vident::Stimulus::Outlet.parse("user_card_component", ".x", implied: @implied)
      assert_equal "user-card-component", o.name
      assert_equal ".x", o.selector
    end

    def test_outlet_parse_invalid_shape_raises
      assert_raises(::Vident::ParseError) { Vident::Stimulus::Outlet.parse(42, implied: @implied) }
    end

    def test_action_parse_qualified_string_without_arrow
      a = Vident::Stimulus::Action.parse("admin--users#show", implied: @implied)
      assert_nil a.event
      assert_equal "admin--users", a.controller.name
      assert_equal "show", a.method_name
    end

    # ---- Stimulus::Collection ------------------------------------------

    def test_collection_merge_same_kind
      kind = Vident::Internals::Registry.fetch(:targets)
      t1 = Vident::Stimulus::Target.parse(:a, implied: @implied)
      t2 = Vident::Stimulus::Target.parse(:b, implied: @implied)
      c1 = Vident::Stimulus::Collection.new(kind: kind, items: [t1])
      c2 = Vident::Stimulus::Collection.new(kind: kind, items: [t2])
      merged = c1.merge(c2)
      assert_equal 2, merged.size
      assert_equal [t1, t2], merged.to_a
    end

    def test_collection_merge_different_kind_raises
      target_kind = Vident::Internals::Registry.fetch(:targets)
      action_kind = Vident::Internals::Registry.fetch(:actions)
      c1 = Vident::Stimulus::Collection.new(kind: target_kind, items: [])
      c2 = Vident::Stimulus::Collection.new(kind: action_kind, items: [])
      assert_raises(ArgumentError) { c1.merge(c2) }
    end

    # ---- to_hash alias (for `{**value}` splat support) -----------------

    def test_value_class_supports_hash_splat
      t = Vident::Stimulus::Target.parse(:input, implied: @implied)
      assert_equal t.to_h, {**t}
    end

    def test_collection_supports_hash_splat
      kind = Vident::Internals::Registry.fetch(:targets)
      items = [Vident::Stimulus::Target.parse(:a, implied: @implied),
        Vident::Stimulus::Target.parse(:b, implied: @implied)]
      collection = Vident::Stimulus::Collection.new(kind: kind, items: items)
      assert_equal collection.to_h, {**collection}
    end
  end
end
