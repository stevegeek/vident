# Vident::BetterHtml
Short description and motivation.

## Usage
How to use my plugin.

```ruby
BetterHtml.config = BetterHtml::Config.new(YAML.load(File.read(".better-html.yml")))

BetterHtml.configure do |config|
  config.template_exclusion_filter = proc { |filename| !filename.start_with?(Rails.root.to_s) }
end
# ViewComponent needs to do this hack to work in certain cases
# see https://github.com/Shopify/better-html/pull/98
class BetterHtml::HtmlAttributes
  alias_method :to_s_without_html_safe, :to_s

  def to_s
    to_s_without_html_safe.html_safe
  end
end
```

## Installation
Add this line to your application's Gemfile:

```ruby
gem "vident-better_html"
```

And then execute:
```bash
$ bundle
```

Or install it yourself as:
```bash
$ gem install vident-better_html
```

## Contributing
Contribution directions go here.

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
