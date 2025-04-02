source "https://rubygems.org"

# Development dependencies
group :development, :test do
  gem "rake", "~> 13.0"
  gem "minitest", "~> 5.0"
  gem "rails", "~> 7.0"
end

# External dependencies required by the gems
gem "view_component", ">= 2.74.1", "< 4"
gem "phlex", ">= 1.5.0", "< 2"
gem "phlex-rails", ">= 0.8.1", "< 2"
gem "better_html", ">= 2.0.0", "< 3"
gem "tailwind_merge", ">= 0.5.2", "< 1"
gem "dry-struct", ">= 1.5.0", "< 2"

# All gems in the monorepo - use path to refer to local files
gem "vident", path: "."
gem "vident-better_html", path: "."
gem "vident-phlex", path: "."
gem "vident-tailwind", path: "."
gem "vident-typed", path: "."
gem "vident-typed-minitest", path: "."
gem "vident-typed-phlex", path: "."
gem "vident-typed-view_component", path: "."
gem "vident-view_component", path: "."
gem "vident-view_component-caching", path: "."