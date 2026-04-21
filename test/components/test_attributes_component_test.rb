# frozen_string_literal: true

require "test_helper"
require "vident"

class TestAttributesComponentTest < Minitest::Test
  def test_can_be_instantiated_with_default_values
    component = ::TestAttributesComponent.new(initials: "TW")
    assert_equal "World", component.name
    assert_equal "TW", component.initials
    assert_nil component.url
  end

  def test_can_be_instantiated_with_custom_values
    component = ::TestAttributesComponent.new(
      name: "John",
      initials: "JD",
      url: "https://example.com"
    )
    assert_equal "John", component.name
    assert_equal "JD", component.initials
    assert_equal "https://example.com", component.url
  end

  def test_renders_with_default_values
    component = ::TestAttributesComponent.new(initials: "TW")
    assert_equal "Hi World", component.call
  end

  def test_renders_with_custom_name_no_url
    component = ::TestAttributesComponent.new(name: "Alice", initials: "A")
    assert_equal "Hi Alice", component.call
  end

  def test_renders_with_url_as_link
    component = ::TestAttributesComponent.new(
      name: "Bob",
      initials: "B",
      url: "https://example.com"
    )
    result = component.call
    assert_includes result, '<a href="https://example.com">'
    assert_includes result, "Hi Bob"
    assert_includes result, "</a>"
  end

  def test_renders_without_url_as_plain_text
    component = ::TestAttributesComponent.new(name: "Charlie", initials: "C", url: nil)
    assert_equal "Hi Charlie", component.call
    refute_includes component.call, "<a"
  end

  def test_initials_validation
    assert_equal "AB", ::TestAttributesComponent.new(initials: "AB").initials

    assert_raises(Literal::TypeError) do
      ::TestAttributesComponent.new(initials: "")
    end
    assert_raises(Literal::TypeError) do
      ::TestAttributesComponent.new(initials: nil)
    end
  end

  def test_url_validation
    assert_nil ::TestAttributesComponent.new(initials: "T", url: nil).url
    assert_equal "https://example.com",
      ::TestAttributesComponent.new(initials: "T", url: "https://example.com").url

    assert_raises(Literal::TypeError) do
      ::TestAttributesComponent.new(initials: "T", url: "")
    end
  end
end
