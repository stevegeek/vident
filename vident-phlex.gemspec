require_relative "lib/vident/phlex/version"

Gem::Specification.new do |spec|
  spec.name = "vident-phlex"
  spec.version = Vident::Phlex::VERSION
  spec.authors = ["Stephen Ierodiaconou"]
  spec.email = ["stevegeek@gmail.com"]
  spec.homepage = "https://github.com/stevegeek/vident-phlex"
  spec.summary = "Vident with Phlex"
  spec.description = "Vident with Phlex"
  spec.license = "MIT"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = spec.homepage + "/blob/main/CHANGELOG.md"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.add_dependency "rails", ">= 7.0.4.3", "< 8"
  spec.add_dependency "vident", ">= 0.8.0", "< 1"
  spec.add_dependency "phlex", ">= 1.5.0", "< 2"
  spec.add_dependency "phlex-rails", ">= 0.8.1", "< 1"
end
