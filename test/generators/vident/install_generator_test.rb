# frozen_string_literal: true

require "test_helper"
require "rails/generators/test_case"
require "generators/vident/install/install_generator"

class Vident::Generators::InstallGeneratorTest < Rails::Generators::TestCase
  tests Vident::Generators::InstallGenerator
  destination File.expand_path("../../tmp/generators", __dir__)
  setup :prepare_destination

  def test_creates_initializer
    # Without an existing ApplicationController the generator should still
    # write the initializer (the controller patch is best-effort).
    run_generator
    assert_file "config/initializers/vident.rb" do |contents|
      assert_match(/Vident::StableId\.strategy = if Rails\.env\.test\?/, contents)
      assert_match(/Vident::StableId::RANDOM_FALLBACK/, contents)
      assert_match(/Vident::StableId::STRICT/, contents)
    end
  end

  def test_patches_application_controller_when_present
    controller_path = File.join(destination_root, "app/controllers/application_controller.rb")
    FileUtils.mkdir_p(File.dirname(controller_path))
    File.write(controller_path, <<~RUBY)
      class ApplicationController < ActionController::Base
      end
    RUBY

    run_generator

    assert_file "app/controllers/application_controller.rb" do |contents|
      assert_match(/before_action do/, contents)
      assert_match(/Vident::StableId\.set_current_sequence_generator\(seed: request\.fullpath\)/, contents)
      assert_match(/after_action do/, contents)
      assert_match(/Vident::StableId\.clear_current_sequence_generator/, contents)
    end
  end

  def test_copies_claude_skill
    run_generator
    assert_file ".claude/skills/vident/SKILL.md" do |contents|
      assert_match(/^---$/, contents)
      assert_match(/^name: Vident$/, contents)
      assert_match(/stimulus do/, contents)
    end
  end

  def test_skipping_skill_when_already_installed
    FileUtils.mkdir_p(File.join(destination_root, ".claude/skills/vident"))
    existing = File.join(destination_root, ".claude/skills/vident/SKILL.md")
    File.write(existing, "pre-existing skill content\n")

    run_generator

    assert_equal "pre-existing skill content\n", File.read(existing)
  end

  def test_force_overwrites_existing_skill
    FileUtils.mkdir_p(File.join(destination_root, ".claude/skills/vident"))
    existing = File.join(destination_root, ".claude/skills/vident/SKILL.md")
    File.write(existing, "stale content\n")

    run_generator ["--force"]

    refute_equal "stale content\n", File.read(existing)
    assert_match(/^name: Vident$/, File.read(existing))
  end

  def test_running_generator_twice_does_not_duplicate_controller_hook
    controller_path = File.join(destination_root, "app/controllers/application_controller.rb")
    FileUtils.mkdir_p(File.dirname(controller_path))
    File.write(controller_path, <<~RUBY)
      class ApplicationController < ActionController::Base
      end
    RUBY

    run_generator
    # Force-overwrite the initializer on the second pass; we only care about
    # the controller patch behavior here.
    run_generator([destination_root, "--force"])

    contents = File.read(controller_path)
    assert_equal 1, contents.scan("Vident::StableId.set_current_sequence_generator").length,
      "expected a single before_action hook after two generator runs"
  end
end
