require "test_helper"

class Vident::ViewComponent::CachingTest < ActiveSupport::TestCase
  test "it has a version number" do
    assert Vident::ViewComponent::Caching::VERSION
  end
end
