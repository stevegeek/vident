# frozen_string_literal: true

module Vident
  class StimulusBuilder
    # Primitives the DSL block tracks. Controllers are set via the component's
    # `stimulus_controllers:` prop, not the DSL, so they're skipped here.
    # Storage shape per primitive is an Array for positional kinds (actions,
    # targets) and a Hash for keyed kinds (values, params, classes, outlets).
    DSL_PRIMITIVES = Stimulus::PRIMITIVES.reject { |primitive| primitive.name == :controllers }.freeze

    def initialize
      @entries = DSL_PRIMITIVES.to_h { |primitive| [primitive.name, primitive.keyed? ? {} : []] }
      @values_from_props = []
    end

    def merge_with(other)
      DSL_PRIMITIVES.each do |primitive|
        mine = @entries[primitive.name]
        theirs = other.entries_for(primitive.name)
        primitive.keyed? ? mine.merge!(theirs) : mine.concat(theirs)
      end
      @values_from_props.concat(other.values_from_props_list)
      self
    end

    def actions(*names)
      @entries[:actions].concat(names)
      self
    end

    def targets(*names)
      @entries[:targets].concat(names)
      self
    end

    def values(**hash)
      @entries[:values].merge!(hash) unless hash.empty?
      self
    end

    def params(**hash)
      @entries[:params].merge!(hash) unless hash.empty?
      self
    end

    def classes(**hash)
      @entries[:classes].merge!(hash) unless hash.empty?
      self
    end

    def values_from_props(*names)
      @values_from_props.concat(names)
      self
    end

    # `outlets({"admin--users" => ".sel"})` accepts a positional Hash for
    # identifiers that can't be Ruby kwarg keys (contain `--`).
    def outlets(positional = nil, **hash)
      bucket = @entries[:outlets]
      bucket.merge!(positional) if positional.is_a?(Hash)
      bucket.merge!(hash) unless hash.empty?
      self
    end

    def to_attributes(component_instance)
      attrs = {}
      DSL_PRIMITIVES.each do |primitive|
        entries = @entries[primitive.name]
        next if entries.empty?
        attrs[primitive.key] = resolve_entries(primitive, entries, component_instance)
      end
      attrs[:stimulus_values_from_props] = @values_from_props.dup unless @values_from_props.empty?
      attrs
    end

    def to_hash(component_instance) = to_attributes(component_instance)
    alias_method :to_h, :to_hash

    protected

    def entries_for(name) = @entries[name]

    def values_from_props_list = @values_from_props

    private

    # Outlets don't support procs — static merge only. The other keyed kinds
    # and the positional (Array-shaped) kinds resolve procs in the component
    # instance and drop nil results.
    def resolve_entries(primitive, entries, component_instance)
      return entries.dup if primitive.name == :outlets

      if primitive.keyed?
        resolve_hash_filtering_nil(entries, component_instance)
      else
        resolve_array_filtering_nil(entries, component_instance)
      end
    end

    def resolve_array_filtering_nil(array, component_instance)
      array.each_with_object([]) do |value, out|
        resolved = callable?(value) ? component_instance.instance_exec(&value) : value
        out << resolved unless resolved.nil?
      end
    end

    # Dropping nil matters because Stimulus's Boolean value parser reads an
    # empty data attribute as `true` — so `-> { flag? || nil }` would silently
    # flip a Boolean value on. Omitting the entry keeps the attribute off.
    def resolve_hash_filtering_nil(hash, component_instance)
      hash.each_with_object({}) do |(key, value), out|
        resolved = callable?(value) ? component_instance.instance_exec(&value) : value
        out[key] = resolved unless resolved.nil?
      end
    end

    def callable?(value) = value.respond_to?(:call)
  end
end
