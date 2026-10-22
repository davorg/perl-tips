# Custom design

The direction is a small editorial field guide to modern Perl: warm paper,
deep teal ink, rust accents, generous Newsreader headlines, and DM Sans for
navigation and body copy. The existing `say` mark anchors the identity. A real,
copyable Perl example supplies the homepage's main visual. The content and
code take priority over decorative photography.

Fonts: [Newsreader](https://fonts.google.com/specimen/Newsreader) and
[DM Sans](https://fonts.google.com/specimen/DM+Sans), loaded through Google Fonts
with `display=swap`. Georgia and system sans-serif fallbacks keep the site
readable if fonts cannot load. Code uses the system monospace stack.

## Preview

```sh
bundle install
bundle exec jekyll serve
```

Open `http://127.0.0.1:4000/`, then visit a tip, All tips, and About. All layouts
are local, so builds no longer fetch Minimal Mistakes. The production build and
GitHub Pages workflows use the same Jekyll commands as before.

Review these views at desktop and narrow phone widths:

- The homepage introduction, copyable signatures example, five most recent
  tips, and perldelta reminder.
- A short tip such as `/2026/10/15/signatures/` and a longer one such as
  `/2026/10/19/try-catch/`. Feature names stay directly below their titles;
  long code lines scroll within their blocks.
- `/all-tips/`, with the same date, calendar icon, middle dot, and feature
  name used on the homepage. All visible posts are grouped by year.
- `/about/`, which holds the longer introduction.

The navigation stays visible on phones. Keyboard focus, a skip link, semantic
headings and landmarks, and the copy button's accessible feedback are included.
The design has no animation; small colour transitions respect reduced-motion
preferences. Print styling simplifies article pages.

## Scope

The custom design replaces the theme's layouts, CSS, icon font, header, footer,
and analytics wrapper. It keeps Jekyll, Kramdown, Rouge, the existing SEO
include, Atom feed, sitemap, GA4 measurement ID, generator, Markdown posts,
post metadata, and published URLs. There is one visible feed link per page,
in the footer. Analytics loads only in production builds.

The signatures teaser is intentionally a fixed introductory example. It links
to the signatures tip and does not change as new tips are published.

The existing Pages workflow deploys changes pushed to `main`.

## Validation

Production and development builds pass with the normal Gemfile and config,
including a development build under `/prototype`. Rendered checks cover all
11 current pages: internal links and assets, the five-tip limit, complete
archive, matching feature/date labels, one footer feed link, canonical URLs,
JSON-LD, and production-only GA4. Every rendered example and expected-output
block matches its Markdown source. All eight post-formatting checks and the
existing copy-button interaction checks pass.

Dave reviewed the site in a browser and confirmed the design and behaviour
before merging. Automated browser review was unavailable: Chromium could not
launch under the workspace's socket restrictions, and Google Fonts could not
be fetched from that workspace. The preview instructions above support future
checks of phone layouts, font loading, and keyboard interactions.
