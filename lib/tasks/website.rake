# frozen_string_literal: true

WEBSITE_DIR = File.expand_path("../../website", __dir__)

namespace :website do
  desc "Render demo components and write HTML/source fragments into the docs site"
  task :demos do
    require File.expand_path("../../test/dummy/config/environment", __dir__)
    require "fileutils"

    out = File.join(WEBSITE_DIR, "_includes", "demos")
    FileUtils.mkdir_p(out)

    # Each demo declares twin components — one Phlex, one ViewComponent —
    # implementing the same UI. The site shows the Phlex render as the
    # canonical Live + Rendered HTML output (its source is cleaner than
    # ERB's auto-encoded form), and the source tab toggles between the
    # two engines' source files.
    demos = [
      {
        slug: "task_card",
        title: "Task card",
        args: [
          {task_id: 1, title: "Write the launch announcement", priority: :high, status: :todo, tags: ["docs", "marketing"]},
          {task_id: 2, title: "Migrate the legacy importer", priority: :medium, status: :done, tags: ["backend"]},
          {task_id: 3, title: "Add Stripe webhooks", priority: :low, status: :wont_do, tags: ["payments", "deferred"]}
        ],
        phlex: {
          component: ::Phlex::TaskCardComponent,
          source_path: "test/dummy/app/components/phlex/task_card_component.rb"
        },
        view_component: {
          component: ::ViewComponent::TaskCardComponent,
          source_path: "test/dummy/app/components/view_component/task_card_component.rb",
          template_path: "test/dummy/app/components/view_component/task_card_component.html.erb"
        }
      }
    ]

    view_context = ActionController::Base.new.view_context

    demos.each do |demo|
      phlex_html = render_with_seed(demo[:slug]) do
        demo[:args].map { |a| demo[:phlex][:component].new(**a).call }.join
      end

      vc_html = render_with_seed(demo[:slug]) do
        demo[:args].map { |a| demo[:view_component][:component].new(**a).render_in(view_context) }.join
      end

      # The Phlex render is the visible Live + Rendered HTML output.
      # ERB auto-encodes `>` in attribute values to `&gt;`, which decodes
      # identically in browsers but reads worse in the Raw HTML tab.
      live_html = clean(phlex_html)

      File.write(File.join(out, "#{demo[:slug]}_rendered.html"), live_html + "\n")
      File.write(File.join(out, "#{demo[:slug]}_html.html"), pretty_html(live_html))

      File.write(
        File.join(out, "#{demo[:slug]}_phlex_source.rb"),
        File.read(File.expand_path("../../#{demo[:phlex][:source_path]}", __dir__))
      )

      vc_source = File.read(File.expand_path("../../#{demo[:view_component][:source_path]}", __dir__))
      vc_template = File.read(File.expand_path("../../#{demo[:view_component][:template_path]}", __dir__))
      vc_combined = "# #{File.basename(demo[:view_component][:source_path])}\n#{vc_source}\n"
      vc_combined += "# #{File.basename(demo[:view_component][:template_path])}\n#{vc_template}"
      File.write(File.join(out, "#{demo[:slug]}_view_component_source.rb"), vc_combined)

      # Sanity check: warn (don't fail) if the two engines diverge in their
      # rendered HTML beyond the known ERB encoding cosmetics.
      if normalised(phlex_html) != normalised(vc_html)
        warn "  ⚠ #{demo[:slug]}: Phlex and ViewComponent renders differ beyond ERB encoding"
      end

      puts "  rendered #{demo[:slug]} → #{live_html.bytesize} bytes"
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

  def render_with_seed(slug, &block)
    Vident::StableId.with_sequence_generator(seed: "vident-docs-#{slug}", &block)
  end

  # Strip the development-only "Before ..." HTML comment that the dummy
  # ApplicationComponent injects, plus ViewComponent's per-template
  # "<!-- BEGIN/END ... -->" annotations, so the embedded fragment stays clean.
  def clean(html)
    html
      .gsub(/<!--\s*Before [^>]*?-->/, "")
      .gsub(/<!--\s*(BEGIN|END)\s+app\/components.*?-->/, "")
      .strip
  end

  # For the divergence sanity check: normalise away cosmetic encoding
  # differences (ERB encodes `>` in attribute values to `&gt;`) so the
  # comparison reflects semantic equivalence.
  def normalised(html)
    clean(html)
      .gsub("&gt;", ">")
      # Collapse whitespace between tags and inside attribute values so the
      # comparison reflects semantic equivalence, not ERB's incidental
      # indentation or trailing spaces from empty class interpolations.
      .gsub(/>\s+</, "><")
      .gsub(/="([^"]*)"/) { %(="#{$1.strip.gsub(/\s+/, " ")}") }
      .strip
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
