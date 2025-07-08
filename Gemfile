source "https://rubygems.org"

gem "rails", "~> #{ENV["RAILS_VERSION"] || "8"}"

# External dependencies with specific versions for development
gem "view_component", "4.0.0.rc2" # ">= 4.0.0", "< 5"
gem "phlex-rails", ">= 0.8.1", "< 3"
gem "tailwind_merge", ">= 0.5.2", "< 2"

gemspec name: "vident", path: "./"
gemspec name: "vident-phlex", path: "./"
gemspec name: "vident-view_component", path: "./"

group :development, :test do
  # Development and testing gems
  gem "appraisal"
  gem "standard"
  gem "simplecov", require: false

  gem "rake", "~> 13.0"
  gem "minitest", "~> 5.0"
  gem "faker"
  gem "puma"
  gem "foreman"
  gem "sqlite3"
  gem "capybara"

  # Asset things for the dummy app
  gem "sprockets-rails"
  gem "turbo-rails"
  gem "importmap-rails"
  gem "stimulus-rails"
  gem "tailwindcss-rails", "~> 3.3.1"
end
