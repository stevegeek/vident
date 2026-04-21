# frozen_string_literal: true

require "digest/sha1"

module Vident2
  # Fragment-caching opt-in. Include into a component to get `cacheable?`,
  # `cache_key`, and the `with_cache_key` / `depends_on` class helpers.
  #
  # `cache_component_modified_time` lives on the adapter base class
  # (Phlex: `.rb` mtime; VC: sidecar template + `.rb` mtime).
  module Caching
    extend ActiveSupport::Concern

    class_methods do
      def inherited(subclass)
        subclass.instance_variable_set(:@named_cache_key_attributes, @named_cache_key_attributes&.clone)
        super
      end

      def with_cache_key(*attrs, name: :_collection)
        attrs << :component_modified_time
        attrs << :to_h if respond_to?(:to_h)
        named_cache_key_includes(name, *attrs.uniq)
      end

      attr_reader :named_cache_key_attributes

      def depends_on(*klasses)
        @component_dependencies ||= []
        @component_dependencies += klasses
      end

      attr_reader :component_dependencies

      def component_modified_time
        return @component_modified_time if defined?(::Rails) && ::Rails.env.production? && @component_modified_time

        raise StandardError, "Must implement cache_component_modified_time" unless respond_to?(:cache_component_modified_time)

        deps = component_dependencies&.map(&:component_modified_time)&.join("-") || ""
        @component_modified_time = deps + cache_component_modified_time
      end

      private

      def named_cache_key_includes(name, *attrs)
        define_cache_key_method unless @named_cache_key_attributes
        @named_cache_key_attributes ||= {}
        @named_cache_key_attributes[name] = attrs
      end

      def define_cache_key_method
        define_method :cache_key do |n = :_collection|
          if defined?(@cache_key)
            return @cache_key[n] if @cache_key.key?(n)
          else
            @cache_key ||= {}
          end
          generate_cache_key(n)
          @cache_key[n]
        end
      end
    end

    def component_modified_time = self.class.component_modified_time

    def cacheable? = respond_to?(:cache_key)

    def cache_key_modifier = ENV["RAILS_CACHE_ID"]

    def cache_keys_for_sources(key_attributes)
      sources = key_attributes.flat_map { |n| n.is_a?(Proc) ? instance_eval(&n) : send(n) }
      sources.compact.filter_map { |item| generate_item_cache_key_from(item) unless item == self }
    end

    def generate_item_cache_key_from(item)
      if item.respond_to? :cache_key_with_version
        item.cache_key_with_version
      elsif item.respond_to? :cache_key
        item.cache_key
      elsif item.is_a?(String)
        Digest::SHA1.hexdigest(item)
      else
        Digest::SHA1.hexdigest(Marshal.dump(item))
      end
    end

    def generate_cache_key(index)
      key_attributes = self.class.named_cache_key_attributes[index]
      return nil unless key_attributes
      key = "#{self.class.name}/#{cache_keys_for_sources(key_attributes).join("/")}"
      raise StandardError, "Cache key for key #{key} is blank!" if key.blank?
      @cache_key[index] = cache_key_modifier.present? ? "#{key}/#{cache_key_modifier}" : key
    end
  end
end
