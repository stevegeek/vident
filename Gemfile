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

require "pathname"

# All vident plugin gemspecs
# Create absolute path based on fact that gemspecs is next to this file
gemspecs = Pathname(__FILE__).dirname.join("vident-*.gemspec").expand_path
Dir[gemspecs].each do |gemspec|
  plugin = gemspec.scan(/vident-(.*)\.gemspec/).flatten.first
  gemspec(name: "vident-#{plugin}")
end

# Development and testing gems
gem "appraisal"
gem "standard"

gem "rake", "~> 13.0"
gem "minitest", "~> 5.0"
gem "faker"
gem "puma"
gem "rails", "~> #{ENV["RAILS_VERSION"] || "8"}"
gem "foreman"
gem "sqlite3"

# Asset things for the dummy app
gem "sprockets-rails"
gem "turbo-rails"
gem "importmap-rails"
gem "stimulus-rails"
gem "tailwindcss-rails", "~> 3.3.1"