require_relative "lib/vident/tailwind/version"

Gem::Specification.new do |spec|
  spec.name = "vident-tailwind"
  spec.version = Vident::Tailwind::VERSION
  spec.authors = ["Stephen Ierodiaconou"]
  spec.email = ["stevegeek@gmail.com"]
  spec.homepage = "https://github.com/stevegeek/vident"
  spec.summary = "Vident with Tailwind class deduplication to allow easy overriding"
  spec.description = "Vident with Tailwind class deduplication to allow easy overriding"
  spec.license = "MIT"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = spec.homepage + "/blob/main/CHANGELOG.md"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    files = `git ls-files -z`.split("\x0")
    
    # Only include files relevant to this gem
    files.select do |f|
      f.match?(%r{^(lib/vident[-_]tailwind|lib/vident/tailwind)}) ||
      f == "vident-tailwind.gemspec" ||
      f == "README.md" ||
      f == "LICENSE.txt" ||
      f == "CHANGELOG.md"
    end
  end

  spec.add_dependency "railties", ">= 7", "< 8"
  spec.add_dependency "activesupport", ">= 7", "< 8"
  spec.add_dependency "vident", ">= 0.8.0", "< 1"
  spec.add_dependency "tailwind_merge", ">= 0.5.2", "< 1"
end
