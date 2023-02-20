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

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Dependencies
  spec.add_dependency "activesupport", ">= 6.0", "< 8"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
