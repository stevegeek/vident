# frozen_string_literal: true

module Vident
  class StimulusBuilder
    def initialize
      @actions = []
      @targets = []
      @values = {}
      @values_from_props = []
      @classes = {}
      @outlets = {}
    end

    def merge_with(other_builder)
      @actions.concat(other_builder.actions_list)
      @targets.concat(other_builder.targets_list)
      @values.merge!(other_builder.values_hash)
      @values_from_props.concat(other_builder.values_from_props_list)
      @classes.merge!(other_builder.classes_hash)
      @outlets.merge!(other_builder.outlets_hash)
      self
    end

    def actions(*action_names)
      @actions.concat(action_names)
      self
    end

    def targets(*target_names)
      @targets.concat(target_names)
      self
    end

    def values(**value_hash)
      @values.merge!(value_hash) unless value_hash.empty?
      self
    end
    
    def values_from_props(*prop_names)
      @values_from_props.concat(prop_names)
      self
    end

    def classes(**class_mappings)
      @classes.merge!(class_mappings)
      self
    end

    def outlets(**outlet_mappings)
      @outlets.merge!(outlet_mappings) unless outlet_mappings.empty?
      self
    end

    def to_attributes(component_instance)
      attrs = {}
      attrs[:stimulus_actions] = resolve_attributes_filtering_nil(@actions, component_instance) unless @actions.empty?
      attrs[:stimulus_targets] = resolve_attributes_filtering_nil(@targets, component_instance) unless @targets.empty?
      attrs[:stimulus_values] = resolve_hash_values_allowing_nil(@values, component_instance) unless @values.empty?
      attrs[:stimulus_values_from_props] = @values_from_props.dup unless @values_from_props.empty?
      attrs[:stimulus_classes] = resolve_hash_classes_filtering_nil(@classes, component_instance) unless @classes.empty?
      attrs[:stimulus_outlets] = @outlets.dup unless @outlets.empty?
      attrs
    end

    def to_hash(component_instance)
      to_attributes(component_instance)
    end
    alias_method :to_h, :to_hash

    protected

    def actions_list
      @actions
    end

    def targets_list
      @targets
    end

    def values_hash
      @values
    end

    def values_from_props_list
      @values_from_props
    end

    def classes_hash
      @classes
    end

    def outlets_hash
      @outlets
    end

    private

    # For actions, targets - filter out nil values from procs AND static
    def resolve_attributes_filtering_nil(array, component_instance)
      result = []
      array.each do |value|
        if callable?(value)
          resolved_value = component_instance.instance_exec(&value)
          # Exclude nil from procs (nil is not valid for actions/targets)
          result << resolved_value unless resolved_value.nil?
        else
          # Exclude static nil values (nil is not valid for actions/targets)
          result << value unless value.nil?
        end
      end
      result
    end

    # For values - allow nil values from procs and static (will become "null" in JavaScript)
    def resolve_hash_values_allowing_nil(hash, component_instance)
      hash.transform_values { |value| callable?(value) ? component_instance.instance_exec(&value) : value }
    end

    # For classes - filter out nil values from procs AND static
    def resolve_hash_classes_filtering_nil(hash, component_instance)
      result = {}
      hash.each do |key, value|
        if callable?(value)
          resolved_value = component_instance.instance_exec(&value)
          # Exclude nil from procs (nil is not valid for classes)
          result[key] = resolved_value unless resolved_value.nil?
        else
          # Exclude static nil values (nil is not valid for classes)
          result[key] = value unless value.nil?
        end
      end
      result
    end

    def callable?(value)
      value.respond_to?(:call)
    end
  end
end