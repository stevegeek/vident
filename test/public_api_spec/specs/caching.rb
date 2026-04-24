# frozen_string_literal: true

module Vident
  module PublicApiSpec
    # Covers: Vident::Caching public API — include to opt in, with_cache_key
    # to declare cache-key attributes, depends_on to chain sub-component
    # mtimes, cacheable? predicate, component_modified_time class method,
    # and cache_key instance method.
    #
    # Note: cache_component_modified_time lives on the adapter base class
    # (Phlex: .rb mtime; VC: sidecar template + .rb mtime). For anonymous
    # test classes, component_source_file_path is set via the inherited
    # hook when the anonymous class is defined, and points into this file.
    module Caching
      # ---- cacheable? predicate ------------------------------------------

      def test_component_without_caching_include_is_not_cacheable
        klass = define_component(name: "ButtonComponent")
        refute_respond_to klass.new, :cacheable?
      end

      def test_component_with_caching_opts_in
        klass = define_component(name: "ButtonComponent") do
          include ::Vident::Caching
          prop :title, String, default: "x", reader: :public
          with_cache_key :title
        end
        comp = klass.new(title: "a")
        assert_respond_to comp, :cacheable?
        assert comp.cacheable?
      end

      # ---- with_cache_key + cache_key ------------------------------------

      def test_with_cache_key_defines_cache_key_method
        klass = define_component(name: "CardComponent") do
          include ::Vident::Caching
          prop :title, String, default: "x", reader: :public
          with_cache_key :title
        end
        assert_respond_to klass.new(title: "a"), :cache_key
      end

      def test_cache_key_differs_when_attr_differs
        klass = define_component(name: "CardComponent") do
          include ::Vident::Caching
          prop :title, String, default: "x", reader: :public
          with_cache_key :title
        end
        klass.define_singleton_method(:cache_component_modified_time) { "1000" }
        refute_equal klass.new(title: "a").cache_key, klass.new(title: "b").cache_key
      end

      def test_cache_key_is_stable_for_same_attrs
        klass = define_component(name: "CardComponent") do
          include ::Vident::Caching
          prop :title, String, default: "x", reader: :public
          with_cache_key :title
        end
        klass.define_singleton_method(:cache_component_modified_time) { "1000" }
        assert_equal klass.new(title: "same").cache_key, klass.new(title: "same").cache_key
      end

      def test_cache_key_includes_class_name
        klass = define_component(name: "CardComponent") do
          include ::Vident::Caching
          prop :title, String, default: "x", reader: :public
          with_cache_key :title
        end
        klass.define_singleton_method(:cache_component_modified_time) { "1000" }
        assert_match(/CardComponent/, klass.new(title: "a").cache_key)
      end

      # ---- component_modified_time --------------------------------------

      # SPEC-NOTE: cache_component_modified_time on VC adapter reads the
      # sidecar template path via Pathname.join(path, virtual_path), and
      # anonymous test classes have nil virtual_path. Phlex reads the .rb
      # source file via caller_locations in its inherited hook — fine for
      # anonymous classes. To keep tests adapter-agnostic, we stub
      # cache_component_modified_time on the anonymous class below.

      def test_component_modified_time_is_a_string
        klass = define_component(name: "CardComponent") do
          include ::Vident::Caching
          prop :title, String, default: "x", reader: :public
          with_cache_key :title
        end
        klass.define_singleton_method(:cache_component_modified_time) { "1234567890" }
        assert_kind_of String, klass.component_modified_time
        assert_equal klass.component_modified_time, klass.new(title: "a").component_modified_time
      end

      # ---- depends_on ---------------------------------------------------

      def test_depends_on_chains_component_modified_times
        dep = define_component(name: "DepComponent") do
          include ::Vident::Caching
          prop :x, String, default: "x", reader: :public
          with_cache_key :x
        end
        dep.define_singleton_method(:cache_component_modified_time) { "100" }

        klass = define_component(name: "MainComponent")
        klass.class_eval do
          include ::Vident::Caching
          prop :y, String, default: "y", reader: :public
          depends_on dep
          with_cache_key :y
        end
        klass.define_singleton_method(:cache_component_modified_time) { "200" }

        assert_match(dep.component_modified_time, klass.component_modified_time)
      end

      def test_component_dependencies_accessor
        dep = define_component(name: "DepComponent") do
          include ::Vident::Caching
          prop :x, String, default: "x", reader: :public
          with_cache_key :x
        end
        klass = define_component(name: "MainComponent")
        klass.class_eval do
          include ::Vident::Caching
          depends_on dep
        end
        assert_equal [dep], klass.component_dependencies
      end

      # ---- cache_key_modifier --------------------------------------------

      def test_cache_key_modifier_comes_from_env
        klass = define_component(name: "CardComponent") do
          include ::Vident::Caching
          prop :title, String, default: "x", reader: :public
          with_cache_key :title
        end
        previous = ENV["RAILS_CACHE_ID"]
        ENV["RAILS_CACHE_ID"] = "v42"
        assert_equal "v42", klass.new(title: "a").cache_key_modifier
      ensure
        ENV["RAILS_CACHE_ID"] = previous
      end

      # ---- cache_component ---------------------------------------------

      def test_cache_component_raises_when_component_is_not_cacheable
        klass = define_component(name: "ButtonComponent")
        define_render(klass) { cache_component { plain "body" } }
        err = assert_raises(::Vident::ConfigurationError) { render(klass.new) }
        assert_match(/not cacheable/, err.message)
        assert_match(/with_cache_key/, err.message)
      end
    end
  end
end
