# frozen_string_literal: true

module Vident
  # Rails fragment caching works by either expecting the cached key object to respond to `cache_key` or for that object
  # to be an array or hash.
  module Caching
    extend ActiveSupport::Concern

    class_methods do
      def inherited(subclass)
        subclass.instance_variable_set(:@named_cache_key_attributes, @named_cache_key_attributes.clone)
        super
      end

      def with_cache_key(*attrs, name: :_collection)
        # Add view file to cache key
        attrs << :component_modified_time
        attrs << :attributes
        named_cache_key_includes(name, *attrs.uniq)
      end

      attr_reader :named_cache_key_attributes

      # Components can be used with fragment caching, but you need to be careful! Read on...
      #
      #     <% cache component do %>
      #      <%= render component %>
      #    <% end %>
      #
      # The most important point is that Rails cannot track dependencies on the component itself, so you need to
      # be careful to be explicit on the attributes, and manually specify any sub Viewcomponent dependencies that the
      # component has. The assumption is that the subcomponent takes any attributes from the parent, so the cache key
      # depends on the parent component attributes. Otherwise changes to the parent or sub component views/Ruby class
      # will result in different cache keys too. Of course if you invalidate all cache keys with a modifier on deploy
      # then no need to worry about changing the cache key on component changes, only on attribute/data changes.
      #
      # A big caveat is that the cache key cannot depend on anything related to the view_context of the component (such
      # as `helpers` as the key is created before the rending pipline is invoked (which is when the view_context is set).
      def depends_on(*klasses)
        @component_dependencies ||= []
        @component_dependencies += klasses
      end

      attr_reader :component_dependencies

      def component_modified_time
        return @component_modified_time if Rails.env.production? && @component_modified_time

        raise StandardError, "Must implement current_component_modified_time" unless respond_to?(:current_component_modified_time)

        # FIXME: This could stack overflow if there are circular dependencies
        deps = component_dependencies&.map(&:component_modified_time)&.join("-") || ""
        @component_modified_time = deps + current_component_modified_time
      end

      private

      def named_cache_key_includes(name, *attrs)
        define_cache_key_method unless @named_cache_key_attributes
        @named_cache_key_attributes ||= {}
        @named_cache_key_attributes[name] = attrs
      end

      def define_cache_key_method
        # If the presenter defines cache key setup then define the method. Otherwise Rails assumes this
        # will return a valid key if the class will respond to this
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

    # Component modified time which is combined with other cache key attributes to generate cache key for an instance
    def component_modified_time
      self.class.component_modified_time
    end

    def cacheable?
      respond_to? :cache_key
    end

    def cache_key_modifier
      ENV["RAILS_CACHE_ID"]
    end

    def cache_keys_for_sources(key_attributes)
      sources = key_attributes.flat_map { |n| n.is_a?(Proc) ? instance_eval(&n) : send(n) }
      sources.compact.map do |item|
        next if item == self
        generate_item_cache_key_from(item)
      end
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
