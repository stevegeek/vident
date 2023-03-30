require_relative "lib/vident/typed/version"

Gem::Specification.new do |spec|
  spec.name = "vident-typed"
  spec.version = Vident::Typed::VERSION
  spec.authors = ["Stephen Ierodiaconou"]
  spec.email = ["stevegeek@gmail.com"]
  spec.homepage = "https://github.com/stevegeek/vident-typed"
  spec.summary = "Vident with typed attributes"
  spec.description = "Vident with typed attributes"
  spec.license = "MIT"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = spec.homepage + "/blob/main/CHANGELOG.md"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.add_dependency "rails", ">= 7.0.4.3", "< 8"
  spec.add_dependency "vident", ">= 0.8.0", "< 1"
  spec.add_dependency "dry-struct", ">= 1.5.0", "< 2"
end
