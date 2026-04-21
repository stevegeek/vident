# frozen_string_literal: true

require "test_helper"
require "vident2"

class V2TestAttributesComponentTest < Minitest::Test
  def test_can_be_instantiated_with_default_values
    component = V2::TestAttributesComponent.new(initials: "TW")
    assert_equal "World", component.name
    assert_equal "TW", component.initials
    assert_nil component.url
  end

  def test_can_be_instantiated_with_custom_values
    component = V2::TestAttributesComponent.new(
      name: "John",
      initials: "JD",
      url: "https://example.com"
    )
    assert_equal "John", component.name
    assert_equal "JD", component.initials
    assert_equal "https://example.com", component.url
  end

  def test_renders_with_default_values
    component = V2::TestAttributesComponent.new(initials: "TW")
    assert_equal "Hi World", component.call
  end

  def test_renders_with_custom_name_no_url
    component = V2::TestAttributesComponent.new(name: "Alice", initials: "A")
    assert_equal "Hi Alice", component.call
  end

  def test_renders_with_url_as_link
    component = V2::TestAttributesComponent.new(
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
    component = V2::TestAttributesComponent.new(name: "Charlie", initials: "C", url: nil)
    assert_equal "Hi Charlie", component.call
    refute_includes component.call, "<a"
  end

  def test_initials_validation
    assert_equal "AB", V2::TestAttributesComponent.new(initials: "AB").initials

    assert_raises(Literal::TypeError) do
      V2::TestAttributesComponent.new(initials: "")
    end
    assert_raises(Literal::TypeError) do
      V2::TestAttributesComponent.new(initials: nil)
    end
  end

  def test_url_validation
    assert_nil V2::TestAttributesComponent.new(initials: "T", url: nil).url
    assert_equal "https://example.com",
      V2::TestAttributesComponent.new(initials: "T", url: "https://example.com").url

    assert_raises(Literal::TypeError) do
      V2::TestAttributesComponent.new(initials: "T", url: "")
    end
  end
end
