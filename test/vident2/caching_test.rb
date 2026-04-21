# frozen_string_literal: true

require "test_helper"
require "vident2"

module Vident2
  # Mirrors the V1 Caching surface: opt-in via `include Vident2::Caching`,
  # `with_cache_key` declares attrs, `depends_on` chains mtimes, and
  # `cache_key` returns a stable deterministic key.
  class CachingTest < Minitest::Test
    def make_component(name: "ButtonComponent", &block)
      klass = Class.new(::Vident2::Phlex::HTML)
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
        include ::Vident2::Caching
        prop :name_attr, String, default: "x", reader: :public
        with_cache_key :name_attr
      end
      klass.define_singleton_method(:cache_component_modified_time) { "1000" }
      assert klass.new(name_attr: "a").cacheable?
    end

    # ---- cache_key -----------------------------------------------------

    def test_cache_key_differs_across_attr_values
      klass = make_component do
        include ::Vident2::Caching
        prop :name_attr, String, default: "x", reader: :public
        with_cache_key :name_attr
      end
      klass.define_singleton_method(:cache_component_modified_time) { "1000" }
      refute_equal klass.new(name_attr: "a").cache_key, klass.new(name_attr: "b").cache_key
    end

    def test_cache_key_stable_for_same_attrs
      klass = make_component do
        include ::Vident2::Caching
        prop :name_attr, String, default: "x", reader: :public
        with_cache_key :name_attr
      end
      klass.define_singleton_method(:cache_component_modified_time) { "1000" }
      assert_equal klass.new(name_attr: "x").cache_key, klass.new(name_attr: "x").cache_key
    end

    def test_cache_key_includes_class_name
      klass = make_component(name: "CardComponent") do
        include ::Vident2::Caching
        prop :name_attr, String, default: "x", reader: :public
        with_cache_key :name_attr
      end
      klass.define_singleton_method(:cache_component_modified_time) { "1000" }
      assert_match(/CardComponent/, klass.new(name_attr: "a").cache_key)
    end

    # ---- depends_on chains mtimes --------------------------------------

    def test_depends_on_folds_dependency_mtime_into_component_modified_time
      dep = make_component(name: "DepComponent") do
        include ::Vident2::Caching
      end
      dep.define_singleton_method(:cache_component_modified_time) { "100" }

      klass = make_component(name: "MainComponent") do
        include ::Vident2::Caching
      end
      klass.depends_on dep
      klass.define_singleton_method(:cache_component_modified_time) { "200" }

      # Dependency mtime (100) is prepended to own mtime (200).
      assert_match(/100/, klass.component_modified_time)
      assert_match(/200/, klass.component_modified_time)
    end

    def test_component_dependencies_accessor
      dep = make_component(name: "DepComponent") do
        include ::Vident2::Caching
      end
      klass = make_component(name: "MainComponent") do
        include ::Vident2::Caching
      end
      klass.depends_on dep
      assert_equal [dep], klass.component_dependencies
    end

    # ---- cache_key_modifier -------------------------------------------

    def test_cache_key_modifier_comes_from_env
      klass = make_component do
        include ::Vident2::Caching
      end
      previous = ENV["RAILS_CACHE_ID"]
      ENV["RAILS_CACHE_ID"] = "v42"
      assert_equal "v42", klass.new.cache_key_modifier
    ensure
      ENV["RAILS_CACHE_ID"] = previous
    end
  end
end
