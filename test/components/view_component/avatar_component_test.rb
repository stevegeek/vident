# frozen_string_literal: true

require "test_helper"
require "vident"

class ViewComponentAvatarComponentTest < Minitest::Test
  def test_stimulus_identifier_matches_v1
    assert_equal "view_component/avatar_component",
      ViewComponent::AvatarComponent.stimulus_identifier_path
    assert_equal "view-component--avatar-component",
      ViewComponent::AvatarComponent.stimulus_identifier
  end

  def test_no_stimulus_controller_flag
    refute ViewComponent::AvatarComponent.stimulus_controller?
  end

  def test_public_readers_default
    component = ViewComponent::AvatarComponent.new(initials: "JD")
    assert_equal "JD", component.initials
    assert_nil component.url
    assert_equal :circle, component.shape
    assert_equal false, component.border
    assert_equal :normal, component.size
  end

  def test_public_readers_populated
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

  def test_shape_class
    circle = ViewComponent::AvatarComponent.new(initials: "JD", shape: :circle)
    assert_equal "rounded-full", circle.send(:shape_class)
    square = ViewComponent::AvatarComponent.new(initials: "JD", shape: :square)
    assert_equal "rounded-md", square.send(:shape_class)
  end

  def test_caching_included
    assert ViewComponent::AvatarComponent.included_modules.include?(::Vident::Caching)
  end

  def test_root_element_attributes_for_image_avatar
    component = ViewComponent::AvatarComponent.new(
      initials: "JD",
      url: "https://example.com/avatar.jpg"
    )
    attributes = component.send(:root_element_attributes)
    assert_equal :img, attributes[:element_tag]
    assert_equal "https://example.com/avatar.jpg", attributes[:html_options][:src]
  end

  def test_root_element_attributes_for_text_avatar
    component = ViewComponent::AvatarComponent.new(initials: "JD")
    attributes = component.send(:root_element_attributes)
    assert_equal :div, attributes[:element_tag]
    refute attributes[:html_options].key?(:src)
  end
end

class ViewComponentAvatarComponentRenderTest < ViewComponent::TestCase
  def test_renders_as_img_when_url_given
    render_inline(ViewComponent::AvatarComponent.new(
      initials: "JD",
      url: "https://example.com/a.jpg"
    ))
    assert_selector "img[src='https://example.com/a.jpg']"
    assert_selector "img.inline-block.object-contain"
    assert_selector "img.view-component--avatar-component"
    refute_match(%r{</img>}, rendered_content)
  end

  def test_renders_as_div_with_initials_when_no_url
    render_inline(ViewComponent::AvatarComponent.new(initials: "JD"))
    assert_selector "div.inline-flex.items-center.justify-center.bg-gray-500"
    assert_selector "div > span", text: "JD"
  end

  def test_no_stimulus_controller_emitted
    render_inline(ViewComponent::AvatarComponent.new(initials: "JD"))
    refute_match(/data-controller/, rendered_content)
    refute_selector "[data-controller]"
  end
end
