# frozen_string_literal: true

require "test_helper"
require "rails/generators/test_case"
require "generators/vident/phlex/component/component_generator"

class Vident::Phlex::Generators::ComponentGeneratorTest < Rails::Generators::TestCase
  tests Vident::Phlex::Generators::ComponentGenerator
  destination File.expand_path("../../../tmp/generators", __dir__)
  setup :prepare_destination

  def test_generates_component_controller_and_test
    run_generator ["Dashboard::TaskCard"]

    assert_file "app/components/dashboard/task_card_component.rb" do |contents|
      assert_match(/class (?:Dashboard::TaskCardComponent|TaskCardComponent) < ApplicationPhlexComponent/, contents)
      assert_match(/prop :title, String/, contents)
      assert_match(/stimulus do/, contents)
      assert_match(/values_from_props :title/, contents)
      assert_match(/action\(:select\)\.on\(:click\)/, contents)
      assert_match(/root_element/, contents)
    end

    assert_file "app/components/dashboard/task_card_component_controller.js" do |contents|
      assert_match(/import \{ Controller \} from "@hotwired\/stimulus"/, contents)
      assert_match(/static values = \{/, contents)
      assert_match(/title: String,/, contents)
    end

    assert_file "test/components/dashboard/task_card_component_test.rb" do |contents|
      assert_match(/class Dashboard::TaskCardComponentTest/, contents)
      assert_match(/Dashboard::TaskCardComponent\.new\(title: "Hello"\)\.call/, contents)
    end
  end

  def test_skip_stimulus_omits_dsl_and_controller
    run_generator ["Card", "--skip-stimulus"]

    assert_file "app/components/card_component.rb" do |contents|
      refute_match(/stimulus do/, contents)
    end
    assert_no_file "app/components/card_component_controller.js"
  end

  def test_skip_controller_keeps_stimulus_dsl
    run_generator ["Card", "--skip-controller"]

    assert_file "app/components/card_component.rb" do |contents|
      assert_match(/stimulus do/, contents)
    end
    assert_no_file "app/components/card_component_controller.js"
  end

  def test_skip_test_omits_test_file
    run_generator ["Card", "--skip-test"]
    assert_no_file "test/components/card_component_test.rb"
  end

  def test_typescript_emits_ts_controller
    run_generator ["Card", "--typescript"]

    assert_no_file "app/components/card_component_controller.js"
    assert_file "app/components/card_component_controller.ts" do |contents|
      assert_match(/declare readonly titleValue: string/, contents)
      assert_match(/select\(event: Event\): void/, contents)
    end
  end

  def test_parent_class_override
    run_generator ["Card", "--parent=AdminComponent"]

    assert_file "app/components/card_component.rb" do |contents|
      assert_match(/class CardComponent < AdminComponent/, contents)
    end
  end
end
