require_relative "lib/vident/typed/phlex/version"

Gem::Specification.new do |spec|
  spec.name = "vident-typed-phlex"
  spec.version = Vident::Typed::Phlex::VERSION
  spec.authors = ["Stephen Ierodiaconou"]
  spec.email = ["stevegeek@gmail.com"]
  spec.homepage = "https://github.com/stevegeek/vident-typed-phlex"
  spec.summary = "Vident with Phlex & typed attributes"
  spec.description = "Vident with Phlex & typed attributes"
  spec.license = "MIT"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = spec.homepage + "/blob/main/CHANGELOG.md"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.add_dependency "rails", ">= 7", "< 8"
  spec.add_dependency "vident-phlex", ">= 0.3.0", "< 1"
  spec.add_dependency "vident-typed", ">= 0.1.0", "< 1"
end
