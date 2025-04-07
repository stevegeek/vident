require_relative "lib/vident/version"
require_relative "lib/vident/view_component/caching/version"

Gem::Specification.new do |spec|
  spec.name = "vident-view_component-caching"
  spec.version = Vident::VERSION
  spec.authors = ["Stephen Ierodiaconou"]
  spec.email = ["stevegeek@gmail.com"]
  spec.homepage = "https://github.com/stevegeek/vident"
  spec.summary = "Cache key computation for Vident components with ViewComponent"
  spec.description = "Cache key computation for Vident components with ViewComponent"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = spec.homepage + "/blob/main/CHANGELOG.md"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    files = `git ls-files -z`.split("\x0")

    # Only include files relevant to this gem
    files.select do |f|
      f.match?(%r{^(lib/vident/view_component/caching)}) ||
        f == "lib/vident/version.rb" ||
        f == "lib/vident/view_component/version.rb" ||
        f == "vident-view_component-caching.gemspec" ||
        f == "README.md" ||
        f == "LICENSE.txt" ||
        f == "CHANGELOG.md"
    end
  end

  spec.add_dependency "rails", ">= 7.2", "< 9"
  spec.add_dependency "vident-view_component", "~> #{Vident::VERSION}"
end
