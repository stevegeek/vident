
# Change Log
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).


## [Unreleased]

### Added

### Changed

### Fixed

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
