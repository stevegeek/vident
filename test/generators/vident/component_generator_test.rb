# frozen_string_literal: true

require "test_helper"
require "rails/generators/test_case"
require "generators/vident/component/component_generator"

class Vident::Generators::ComponentGeneratorTest < Rails::Generators::TestCase
  tests Vident::Generators::ComponentGenerator
  destination File.expand_path("../../tmp/generators", __dir__)
  setup :prepare_destination

  def test_errors_when_engine_ambiguous_and_no_flag
    skip "needs both engines loaded" unless defined?(::Vident::Phlex::HTML) && defined?(::Vident::ViewComponent::Base)

    output = capture(:stderr) { run_generator ["Card"] }
    assert_match(/Both vident-phlex and vident-view_component/, output)
  end

  def test_dispatches_to_phlex_with_engine_flag
    run_generator ["Card", "--engine=phlex"]

    assert_file "app/components/card_component.rb" do |contents|
      assert_match(/class CardComponent < ApplicationPhlexComponent/, contents)
    end
  end

  def test_dispatches_to_view_component_with_engine_flag
    run_generator ["Card", "--engine=view_component"]

    assert_file "app/components/card_component.rb" do |contents|
      assert_match(/class CardComponent < ApplicationViewComponent/, contents)
    end
    assert_file "app/components/card_component.html.erb"
  end

  def test_unknown_engine_errors
    output = capture(:stderr) { run_generator ["Card", "--engine=hanami"] }
    assert_match(/Unknown engine/, output)
  end

  def test_forwards_skip_stimulus_flag
    run_generator ["Card", "--engine=phlex", "--skip-stimulus"]

    assert_file "app/components/card_component.rb" do |contents|
      refute_match(/stimulus do/, contents)
    end
  end
end
