
# Change Log
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).


## [0.13.0] - 2024-04-07

### Breaking

- `data_maps` has been renamed to `values` and support has been added for the Stimulus 2+ Values API.
- `root`/`parent_element` no longer takes options, to define attributes for it, you can use `root_element_attributes` or the view component helper `root_component_attributes`. This change means
  that root elements can be instantiated outside of `render` which is useful if you refer to the instance in the components body block 

### Added

- New monorepo structure for the Vident project, retaining the separate gems however.
- All gems now have the same version and are released together.

### Changed

### Fixed

## [0.12.1] - 2024-06-12

### Fixed

- parsing of targets where the controller is also specified

## [0.12.0] - 2024-02-25

### Added

- `outlet` DSL methods updated so that the selector is scoped to the component's root element by default. This 
  is probably the most common use case, and it's now the default.
- `with_outlets` DSL method added to generate the data-* attributes for the outlets and return as a fragment  
  of HTML


## [0.11.0] - 2024-02-21

### Added

- `outlet_host` DSL method to support components hooking themselves into a host component's outlets



## [0.10.1] - 2024-02-21

### Added

- `outlets` option now accepts either a string stimulus controller identifier, a component instance, or a tuple of 
  identifier and CSS selector for the outlet.


## [0.10.0] - 2024-02-21

### Added

- `outlets` option for components, used to specify Stimulus outlets 

## [0.9.0] - 2023-08-11

### Added

- `#cache_key` support is now part of the core gem, and can be added to components using `Vident::Caching` module

## [0.8.0] - 2023-03-31

### Added

- new gems for Vident related functionality, eg `vident-typed` and `vident-tailwind`
- `vident` is now the core gem which can be used with any component system. Gems for Phlex and ViewComponent are available, `vident-phlex` and `vident-view_component`, and `vident-typed-phlex` and `vident-typed-view_component` are available with typed attributes support.

### Changed

- removed functionality for `better_html`, `dry-types`, `view_component`, and `phlex` from the core gem
- gem is now a Rails Engine and supports eager and autoloading

### Fixed

- Fix untyped attributes inheritance

## [0.7.0] - 2023-03-08  

### Added

- new `Vident::Tailwind` module which uses [tailwind_merge](https://github.com/gjtorikian/tailwind_merge) to merge TailwindCSS classes

### Changed

- Removed a dependency on intenal constants from `phlex`

## [0.6.3] - 2023-03-03

### Fixed

- Fix for changes to HTML tag collection in Phlex


## [0.6.2] - 2023-02-23

### Fixed

- Element tag options are not set when no ID is provided


## [0.6.1] - 2023-02-20

### Fixed

- `better_html` support fix for aliased dsl methods


## [0.6.0] - 2023-02-20

### Added

- Experimental support for `better_html` in the root components (the stimulus attributes are generated with `html_attributes`)



## [0.5.1] - 2023-02-17

### Added

- N/A

### Changed

- N/A

### Fixed

- Typed attributes was not always using custom coercion methods if they were defined 

### Removed

- N/A

### Deprecated

- N/A

### Security

- N/A

---

# Package Changelogs

## vident-better_html

### [0.6.0] - 2023-02-20

#### Added

- Experimental support for `better_html` in the root components (the stimulus attributes are generated with `html_attributes`)

### [0.6.1] - 2023-02-20

#### Fixed

- `better_html` support fix for aliased dsl methods

## vident-tailwind

### [0.1.1] - 2023-04-02

#### Fixed

- `tailwind_merge` should only take a non-nil value, and since it uses the class string as a cache key, it should not be blank.

## vident-typed-view_component

### [0.3.0] - 2023-08-12

- Update to depend on `vident-view_component` v0.3.0
- Adds support for new `Vident::Caching` module
- Update examples to support view_component v3

### [0.1.0] - 2023-04-01

- Initial release, extracted from `vident`

## vident-view_component

### [0.3.0] - 2023-08-12

- Update to depend on `vident` v0.9.0
- Adds support for new `Vident::Caching` module
- Update examples to support view_component v3

### [0.1.0] - 2023-04-01

- Initial release, extracted from `vident`

## vident-phlex

### [0.3.0] - 2023-08-12

- Update to depend on `vident` v0.9.0
- Adds support for new `Vident::Caching` module

### [0.1.0] - 2023-04-01

- Initial release, extracted from `vident`

## vident-typed-phlex

### [0.3.0] - 2023-08-12

- Update to depend on `vident-typed` v0.3.0
- Adds support for new `Vident::Caching` module

### [0.1.0] - 2023-04-01

- Initial release, extracted from `vident`
