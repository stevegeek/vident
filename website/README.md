# Vident Documentation Website

Static documentation site built with Jekyll and the
[jekyll-vitepress-theme](https://github.com/crmne/jekyll-vitepress-theme).
The site deploys to Cloudflare Pages from `main` (see
`.github/workflows/website.yml`).

## Local development

From the repository root:

```bash
# Build the site (also re-renders the live demo HTML / sources)
bundle exec rake website:demos website:build

# Serve with live reload at http://localhost:4000
bundle exec rake website:serve

# Clean generated output
bundle exec rake website:clean
```

Or, manually inside `website/`:

```bash
cd website
bundle install
bundle exec jekyll serve
```

## How the live demo on the landing page works

The landing page leads with a working component (`PhlexGreeters::GreeterVidentComponent`
from the dummy app). Because Cloudflare Pages serves static HTML only, we
pre-render the example at build time:

- `rake website:demos` renders the Phlex component to HTML and writes the
  fragment, the Vident source, and a pretty-printed copy of the rendered
  HTML into `website/_includes/demos/`.
- `website/assets/js/demo.js` ships a tiny Stimulus bundle (loaded from a CDN)
  that registers the controllers under the same identifiers the rendered
  components use, so the demo is interactive in the browser without a server.

If you change the demo component, re-run `rake website:demos` to refresh the
embedded fragments.
