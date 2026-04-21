# frozen_string_literal: true

require "test_helper"
require "vident"

module Vident
  # Mirrors the V1 Caching surface: opt-in via `include Vident::Caching`,
  # `with_cache_key` declares attrs, `depends_on` chains mtimes, and
  # `cache_key` returns a stable deterministic key.
  class CachingTest < Minitest::Test
    def make_component(name: "ButtonComponent", &block)
      klass = Class.new(::Vident::Phlex::HTML)
      klass.define_singleton_method(:name) { name }
      klass.class_eval(&block) if block
      klass
    end

    # ---- opt-in --------------------------------------------------------

    def test_component_without_caching_include_is_not_cacheable
      klass = make_component
      refute_respond_to klass.new, :cacheable?
    end

    def test_component_with_caching_include_is_cacheable
      klass = make_component do
        include ::Vident::Caching
        prop :name_attr, String, default: "x", reader: :public
        with_cache_key :name_attr
      end
      klass.define_singleton_method(:cache_component_modified_time) { "1000" }
      assert klass.new(name_attr: "a").cacheable?
    end

    # ---- cache_key -----------------------------------------------------

    def test_cache_key_differs_across_attr_values
      klass = make_component do
        include ::Vident::Caching
        prop :name_attr, String, default: "x", reader: :public
        with_cache_key :name_attr
      end
      klass.define_singleton_method(:cache_component_modified_time) { "1000" }
      refute_equal klass.new(name_attr: "a").cache_key, klass.new(name_attr: "b").cache_key
    end

    def test_cache_key_stable_for_same_attrs
      klass = make_component do
        include ::Vident::Caching
        prop :name_attr, String, default: "x", reader: :public
        with_cache_key :name_attr
      end
      klass.define_singleton_method(:cache_component_modified_time) { "1000" }
      assert_equal klass.new(name_attr: "x").cache_key, klass.new(name_attr: "x").cache_key
    end

    def test_cache_key_includes_class_name
      klass = make_component(name: "CardComponent") do
        include ::Vident::Caching
        prop :name_attr, String, default: "x", reader: :public
        with_cache_key :name_attr
      end
      klass.define_singleton_method(:cache_component_modified_time) { "1000" }
      assert_match(/CardComponent/, klass.new(name_attr: "a").cache_key)
    end

    # ---- depends_on chains mtimes --------------------------------------

    def test_depends_on_folds_dependency_mtime_into_component_modified_time
      dep = make_component(name: "DepComponent") do
        include ::Vident::Caching
      end
      dep.define_singleton_method(:cache_component_modified_time) { "100" }

      klass = make_component(name: "MainComponent") do
        include ::Vident::Caching
      end
      klass.depends_on dep
      klass.define_singleton_method(:cache_component_modified_time) { "200" }

      # Dependency mtime (100) is prepended to own mtime (200).
      assert_match(/100/, klass.component_modified_time)
      assert_match(/200/, klass.component_modified_time)
    end

    def test_component_dependencies_accessor
      dep = make_component(name: "DepComponent") do
        include ::Vident::Caching
      end
      klass = make_component(name: "MainComponent") do
        include ::Vident::Caching
      end
      klass.depends_on dep
      assert_equal [dep], klass.component_dependencies
    end

    # ---- inherited copies component_dependencies ----------------------

    def test_subclass_inherits_parent_component_dependencies
      dep = make_component(name: "DepComponent") do
        include ::Vident::Caching
      end
      dep.define_singleton_method(:cache_component_modified_time) { "50" }

      parent = make_component(name: "ParentComponent") do
        include ::Vident::Caching
      end
      parent.depends_on dep
      parent.define_singleton_method(:cache_component_modified_time) { "100" }

      child = Class.new(parent)
      child.define_singleton_method(:name) { "ChildComponent" }
      child.define_singleton_method(:cache_component_modified_time) { "200" }

      assert_equal parent.component_dependencies, child.component_dependencies
      assert_match(/50/, child.component_modified_time)
    end

    # ---- cache_key_modifier -------------------------------------------

    def test_cache_key_modifier_comes_from_env
      klass = make_component do
        include ::Vident::Caching
      end
      previous = ENV["RAILS_CACHE_ID"]
      ENV["RAILS_CACHE_ID"] = "v42"
      assert_equal "v42", klass.new.cache_key_modifier
    ensure
      ENV["RAILS_CACHE_ID"] = previous
    end

    # ---- cache_component_modified_time raises when source file missing ----

    def test_cache_component_modified_time_raises_configuration_error_when_source_file_missing
      klass = make_component(name: "NoSourceComponent") do
        include ::Vident::Caching
      end
      klass.component_source_file_path = "/nonexistent/path/to/component.rb"
      err = assert_raises(::Vident::ConfigurationError) { klass.cache_component_modified_time }
      assert_match(/No component source file/, err.message)
    end

    def test_cache_component_modified_time_raises_configuration_error_when_path_nil
      klass = make_component(name: "NilSourceComponent") do
        include ::Vident::Caching
      end
      klass.component_source_file_path = nil
      err = assert_raises(::Vident::ConfigurationError) { klass.cache_component_modified_time }
      assert_kind_of ::Vident::ConfigurationError, err
    end

    # ---- component_modified_time raises when method not implemented --------

    def test_component_modified_time_raises_configuration_error_when_method_not_implemented
      klass = make_component(name: "UnimplementedComponent") do
        include ::Vident::Caching
      end
      klass.singleton_class.undef_method(:cache_component_modified_time)
      err = assert_raises(::Vident::ConfigurationError) { klass.component_modified_time }
      assert_match(/cache_component_modified_time/, err.message)
    end

    # ---- generate_cache_key raises when sources resolve to empty ------

    def test_cache_key_raises_when_all_sources_resolve_to_nil
      # Bypasses `with_cache_key` to register a key group where every attr
      # resolves to nil, producing an empty sources array.
      klass = make_component(name: "EmptyKeyComponent") do
        include ::Vident::Caching
        send(:named_cache_key_includes, :_collection, proc {})
      end
      err = assert_raises(::Vident::ConfigurationError) { klass.new.cache_key }
      assert_match(/EmptyKeyComponent/, err.message)
      assert_match(/no cache key sources resolved/, err.message)
    end
  end
end
