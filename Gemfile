source "https://rubygems.org"

# Main gemspec
gemspec name: "vident"

# External dependencies with specific versions for development
gem "view_component", "4.0.0.rc2" # ">= 4.0.0", "< 5"
gem "phlex", ">= 2.0", "< 3"
gem "phlex-rails", ">= 0.8.1", "< 3"
gem "better_html", ">= 2.0.0", "< 3"
gem "tailwind_merge", ">= 0.5.2", "< 2"
gem "dry-struct", ">= 1.5.0", "< 2"

require "pathname"

gemspec name: "vident-phlex"
gemspec name: "vident-view_component"

# Development and testing gems
gem "appraisal"
gem "standard"
gem "simplecov", require: false

gem "rake", "~> 13.0"
gem "minitest", "~> 5.0"
gem "faker"
gem "puma"
gem "rails", "~> #{ENV["RAILS_VERSION"] || "8"}"
gem "foreman"
gem "sqlite3"
gem "capybara"

# Asset things for the dummy app
gem "sprockets-rails"
gem "turbo-rails"
gem "importmap-rails"
gem "stimulus-rails"
gem "tailwindcss-rails", "~> 3.3.1"
