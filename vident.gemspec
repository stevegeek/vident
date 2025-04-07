# frozen_string_literal: true

require_relative "lib/vident/version"

# Collect files from other gemspecs to exclude them from the main gem
plugin_files = []

Dir["vident-*.gemspec"].each do |gemspec_file|
  spec = Gem::Specification.load(gemspec_file)
  plugin_files << spec.files if spec
end

# Flatten and make unique
ignored_files = plugin_files.flatten.uniq

Gem::Specification.new do |spec|
  spec.name = "vident"
  spec.version = Vident::VERSION
  spec.authors = ["Stephen Ierodiaconou"]
  spec.email = ["stevegeek@gmail.com"]

  spec.summary = "Vident is the base of your design system implementation, which provides helpers for working with Stimulus. For component libraries with ViewComponent or Phlex."
  spec.description = "Vident makes using Stimulus with your `ViewComponent` or `Phlex` view components as easy as writing Ruby. Vident is the base of your design system implementation, which provides helpers for working with Stimulus. For component libraries with ViewComponent or Phlex."
  spec.homepage = "https://github.com/stevegeek/vident"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = spec.homepage + "/blob/main/CHANGELOG.md"

  spec.files = Dir.chdir(__dir__) do
    files = `git ls-files -z`.split("\x0")

    # Only include files relevant to this gem
    all_files = files.select do |f|
      f.start_with?('lib/')
    end

    # Exclude files from other gemspecs
    all_files - ignored_files + [
      'README.md', 'LICENSE.txt', 'CHANGELOG.md'
    ]
  end

  spec.add_dependency "railties", ">= 7.2", "< 9"
  spec.add_dependency "activesupport", ">= 7.2", "< 9"
end
