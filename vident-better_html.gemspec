require_relative "lib/vident/better_html/version"

Gem::Specification.new do |spec|
  spec.name = "vident-better_html"
  spec.version = Vident::BetterHtml::VERSION
  spec.authors = ["Stephen Ierodiaconou"]
  spec.email = ["stevegeek@gmail.com"]
  spec.summary = "Vident support for BetterHTML."
  spec.description = "Vident support for better_html. If you use better_html, you will need to install this gem too."
  spec.homepage = "https://github.com/stevegeek/vident-better_html"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = spec.homepage + "/blob/main/CHANGELOG.md"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.add_dependency "rails", ">= 7.0.4.3", "< 8"
  spec.add_dependency "vident", ">= 0.8.0", "< 1"
  spec.add_dependency "better_html", ">= 2.0.0", "< 3"
end
