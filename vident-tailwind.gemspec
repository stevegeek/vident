require_relative "lib/vident/tailwind/version"

Gem::Specification.new do |spec|
  spec.name = "vident-tailwind"
  spec.version = Vident::Tailwind::VERSION
  spec.authors = ["Stephen Ierodiaconou"]
  spec.email = ["stevegeek@gmail.com"]
  spec.homepage = "https://github.com/stevegeek/vident-tailwind"
  spec.summary = "Vident with Tailwind class deduplication to allow easy overriding"
  spec.description = "Vident with Tailwind class deduplication to allow easy overriding"
  spec.license = "MIT"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  # spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.add_dependency "rails", ">= 7.0.4.3", "< 8"
  spec.add_dependency "vident", ">= 0.8.0", "< 1"
  spec.add_dependency "tailwind_merge", ">= 0.5.2", "< 1"
end
