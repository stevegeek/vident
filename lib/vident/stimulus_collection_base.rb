# frozen_string_literal: true

module Vident
  class StimulusCollectionBase
    def initialize(items = [])
      @items = Array(items).flatten.compact
    end

    def <<(item)
      @items << item
      self
    end

    def to_h
      raise NoMethodError, "Subclasses must implement to_h"
    end

    def to_a
      @items.dup
    end

    def to_hash
      to_h
    end

    def empty?
      @items.empty?
    end

    def any?
      !empty?
    end

    def merge(*other_collections)
      merged = self.class.new
      merged.instance_variable_set(:@items, @items.dup)

      other_collections.each do |collection|
        next unless collection.is_a?(self.class)
        merged.instance_variable_get(:@items).concat(collection.instance_variable_get(:@items))
      end

      merged
    end

    def self.merge(*collections)
      return new if collections.empty?

      first_collection = collections.first
      return first_collection if collections.size == 1

      first_collection.merge(*collections[1..-1])
    end

    protected

    attr_reader :items
  end
end
