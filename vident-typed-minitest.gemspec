require_relative "lib/vident/version"
require_relative "lib/vident/typed/version"
require_relative "lib/vident/typed/minitest/version"

Gem::Specification.new do |spec|
  spec.name = "vident-typed-minitest"
  spec.version = Vident::VERSION
  spec.authors = ["Stephen Ierodiaconou"]
  spec.email = ["stevegeek@gmail.com"]
  spec.homepage = "https://github.com/stevegeek/vident"
  spec.summary = "Vident test helper for Minitest"
  spec.description = "Vident test helper for Minitest"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = spec.homepage + "/blob/main/CHANGELOG.md"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    files = `git ls-files -z`.split("\x0")

    # Only include files relevant to this gem
    files.select do |f|
      f.match?(%r{^(lib/vident/typed/minitest)}) ||
        f == "README.md" ||
        f == "LICENSE.txt" ||
        f == "CHANGELOG.md"
    end
  end

  spec.add_dependency "railties", ">= 7.2", "< 9"
  spec.add_dependency "activesupport", ">= 7.2", "< 9"
  spec.add_dependency "vident-typed", "~> #{Vident::VERSION}"
  spec.add_dependency "minitest", ">= 5.14.4", "< 6.0"
  spec.add_dependency "minitest-hooks", ">= 1.5.0", "< 2.0"
  spec.add_dependency "faker", ">= 2.22.0", "< 4.0"
end
