require_relative "lib/vident/version"
require_relative "lib/vident/typed/version"

Gem::Specification.new do |spec|
  spec.name = "vident-typed"
  spec.version = Vident::VERSION
  spec.authors = ["Stephen Ierodiaconou"]
  spec.email = ["stevegeek@gmail.com"]
  spec.homepage = "https://github.com/stevegeek/vident"
  spec.summary = "Vident with typed attributes"
  spec.description = "Vident with typed attributes"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = spec.homepage + "/blob/main/CHANGELOG.md"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    files = `git ls-files -z`.split("\x0")

    # Only include files relevant to this gem
    files.select do |f|
      f.match?(%r{^(lib/vident[-_]typed\.rb|lib/vident/typed(?!/minitest|/phlex|/view_component))}) ||
        f == "lib/vident/version.rb" ||
        f == "vident-typed.gemspec" ||
        f == "README.md" ||
        f == "LICENSE.txt" ||
        f == "CHANGELOG.md"
    end
  end

  spec.add_dependency "railties", ">= 7.2", "< 9"
  spec.add_dependency "activesupport", ">= 7.2", "< 9"
  spec.add_dependency "vident", "~> #{Vident::VERSION}"
  spec.add_dependency "dry-struct", ">= 1.5.0", "< 2"
end
