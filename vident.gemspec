# frozen_string_literal: true

require_relative "lib/vident/version"

Gem::Specification.new do |spec|
  spec.name = "vident"
  spec.version = Vident::VERSION
  spec.authors = ["Stephen Ierodiaconou"]
  spec.email = ["stevegeek@gmail.com"]

  spec.summary = "Vident is the base of your design system implementation, which provides helpers for working with Stimulus. For component libraries with ViewComponent or Phlex."
  spec.description = "Vident makes using Stimulus with your `ViewComponent` or `Phlex` view components as easy as writing Ruby. Vident is the base of your design system implementation, which provides helpers for working with Stimulus. For component libraries with ViewComponent or Phlex."
  spec.homepage = "https://github.com/stevegeek/vident"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = spec.homepage + "/blob/main/CHANGELOG.md"

  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ examples/ docs/ .git .github appveyor Gemfile])
    end
  end

  spec.add_dependency "railties", ">= 7", "< 8.0"
  spec.add_dependency "activesupport", ">= 7", "< 8.0"
end
