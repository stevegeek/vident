# Pin npm packages by running ./bin/importmap
#
pin "application", preload: true
pin "@hotwired/turbo-rails", to: "turbo.min.js", preload: true
pin "@hotwired/stimulus", to: "stimulus.min.js", preload: true
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js", preload: true
pin_all_from "app/javascript/controllers", under: "controllers"

# Pin all Stimulus JS controllers from app/components and app/views
# See https://stackoverflow.com/a/73228193/268602
root = Rails.root
components_directories = [root.join("app/components")]
components_directories.each do |components_path|
  prefix = components_path.relative_path_from(root).to_s.gsub("/", "_")

  # Pinning all Stimulus controllers from components_path under 'prefix' which is the relative path from root with '/'
  # replaced by '_'
  components_path.glob("**/*_controller.js").each do |controller|
    name = controller.relative_path_from(components_path).to_s.remove(/\.js$/)
    pin "#{prefix}/#{name}", to: name
  end
end
