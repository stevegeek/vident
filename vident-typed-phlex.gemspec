require_relative "lib/vident/version"
require_relative "lib/vident/typed/version"
require_relative "lib/vident/phlex/version"
require_relative "lib/vident/typed/phlex/version"

Gem::Specification.new do |spec|
  spec.name = "vident-typed-phlex"
  spec.version = Vident::VERSION
  spec.authors = ["Stephen Ierodiaconou"]
  spec.email = ["stevegeek@gmail.com"]
  spec.homepage = "https://github.com/stevegeek/vident"
  spec.summary = "Vident with Phlex & typed attributes"
  spec.description = "Vident with Phlex & typed attributes"
  spec.license = "MIT"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = spec.homepage + "/blob/main/CHANGELOG.md"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    files = `git ls-files -z`.split("\x0")

    # Only include files relevant to this gem
    files.select do |f|
      f.match?(%r{^(lib/vident[-_]typed[-_]phlex|lib/vident/typed/phlex)}) ||
        f == "lib/vident/version.rb" ||
        f == "lib/vident/typed/version.rb" ||
        f == "vident-typed-phlex.gemspec" ||
        f == "README.md" ||
        f == "LICENSE.txt" ||
        f == "CHANGELOG.md"
    end
  end

  spec.add_dependency "railties", ">= 7", "< 8"
  spec.add_dependency "vident-phlex", "~> #{Vident::VERSION}"
  spec.add_dependency "vident-typed", "~> #{Vident::VERSION}"
end
