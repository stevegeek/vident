# frozen_string_literal: true

module Vident
  module Base
    extend ActiveSupport::Concern

    class_methods do
      def no_stimulus_controller
        @no_stimulus_controller = true
      end

      def stimulus_controller?
        !@no_stimulus_controller
      end

      # The "name" of the component from its class name and namespace. This is used to generate a HTML class name
      # that can helps identify the component type in the DOM or for styling purposes.
      def component_name
        @component_name ||= stimulus_identifier
      end

      def slots?
        registered_slots.present?
      end

      # TODO: move stuff related to cache key to a module

      # TypedComponents can be used with fragment caching, but you need to be careful! Read on...
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

      def with_cache_key(*attrs, name: :_collection)
        raise StandardError, "with_cache_key can only be used on components *without* slots as there is no eary way to track their content changes so too risky" if slots?
        # Add view file to cache key
        attrs << :component_modified_time
        super
      end

      def component_modified_time
        return @component_modified_time if Rails.env.production? && @component_modified_time
        # FIXME: This could stack overflow if there are circular dependencies
        deps = component_dependencies&.map(&:component_modified_time)&.join("-") || ""
        @component_modified_time = deps + sidecar_view_modified_time + rb_component_modified_time
      end

      def sidecar_view_modified_time
        return @sidecar_view_modified_time if Rails.env.production? && defined?(@sidecar_view_modified_time)
        @sidecar_view_modified_time = ::File.exist?(template_path) ? ::File.mtime(template_path).to_i.to_s : ""
      end

      def rb_component_modified_time
        return @rb_component_modified_time if Rails.env.production? && defined?(@rb_component_modified_time)
        @rb_component_modified_time = ::File.exist?(component_path) ? ::File.mtime(component_path).to_i.to_s : ""
      end

      def template_path
        File.join components_base_path, "#{virtual_path}.html.erb"
      end

      def component_path
        File.join components_base_path, "#{virtual_path}.rb"
      end

      def components_base_path
        ::Rails.configuration.view_component.view_component_path || "app/components"
      end

      # Dont check collection params, we use kwargs
      def validate_collection_parameter!(validate_default: false)
      end

      # stimulus controller identifier
      def stimulus_identifier
        stimulus_identifier_from_path(identifier_name_path)
      end

      def identifier_name_path
        if ancestors.include?(Phlex::HTML)
          name.remove("Views::").underscore
        else
          name.underscore
        end
      end

      def stimulus_identifier_from_path(path)
        path.split("/").map { |p| p.to_s.dasherize }.join("--")
      end

      private

      # Define reader & presence check method, for performance use ivar directly
      def define_attribute_delegate(attr_name)
        class_eval(<<-RUBY, __FILE__, __LINE__ + 1)
          def #{attr_name}
            #{@attribute_ivar_names[attr_name]}
          end

          def #{attr_name}?
            #{@attribute_ivar_names[attr_name]}.present?
          end
        RUBY
      end
    end

    def prepare_attributes(attributes)
      raise NotImplementedError
    end

    # Override this method to perform any initialisation before attributes are set
    def before_initialise(_attrs)
    end

    # Override this method to perform any initialisation after attributes are set
    def after_initialise
    end

    def clone(overrides = {})
      new_set = to_hash.merge(**overrides)
      self.class.new(**new_set)
    end

    def inspect(klass_name = "Component")
      attr_text = attributes.map { |k, v| "#{k}=#{v.inspect}" }.join(", ")
      "#<#{self.class.name}<Vident::#{klass_name}> #{attr_text}>"
    end

    # Generate a unique ID for a component, can be overridden as required. Makes it easier to setup things like ARIA
    # attributes which require elements to reference by ID. Note this overrides the `id` accessor
    def id
      @id.presence || random_id
    end

    # Methods to use in component views
    # ---------------------------------

    delegate :params, to: :helpers

    # HTML and attribute definition and creation

    # Helper to create the main element
    def parent_element(**options)
      @parent_element ||= begin
        # Note: we cant mix phlex and view_component render contexts
        klass = if self.class.ancestors.include?(Phlex::HTML)
          RootComponent::UsingPhlexHTML
        else
          RootComponent::UsingViewComponent
        end
        klass.new(**stimulus_options_for_component(options))
      end
    end
    alias_method :root, :parent_element

    # This can be overridden to return an array of extra class names
    def element_classes
    end

    # A HTML class name that can helps identify the component type in the DOM or for styling purposes.
    def component_class_name
      self.class.component_name
    end
    alias_method :js_event_name_prefix, :component_class_name

    # Generates the full list of HTML classes for the component
    def render_classes(erb_defined_classes = nil)
      # TODO: avoid pointless creation of arrays
      base_classes = [component_class_name] + Array.wrap(element_classes)
      base_classes += Array.wrap(erb_defined_classes) if erb_defined_classes
      classes_on_component = attribute(:html_options)&.fetch(:class, nil)
      base_classes += Array.wrap(classes_on_component) if classes_on_component
      produce_style_classes(base_classes)
    end

    def stimulus_identifier
      self.class.stimulus_identifier
    end

    # TODO: Move to caching module
    # Component modified time which is combined with other cache key attributes to generate cache key for an instance
    def component_modified_time
      self.class.component_modified_time
    end

    # The `component` class name is used to create the controller name.
    # The path of the Stimulus controller when none is explicitly set
    def default_controller_path
      self.class.identifier_name_path
    end

    protected

    # Prepare the stimulus attributes for a StimulusComponent
    def stimulus_options_for_component(options)
      {
        **options.except(:id, :element_tag, :html_options, :controller, :controllers, :actions, :targets, :named_classes, :data_maps),
        id: respond_to?(:id) ? id : (attribute(:id) || options[:id]),
        element_tag: attribute(:element_tag) || options[:element_tag] || :div,
        html_options: prepare_html_options(options[:html_options]),
        controllers: (
          self.class.stimulus_controller? ? [default_controller_path] : []
        ) + Array.wrap(options[:controllers]) + attribute(:controllers),
        actions: attribute(:actions) + Array.wrap(options[:actions]),
        targets: attribute(:targets) + Array.wrap(options[:targets]),
        named_classes: merge_stimulus_option(options, :named_classes),
        data_maps: prepare_stimulus_option(options, :data_maps)
      }
    end

    private

    def prepare_html_options(erb_options)
      # Options should override in this order:
      # - defined on component class methods (lowest priority)
      # - defined by passing to component erb
      # - defined by passing to component constructor (highest priority)
      options = erb_options&.except(:class) || {}
      classes_from_view = Array.wrap(erb_options[:class]) if erb_options&.key?(:class)
      options[:class] = render_classes(classes_from_view)
      options.merge!(attribute(:html_options).except(:class)) if attribute(:html_options)
      options
    end

    # TODO: deprecate the ability to set via method on class (responds_to?) and just use component attributes
    # or attributes passed to parent_element
    def prepare_stimulus_option(options, name)
      resolved = respond_to?(name) ? Array.wrap(send(name)) : []
      resolved.concat(Array.wrap(attribute(name)))
      resolved.concat(Array.wrap(options[name]))
      resolved
    end

    def merge_stimulus_option(options, name)
      (attribute(name) || {}).merge(options[name] || {})
    end

    def produce_style_classes(class_names)
      dedupe_view_component_classes(class_names)
    end

    def template_path
      self.class.template_path
    end

    def random_id
      @random_id ||= "#{self.class.component_name}-#{StableId.next_id_in_sequence}"
    end

    CLASSNAME_SEPARATOR = " "

    # Join all the various class definisions possible and dedupe
    def dedupe_view_component_classes(html_classes)
      html_classes.reject!(&:blank?)

      # Join, then dedupe.
      # This ensures that entries from the classes array such as "a b", "a", "b" are correctly deduped.
      # Note we are trying to do this with less allocations to avoid GC churn
      # classes = classes.join(" ").split(" ").uniq
      html_classes.map! { |x| x.include?(CLASSNAME_SEPARATOR) ? x.split(CLASSNAME_SEPARATOR) : x }
        .flatten!
      html_classes.uniq!
      html_classes.present? ? html_classes.join(CLASSNAME_SEPARATOR) : nil
    end
  end
end
