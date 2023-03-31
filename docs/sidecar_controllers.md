# Making 'sidecar' Stimulus Controllers work

## When using `stimulus-rails`, `sprockets-rails` & `importmap-rails`

Pin any JS modules from under `app/views` and `app/components` which are sidecar with their respective components.

Add to `config/importmap.rb`:

```ruby
components_directories = [Rails.root.join("app/components"), Rails.root.join("app/views")]
components_directories.each do |components_path|
  prefix = components_path.basename.to_s
  components_path.glob("**/*_controller.js").each do |controller|
    name = controller.relative_path_from(components_path).to_s.remove(/\.js$/)
    pin "#{prefix}/#{name}", to: name
  end
end
```

Note we don't use `pin_all_from` as it is meant to work with a subdirectory in `assets.paths`
See this for more: https://stackoverflow.com/a/73228193/268602

Then we need to ensure that sprockets picks up those files in build, so add
to the `app/assets/config/manifest.js`:

```js
//= link_tree ../../components .js
//= link_tree ../../views .js
```

We also need to add to `assets.paths`. Add to your to `config/application.rb`

```ruby
config.importmap.cache_sweepers.append(Rails.root.join("app/components"), Rails.root.join("app/views"))
config.assets.paths.append("app/components", "app/views")
```

## When using `webpacker`

TODO

## When using `propshaft`

TODO

# Using TypeScript for Stimulus Controllers

TODO
