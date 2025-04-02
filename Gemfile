source "https://rubygems.org"

# Main gemspec
gemspec name: "vident"

# External dependencies with specific versions for development
gem "view_component", ">= 2.74.1", "< 4"
gem "phlex", ">= 1.5.0", "< 2"
gem "phlex-rails", ">= 0.8.1", "< 2"
gem "better_html", ">= 2.0.0", "< 3"
gem "tailwind_merge", ">= 0.5.2", "< 1"
gem "dry-struct", ">= 1.5.0", "< 2"

# All vident plugin gemspecs
Dir["vident-*.gemspec"].each do |gemspec|
  plugin = gemspec.scan(/vident-(.*)\.gemspec/).flatten.first
  gemspec(name: "vident-#{plugin}", development_group: plugin)
end


# Development and testing gems
gem "rake", "~> 13.0"
gem "minitest", "~> 5.0"
gem "rails", "~> #{ENV['RAILS_VERSION'] || '7.0'}"
gem "appraisal", "~> 2.5"
gem "sqlite3"
gem "puma"