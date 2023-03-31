require_relative "lib/vident/view_component/caching/version"

Gem::Specification.new do |spec|
  spec.name        = "vident-view_component-caching"
  spec.version     = Vident::ViewComponent::Caching::VERSION
  spec.authors     = ["Stephen Ierodiaconou"]
  spec.email       = ["stevegeek@gmail.com"]
  spec.homepage = "https://github.com/stevegeek/vident-view_component-caching"
  spec.summary = "Cache key computation for Vident components with ViewComponent"
  spec.description = "Cache key computation for Vident components with ViewComponent"
  spec.license = "MIT"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = spec.homepage + "/blob/main/CHANGELOG.md"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.add_dependency "rails", ">= 7.0.4.3"
  spec.add_dependency "vident-view_component", ">= 0.1.0", "< 1"
end
