# frozen_string_literal: true

namespace :website do
  WEBSITE_DIR = File.expand_path("../../website", __dir__)

  desc "Render demo components and write HTML/source fragments into the docs site"
  task :demos do
    require File.expand_path("../../test/dummy/config/environment", __dir__)
    require "fileutils"

    out = File.join(WEBSITE_DIR, "_includes", "demos")
    FileUtils.mkdir_p(out)

    demos = [
      {
        slug: "release_card",
        title: "Deploy dashboard release card",
        component: Dashboard::ReleaseCardComponent,
        args: {release_id: 1, name: "API Gateway", version: "2.4.1", environment: :production, status: :deployed},
        # The release card emits a sibling card and a third "pending" card so
        # the demo shows the dynamic `status:` class colours side by side.
        siblings: [
          {release_id: 2, name: "Auth Service", version: "1.9.0", environment: :staging, status: :pending},
          {release_id: 3, name: "Web Frontend", version: "3.0.0-rc1", environment: :preview, status: :failed}
        ],
        source_path: "test/dummy/app/components/dashboard/release_card_component.rb"
      }
    ]

    demos.each do |demo|
      html = Vident::StableId.with_sequence_generator(seed: "vident-docs-#{demo[:slug]}") do
        rendered = demo[:component].new(**demo[:args]).call
        Array(demo[:siblings]).each do |sibling_args|
          rendered += demo[:component].new(**sibling_args).call
        end
        rendered
      end
      # Strip the development-only "Before ..." HTML comment that the dummy
      # ApplicationComponent injects so the embedded fragment stays clean.
      html = html.gsub(/<!--\s*Before [^>]*?-->/, "").strip

      source = File.read(File.expand_path("../../#{demo[:source_path]}", __dir__))

      File.write(File.join(out, "#{demo[:slug]}_rendered.html"), html + "\n")
      File.write(File.join(out, "#{demo[:slug]}_source.rb"), source)
      File.write(File.join(out, "#{demo[:slug]}_html.html"), pretty_html(html))
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

  # Pretty-prints the rendered fragment for the "Raw HTML" tab. Nokogiri
  # escapes `>` inside attribute values to `&gt;` (correct HTML5, but ugly to
  # read), so we unescape that back — the result is still valid HTML and
  # matches what a developer would expect to see in their source.
  def pretty_html(html)
    require "nokogiri"
    Nokogiri::HTML5.fragment(html).to_xhtml(indent: 2).gsub("&gt;", ">")
  end
end
