module ViewComponent
  class AvatarComponent < ::Vident::ViewComponent::Base
    include Vident::Caching

    no_stimulus_controller
    with_cache_key

    prop :url, _Nilable(String), predicate: :private, reader: :public
    prop :initials, String, reader: :public

    prop :shape, Symbol, default: :circle, reader: :public

    prop :border, _Boolean, default: false, predicate: :private, reader: :public

    prop :size, Symbol, default: :normal, reader: :public

    private

    def root_element_attributes
      {
        element_tag: image_avatar? ? :img : :div,
        html_options: default_html_options
      }
    end

    def default_html_options
      if image_avatar?
        {class: "inline-block object-contain", src: @url, alt: t(".image")}
      else
        {class: "inline-flex items-center justify-center bg-gray-500"}
      end
    end

    def element_classes
      [size_classes, shape_class, border? ? "border" : ""]
    end

    alias_method :image_avatar?, :url?

    def shape_class
      (@shape == :circle) ? "rounded-full" : "rounded-md"
    end

    def size_classes
      case @size
      when :tiny
        "w-6 h-6"
      when :small
        "w-8 h-8"
      when :medium
        "w-12 h-12"
      when :large
        "w-14 h-14"
      when :x_large
        "sm:w-24 sm:h-24 w-16 h-16"
      when :xx_large
        "sm:w-32 sm:h-32 w-24 h-24"
      else
        "w-10 h-10"
      end
    end

    def text_size_class
      case @size
      when :tiny
        "text-xs"
      when :small
        "text-xs"
      when :medium
        "text-lg"
      when :large
        "sm:text-xl text-lg"
      when :extra_large
        "sm:text-2xl text-xl"
      else
        "text-medium"
      end
    end
  end
end
