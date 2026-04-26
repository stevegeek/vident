# frozen_string_literal: true

WEBSITE_DIR = File.expand_path("../../website", __dir__)

namespace :website do
  desc "Render demo components and write HTML/source fragments into the docs site"
  task :demos do
    require File.expand_path("../../test/dummy/config/environment", __dir__)
    require "fileutils"

    out = File.join(WEBSITE_DIR, "_includes", "demos")
    FileUtils.mkdir_p(out)

    # The homepage demo is the same Phlex component the dummy app renders at
    # /components/tasks. We pre-render it here so the static site can ship
    # byte-identical HTML, paired with the same Stimulus controller registered
    # in `website/assets/js/demo.js`.
    demos = [
      {
        slug: "task_card",
        component: ::Tasks::TaskCardComponent,
        source_path: "test/dummy/app/components/tasks/task_card_component.rb",
        args: [
          {task_id: 1, title: "Write the launch announcement", due: "Today", list: :today, status: :todo},
          {task_id: 2, title: "Migrate the legacy importer", due: "Wed", list: :this_week, status: :done},
          {task_id: 3, title: "Add Stripe webhooks", due: "—", list: :backlog, status: :wont_do}
        ]
      }
    ]

    demos.each do |demo|
      html = Vident::StableId.with_sequence_generator(seed: "vident-docs-#{demo[:slug]}") do
        demo[:args].map { |a| demo[:component].new(**a).call }.join
      end
      html = clean(html)

      File.write(File.join(out, "#{demo[:slug]}_rendered.html"), html + "\n")
      File.write(File.join(out, "#{demo[:slug]}_html.html"), pretty_html(html))
      File.write(
        File.join(out, "#{demo[:slug]}_source.rb"),
        File.read(File.expand_path("../../#{demo[:source_path]}", __dir__))
      )

      puts "  rendered #{demo[:slug]} → #{html.bytesize} bytes"
    end

    puts "Wrote demos to #{out}"
  end

  desc "Build the documentation website"
  task build: :demos do
    Dir.chdir(WEBSITE_DIR) do
      sh "bundle install"
      sh "bundle exec jekyll build"
    end
  end

  desc "Serve the documentation website locally with live reload"
  task serve: :demos do
    Dir.chdir(WEBSITE_DIR) do
      sh "bundle install"
      sh "bundle exec jekyll serve --livereload"
    end
  end

  desc "Clean the documentation website build"
  task :clean do
    Dir.chdir(WEBSITE_DIR) do
      sh "bundle exec jekyll clean"
    end
  end

  # Strip the development-only "Before ..." HTML comment that the dummy
  # ApplicationComponent injects so the embedded fragment stays clean.
  def clean(html)
    html.gsub(/<!--\s*Before [^>]*?-->/, "").strip
  end

  # Pretty-prints the rendered fragment for the "Rendered HTML" tab. Nokogiri
  # escapes `>` inside attribute values to `&gt;` (correct HTML5, but ugly to
  # read), so we unescape that back — the result is still valid HTML and
  # matches what a developer would expect to see in their source.
  def pretty_html(html)
    require "nokogiri"
    Nokogiri::HTML5.fragment(html).to_xhtml(indent: 2).gsub("&gt;", ">")
  end
end
