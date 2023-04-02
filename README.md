# Vident

**Vident** is a collection of gems that help you create **flexible** & **maintainable** component libraries for your Rails application.

<a href="https://github.com/stevegeek/vident"><img alt="Vident logo" src="https://raw.githubusercontent.com/stevegeek/vident/main/logo-by-sd-256-colors.png" width="180" /></a>

Vident also provides a neat Ruby DSL to make wiring up **Stimulus easier & less error prone** in your view components.

[`ViewComponent`](https://viewcomponent.org/) and [`Phlex`](https://phlex.fun) supported.

# Motivation

I love working with Stimulus, but I find manually crafting the data attributes for
targets and actions error-prone and tedious. Vident aims to make this process easier
and keep me thinking in Ruby.

I have been using Vident with `ViewComponent` in production apps for a while now (and recently `Phlex`!) 
and it has been constantly evolving.

This gem is a work in progress and I would love to get your feedback and contributions!

# Vident is a collection of gems

The core gems are:

- [`vident`](https://github.com/stevegeek/vident) to get the base functionality
- [`vident-typed`](https://github.com/stevegeek/vident-typed) to optionally define typed attributes for your view components

Gems that provide support for `ViewComponent` and `Phlex`:

- [`vident-view_component`](https://github.com/stevegeek/vident-view_component) for using with `ViewComponent` and untyped attributes
- [`vident-typed-view_component`](https://github.com/stevegeek/vident-typed-view_component) for using with `ViewComponent` and typed attributes
- [`vident-phlex`](https://github.com/stevegeek/vident-phlex) for using with `Phlex` and untyped attributes
- [`vident-typed-phlex`](https://github.com/stevegeek/vident-typed-phlex) for using with `Phlex` and typed attributes

There is also:

- [`vident-typed-minitest`](https://github.com/stevegeek/vident-typed-minitest) to get some test helpers for typed attributes (auto generates inputs to test attributes)
- [`vident-better_html`](https://github.com/stevegeek/vident-better_html) to support `better_html` if you use it in your Rails app
- [`vident-tailwind`](https://github.com/stevegeek/vident-tailwind) to get all the benefits of the amazing [`tailwind_merge`](https://github.com/gjtorikian/tailwind_merge/).
- [`vident-view_component-caching`](https://github.com/stevegeek/vident-view_component-caching) to get `.cache_key` support for your components


# Things still to do...

This is a work in progress. Here's what's left to do for first release:

- Iterate on the interfaces and functionality
- Add tests
- Make the gem more configurable to fit more use cases
- Create an example library of a few components for some design system
  - Create a demo app with `lookbook` and those components
- Add more documentation

# About Vident

## What does Vident provide?

- Base classes for your `ViewComponent` components or `Phlex` components that provides a helper to create the
  all important 'root' element component (can be used with templated or template-less components).

- implementations of these root components for creating the 'root' element in your view components. Similar to `Primer::BaseComponent` but
  exposes a simple API for configuring and adding Stimulus controllers, targets and actions. The root component also handles deduplication
 of classes, creating a unique ID, setting the element tag type, handling possible overrides set at the render site, and determining stimulus controller identifiers etc

- a way to define attributes for your components, either typed or untyped, with default values and optional validation.

### Various utilities

Such as...

- for Taiwind users, a mixin for your vident component which uses [tailwind_merge](https://github.com/gjtorikian/tailwind_merge) to merge TailwindCSS classes
  so you can easily override classes when rendering a component.
- a mixin for your Vident ViewComponents which provides a `#cache_key` method that can be used to generate a cache key for
  fragment caching or etag generation.
- a test helper for your typed Vident ViewComponents which can be used to generate good and bad attribute/params/inputs 

## All the Features...

- use Vident with `ViewComponent` or `Phlex` or your own view component system
- A helper to create the root HTML element for your component, which then handles creation of attributes.
- Component arguments are defined using the `attribute` method which allows you to define default values, (optionally) types and
  if blank or nil values should be allowed.
- You can use the same component in multiple contexts and configure the root element differently in each context by passing
  options to the component when instantiating it.
- Stimulus support is built in and sets a default controller name based on the component name.
- Stimulus actions, targets and classes can be setup using a simple DSL to avoid hand crafting the data attributes.
- Since data attribute names are generated from the component class name, you can rename easily refactor and move components without
  having to update the data attributes in your views.
- Components are rendered with useful class names and IDs to make debugging easier (autogenerated IDs are 'random' but deterministic so they
  are the same each time a given view is rendered to avoid content changing/Etag changing).
- (experimental) Support for fragment caching of components (only with ViewComponent and with caveats)
- (experimental) A test helper to make testing components easier by utilising type information from the component arguments to render
  automatically configured good and bad examples of the component.
- (experimental) support for `better_html`


## Installation

This gem (`vident`) provides only base functionality but there are a number of gems that provide additional functionality
or an "out of the box" experience.

It's a "pick your own adventure" approach. You decide what frameworks and features you want to use
and add the gems as needed.

First, add this line to your application's Gemfile:

```ruby 
gem 'vident'
```

Then go on to choose the gems you want to use:

#### Q1. Do you want to use [`ViewComponent`](https://viewcomponent.org/) or [`Phlex`](https://www.phlex.fun/) for your view components?

For ViewComponent use:

- [`vident-view_component`](https://github.com/stevegeek/vident-view_component)

For Phlex use:

- [`vident-phlex`](https://github.com/stevegeek/vident-phlex)


Note: you can also use both in the same app.

For example, if you want to use ViewComponent and Phlex in the same app, you might end up with:

```ruby
gem 'vident'
gem 'vident-view_component'
gem 'vident-phlex'
```

#### Q2. Do you want to build components where the attributes have runtime type checking (powered by [`dry-types`](https://github.com/dry-rb/dry-types))?

If yes, then add `vident-typed` to your Gemfile:

```ruby
gem 'vident-typed'
```

and then use the relavent `*-typed-*` gems for your chosen view component system:

- use [`vident-typed-view_component`](https://github.com/stevegeek/vident-typed-view_component)
- and/or [`vident-typed-phlex`](https://github.com/stevegeek/vident-typed-phlex)

Note you must also include the gem for the view component system you are using.

For example, for ViewComponent, you might end up with:

```ruby
gem 'vident'
gem 'vident-view_component'
gem 'vident-typed'
gem 'vident-typed-view_component'
```

#### Q3. Do you use or want to use [BetterHTML](https://github.com/Shopify/better-html) in your Rails project?

If yes, then include [`vident-better_html`](https://github.com/stevegeek/vident-better_html) in your Gemfile alongside `better_html` and your vident gems of choice.

```ruby
...
gem 'better_html'
gem 'vident-better_html'
```

Note that `vident-better_html` automatically enables `better_html` support in Vident root components.

### Q4. Do you use or want to use [TailwindCSS](https://tailwindcss.com/)?

If yes, then consider adding [`vident-tailwind`](https://github.com/stevegeek/vident-tailwind) to your Gemfile alongside your vident gems of choice. 

```ruby
...
gem 'vident-tailwind'
```

When creating your components you can then include `Vident::Tailwind` to get all the benefits of the amazing [`tailwind_merge`](https://github.com/gjtorikian/tailwind_merge/).

### Q5. Did none of the above gems suit your needs?

You can always just use base `vident` gems and then roll your own solutions:

- [`vident`](https://github.com/stevegeek/vident) to get the base functionality to mix with your own view component system
- [`vident-typed`](https://github.com/stevegeek/vident-typed) to define typed attributes for your own view component system


## Documentation

See the [docs](docs/) directory and visit the individual gem pages for more information.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/stevegeek/vident. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/vident/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Vident project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/vident/blob/master/CODE_OF_CONDUCT.md).
