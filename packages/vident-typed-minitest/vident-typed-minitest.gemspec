require_relative "lib/vident/typed/minitest/version"

Gem::Specification.new do |spec|
  spec.name = "vident-typed-minitest"
  spec.version = Vident::Typed::Minitest::VERSION
  spec.authors = ["Stephen Ierodiaconou"]
  spec.email = ["stevegeek@gmail.com"]
  spec.homepage = "https://github.com/stevegeek/vident-typed-minitest"
  spec.summary = "Vident test helper for Minitest"
  spec.description = "Vident test helper for Minitest"
  spec.license = "MIT"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = spec.homepage + "/blob/main/CHANGELOG.md"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.add_dependency "railties", ">= 7", "< 8"
  spec.add_dependency "activesupport", ">= 7", "< 8"
  spec.add_dependency "vident-typed", ">= 0.1.0", "< 1.0"
  spec.add_dependency "minitest", ">= 5.14.4", "< 6.0"
  spec.add_dependency "minitest-hooks", ">= 1.5.0", "< 2.0"
  spec.add_dependency "faker", ">= 2.22.0", "< 4.0"
end
