require_relative "lib/vident/view_component/version"

Gem::Specification.new do |spec|
  spec.name = "vident-view_component"
  spec.version = Vident::ViewComponent::VERSION
  spec.authors = ["Stephen Ierodiaconou"]
  spec.email = ["stevegeek@gmail.com"]
  spec.homepage = "https://github.com/stevegeek/vident-view_component"
  spec.summary = "Vident with ViewComponent"
  spec.description = "Vident with ViewComponent"
  spec.license = "MIT"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = spec.homepage + "/blob/main/CHANGELOG.md"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.add_dependency "railties", ">= 7", "< 8.0"
  spec.add_dependency "activesupport", ">= 7", "< 8.0"
  spec.add_dependency "vident", ">= 0.9.0", "< 1"
  spec.add_dependency "view_component", ">= 2.74.1", "< 4"
end
