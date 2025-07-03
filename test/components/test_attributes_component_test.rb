require "test_helper"

class TestAttributesComponentTest < Minitest::Test
  def test_can_be_instantiated_with_default_values
    component = TestAttributesComponent.new(initials: "TW")
    
    assert_equal "World", component.name
    assert_equal "TW", component.initials
    assert_nil component.url
  end

  def test_can_be_instantiated_with_custom_values
    component = TestAttributesComponent.new(
      name: "John",
      initials: "JD",
      url: "https://example.com"
    )
    
    assert_equal "John", component.name
    assert_equal "JD", component.initials
    assert_equal "https://example.com", component.url
  end

  def test_renders_with_default_values
    component = TestAttributesComponent.new(initials: "TW")
    result = component.call
    
    assert_equal "Hi World", result
  end

  def test_renders_with_custom_name_no_url
    component = TestAttributesComponent.new(name: "Alice", initials: "A")
    result = component.call
    
    assert_equal "Hi Alice", result
  end

  def test_renders_with_url_as_link
    component = TestAttributesComponent.new(
      name: "Bob", 
      initials: "B",
      url: "https://example.com"
    )
    result = component.call
    
    # Should render as a link when URL is present
    assert_includes result, '<a href="https://example.com">'
    assert_includes result, "Hi Bob"
    assert_includes result, "</a>"
  end

  def test_renders_without_url_as_plain_text
    component = TestAttributesComponent.new(name: "Charlie", initials: "C", url: nil)
    result = component.call
    
    # Should render as plain text when URL is nil
    assert_equal "Hi Charlie", result
    refute_includes result, "<a"
  end

  def test_renders_without_url_as_plain_text_when_empty_string
    component = TestAttributesComponent.new(name: "Dave", initials: "D", url: "")
    result = component.call
    
    # Should render as plain text when URL is empty string
    assert_equal "Hi Dave", result
    refute_includes result, "<a"
  end

  def test_initials_validation
    # Should accept non-empty string
    component = TestAttributesComponent.new(initials: "AB")
    assert_equal "AB", component.initials

    # Should reject empty string during validation (if validation is enforced)
    # Note: This depends on how Literal validation works with _String(&:present?)
  end

  def test_url_validation
    # Should accept nil
    component = TestAttributesComponent.new(initials: "T", url: nil)
    assert_nil component.url

    # Should accept non-empty string
    component = TestAttributesComponent.new(initials: "T", url: "https://example.com")
    assert_equal "https://example.com", component.url
  end
end