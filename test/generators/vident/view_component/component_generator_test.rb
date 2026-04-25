# frozen_string_literal: true

require "test_helper"
require "rails/generators/test_case"
require "generators/vident/view_component/component/component_generator"

class Vident::ViewComponent::Generators::ComponentGeneratorTest < Rails::Generators::TestCase
  tests Vident::ViewComponent::Generators::ComponentGenerator
  destination File.expand_path("../../../tmp/generators", __dir__)
  setup :prepare_destination

  def test_generates_component_template_controller_and_test
    run_generator ["Dashboard::TaskCard"]

    assert_file "app/components/dashboard/task_card_component.rb" do |contents|
      assert_match(/class (?:Dashboard::TaskCardComponent|TaskCardComponent) < ApplicationViewComponent/, contents)
      assert_match(/prop :title, String, reader: :public/, contents)
      assert_match(/stimulus do/, contents)
      assert_match(/root_element_attributes/, contents)
    end

    assert_file "app/components/dashboard/task_card_component.html.erb" do |contents|
      assert_match(/<%= root_element do %>/, contents)
      assert_match(/<%= title %>/, contents)
    end

    assert_file "app/components/dashboard/task_card_component_controller.js" do |contents|
      assert_match(/import \{ Controller \} from "@hotwired\/stimulus"/, contents)
      assert_match(/title: String,/, contents)
    end

    assert_file "test/components/dashboard/task_card_component_test.rb" do |contents|
      assert_match(/class Dashboard::TaskCardComponentTest < ViewComponent::TestCase/, contents)
      assert_match(/render_inline\(Dashboard::TaskCardComponent\.new\(title: "Hello"\)\)/, contents)
    end
  end

  def test_skip_stimulus_omits_dsl_and_controller
    run_generator ["Card", "--skip-stimulus"]

    assert_file "app/components/card_component.rb" do |contents|
      refute_match(/stimulus do/, contents)
    end
    assert_no_file "app/components/card_component_controller.js"
  end

  def test_typescript_emits_ts_controller
    run_generator ["Card", "--typescript"]

    assert_no_file "app/components/card_component_controller.js"
    assert_file "app/components/card_component_controller.ts" do |contents|
      assert_match(/declare readonly titleValue: string/, contents)
    end
  end
end
