# frozen_string_literal: true

require "test_helper"
require "vident"

class PhlexAvatarComponentTest < Minitest::Test
  def test_stimulus_identifier_matches_v1
    assert_equal "phlex/avatar_component",
      Phlex::AvatarComponent.stimulus_identifier_path
    assert_equal "phlex--avatar-component",
      Phlex::AvatarComponent.stimulus_identifier
  end

  def test_no_stimulus_controller_flag
    refute Phlex::AvatarComponent.stimulus_controller?
  end

  def test_public_readers
    component = Phlex::AvatarComponent.new(initials: "JD")
    assert_equal "JD", component.initials
    assert_nil component.url
    assert_equal :circle, component.shape
    assert_equal false, component.border
    assert_equal :normal, component.size
  end

  def test_all_props
    component = Phlex::AvatarComponent.new(
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

  def test_renders_as_img_when_url_given
    html = Phlex::AvatarComponent.new(initials: "JD", url: "https://example.com/a.jpg").call
    assert_match(/<img\b[^>]*src="https:\/\/example\.com\/a\.jpg"/, html)
    assert_match(/class="[^"]*inline-block object-contain[^"]*"/, html)
    assert_match(/class="[^"]*phlex--avatar-component[^"]*"/, html)
    refute_match(/data-controller/, html)
  end

  def test_renders_as_div_with_initials_when_no_url
    html = Phlex::AvatarComponent.new(initials: "AB").call
    assert_match(/<div\b[^>]*class="[^"]*inline-flex[^"]*items-center[^"]*justify-center[^"]*bg-gray-500/, html)
    assert_match(/<span\b[^>]*>AB<\/span>/, html)
    refute_match(/data-controller/, html)
  end

  def test_no_data_controller_emitted
    html = Phlex::AvatarComponent.new(initials: "JD").call
    refute_match(/data-controller/, html)
  end

  def test_shape_class_helper
    circle = Phlex::AvatarComponent.new(initials: "JD", shape: :circle)
    assert_equal "rounded-full", circle.send(:shape_class)

    square = Phlex::AvatarComponent.new(initials: "JD", shape: :square)
    assert_equal "rounded-md", square.send(:shape_class)
  end

  def test_root_element_attributes_for_image_avatar
    component = Phlex::AvatarComponent.new(
      initials: "JD",
      url: "https://example.com/avatar.jpg"
    )
    attributes = component.send(:root_element_attributes)
    assert_equal :img, attributes[:element_tag]
    assert_equal "https://example.com/avatar.jpg", attributes[:html_options][:src]
    assert_equal "Profile image", attributes[:html_options][:alt]
  end

  def test_root_element_attributes_for_text_avatar
    component = Phlex::AvatarComponent.new(initials: "JD")
    attributes = component.send(:root_element_attributes)
    assert_equal :div, attributes[:element_tag]
    refute attributes[:html_options].key?(:src)
    refute attributes[:html_options].key?(:alt)
  end
end
