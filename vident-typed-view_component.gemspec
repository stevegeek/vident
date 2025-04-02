require_relative "lib/vident/typed/view_component/version"

Gem::Specification.new do |spec|
  spec.name = "vident-typed-view_component"
  spec.version = Vident::Typed::ViewComponent::VERSION
  spec.authors = ["Stephen Ierodiaconou"]
  spec.email = ["stevegeek@gmail.com"]
  spec.homepage = "https://github.com/stevegeek/vident-typed-view_component"
  spec.summary = "Vident with ViewComponent & typed attributes"
  spec.description = "Vident with ViewComponent & typed attributes"
  spec.license = "MIT"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = spec.homepage + "/blob/main/CHANGELOG.md"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.add_dependency "railties", ">= 7", "< 8"
  spec.add_dependency "activesupport", ">= 7", "< 8"
  spec.add_dependency "vident-typed", ">= 0.1.0", "< 1"
  spec.add_dependency "vident-view_component", ">= 0.3.0", "< 1"
end
