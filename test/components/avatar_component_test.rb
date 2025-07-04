require "test_helper"

class AvatarComponentTest < Minitest::Test
  def test_can_be_instantiated_with_minimal_required_props
    component = ViewComponent::AvatarComponent.new(initials: "JD")

    assert_equal "JD", component.initials
    assert_nil component.url
    assert_equal :circle, component.shape
    assert_equal false, component.border
    assert_equal :normal, component.size
  end

  def test_can_be_instantiated_with_all_props
    component = ViewComponent::AvatarComponent.new(
      initials: "AB",
      url: "https://example.com/avatar.jpg",
      shape: :square,
      border: true,
      size: :large
    )

    assert_equal "AB", component.initials
    assert_equal "https://example.com/avatar.jpg", component.url
    assert_equal :square, component.shape
    assert_equal true, component.border
    assert_equal :large, component.size
  end

  def test_image_avatar_predicate_method
    # Should return true when URL is present
    component_with_url = ViewComponent::AvatarComponent.new(
      initials: "JD",
      url: "https://example.com/avatar.jpg"
    )
    assert component_with_url.send(:image_avatar?)

    # Should return false when URL is nil
    component_without_url = ViewComponent::AvatarComponent.new(initials: "JD")
    refute component_without_url.send(:image_avatar?)
  end

  def test_shape_class_method
    circle_component = ViewComponent::AvatarComponent.new(initials: "JD", shape: :circle)
    assert_equal "rounded-full", circle_component.send(:shape_class)

    square_component = ViewComponent::AvatarComponent.new(initials: "JD", shape: :square)
    assert_equal "rounded-md", square_component.send(:shape_class)
  end

  def test_size_classes_method
    test_cases = {
      tiny: "w-6 h-6",
      small: "w-8 h-8",
      medium: "w-12 h-12",
      large: "w-14 h-14",
      x_large: "sm:w-24 sm:h-24 w-16 h-16",
      xx_large: "sm:w-32 sm:h-32 w-24 h-24",
      normal: "w-10 h-10",
      unknown: "w-10 h-10"  # default case
    }

    test_cases.each do |size, expected_classes|
      component = ViewComponent::AvatarComponent.new(initials: "JD", size: size)
      assert_equal expected_classes, component.send(:size_classes), "Failed for size: #{size}"
    end
  end

  def test_text_size_class_method
    test_cases = {
      tiny: "text-xs",
      small: "text-xs",
      medium: "text-lg",
      large: "sm:text-xl text-lg",
      extra_large: "sm:text-2xl text-xl",
      normal: "text-medium",
      unknown: "text-medium"  # default case
    }

    test_cases.each do |size, expected_class|
      component = ViewComponent::AvatarComponent.new(initials: "JD", size: size)
      assert_equal expected_class, component.send(:text_size_class), "Failed for size: #{size}"
    end
  end

  def test_element_classes_method
    # Test without border
    component = ViewComponent::AvatarComponent.new(
      initials: "JD",
      size: :medium,
      shape: :circle,
      border: false
    )
    expected_classes = ["w-12 h-12", "rounded-full", ""]
    assert_equal expected_classes, component.send(:element_classes)

    # Test with border
    component_with_border = ViewComponent::AvatarComponent.new(
      initials: "JD",
      size: :large,
      shape: :square,
      border: true
    )
    expected_classes_with_border = ["w-14 h-14", "rounded-md", "border"]
    assert_equal expected_classes_with_border, component_with_border.send(:element_classes)
  end

  def test_default_html_options_for_image_avatar
    component = ViewComponent::AvatarComponent.new(
      initials: "JD",
      url: "https://example.com/avatar.jpg"
    )

    # Mock the translate method to avoid ViewComponent render context issues
    component.define_singleton_method(:t) { |key| "Image" }

    options = component.send(:default_html_options)

    assert_equal "inline-block object-contain", options[:class]
    assert_equal "https://example.com/avatar.jpg", options[:src]
    assert_equal "Image", options[:alt]
  end

  def test_default_html_options_for_text_avatar
    component = ViewComponent::AvatarComponent.new(initials: "JD")

    options = component.send(:default_html_options)

    assert_equal "inline-flex items-center justify-center bg-gray-500", options[:class]
    refute options.key?(:src)
    refute options.key?(:alt)
  end

  def test_root_element_attributes_for_image_avatar
    component = ViewComponent::AvatarComponent.new(
      initials: "JD",
      url: "https://example.com/avatar.jpg"
    )

    # Mock the translate method to avoid ViewComponent render context issues
    component.define_singleton_method(:t) { |key| "Image" }

    attributes = component.send(:root_element_attributes)

    assert_equal :img, attributes[:element_tag]
    assert_kind_of Hash, attributes[:html_options]
    assert_equal "https://example.com/avatar.jpg", attributes[:html_options][:src]
  end

  def test_root_element_attributes_for_text_avatar
    component = ViewComponent::AvatarComponent.new(initials: "JD")

    attributes = component.send(:root_element_attributes)

    assert_equal :div, attributes[:element_tag]
    assert_kind_of Hash, attributes[:html_options]
    refute attributes[:html_options].key?(:src)
  end

  def test_no_stimulus_controller_flag
    # The component should have no stimulus controller due to `no_stimulus_controller` declaration
    refute ViewComponent::AvatarComponent.stimulus_controller?
  end

  def test_border_predicate_methods
    # Test border? predicate method through private predicate
    component_with_border = ViewComponent::AvatarComponent.new(initials: "JD", border: true)
    assert component_with_border.send(:border?)

    component_without_border = ViewComponent::AvatarComponent.new(initials: "JD", border: false)
    refute component_without_border.send(:border?)
  end

  def test_url_predicate_methods
    # Test url? predicate method through private predicate
    component_with_url = ViewComponent::AvatarComponent.new(
      initials: "JD",
      url: "https://example.com/avatar.jpg"
    )
    assert component_with_url.send(:url?)

    component_without_url = ViewComponent::AvatarComponent.new(initials: "JD")
    refute component_without_url.send(:url?)
  end

  def test_caching_included
    # Test that Vident::Caching is included
    assert ViewComponent::AvatarComponent.included_modules.include?(Vident::Caching)
  end
end
