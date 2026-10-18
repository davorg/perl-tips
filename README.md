# Modern Perl Tips

A static Jekyll blog with a Perl script that generates and checks short articles
about modern Perl. The repository is
[`davorg/perl-tips`](https://github.com/davorg/perl-tips); the intended site is
`https://tips.perlhacks.com/`.

The message is **useful Perl features, one small tip at a time**: help existing
Perl programmers discover additions they may have missed, encourage reading
[perldelta](https://metacpan.org/dist/perl/view/pod/perldelta.pod) with each new
release, and keep Perl reasonably up to date. This appears on the homepage,
in site metadata, and in a reminder in the footer on every page.

The homepage shows the five newest tips, with the complete archive on All tips.
Code blocks have a compact, keyboard-accessible copy button in the top-right corner.
It copies the code as plain text, preserves whitespace, and confirms success.
If clipboard access is denied or unavailable, the code is selected for manual
copying and a message explains what to do.

SEO metadata is rendered once by `_includes/seo.html`. It supplies canonical
URLs, concise descriptions, Open Graph image dimensions and alt text, and
large-image Twitter card tags. JSON-LD identifies the homepage as a WebSite,
the index as a CollectionPage, and tips as BlogPosting articles with the author
and publication dates. Collection-page build dates are not presented as article
publication dates. New generated tips have a useful, reader-facing headline
that describes the practical benefit of the example. That headline is used in
the article, listings, feed, search metadata, and social cards. The feature ID
stays in `feature`, tags, filenames, and the covered-feature list. Descriptions
are based on the reviewed topic notes. Changing a headline does not change its URL.

All 24 existing posts have been given descriptive headlines, with their feature
IDs retained in metadata. Their bodies, dates, tags, filenames, and URLs were
preserved. This title backfill does not fix the historical articles' technical
errors; those articles are still planned for replacement before launch.

Google Analytics uses GA4 measurement ID `G-M8YLPJPFFR`, configured under
`analytics.google.tracking_id` in `_config.yml`.

The teal `say` mark is an editable SVG used in the masthead and as the favicon.
The social preview has an SVG source and a PNG export in `img/`. Regenerate it
after changing the source with:

```sh
rsvg-convert -o img/perl-tips-social.png img/perl-tips-social.svg
```

## Generation and validation

Run `bin/generate_post [YYYY-MM-DD]` from any directory. Without a date it uses
today's UTC date. Generation follows these steps:

1. Lock generation, validate the date and covered-feature state, and reject a
   date that already has a post.
2. Choose the first uncovered topic in [`data/topics.json`](data/topics.json).
   Topics have canonical IDs, legacy aliases, introduction versions, factual
   notes, and fixed links to the Perl 5.36 documentation. The model cannot
   invent the topic or the documentation URL. Aliases such as `signatures`,
   `sub signatures`, and `subroutine signatures` count as one topic.
3. Request a structured JSON draft with a helpful title, a problem, one
   standalone Perl program, its exact expected stdout, and an explanation.
   The prompt targets stable Perl 5.36, requires all setup and inputs, and rules out placeholders,
   external dependencies, warning suppression, and nondeterministic output.
4. Check the HTTP response, completion status, refusal, JSON schema, and draft
   format. Run the program in an isolated `perl:5.36` Docker container. Compilation
   failures, runtime failures, stderr, timeouts, excessive output, or stdout
   that differs from the promised output reject the draft.
5. Ask a separate technical-review request to check that the example actually
   demonstrates the topic, the title describes its practical benefit, and the
   prose and version claims are accurate. Titles must be plain text on one line,
   have at least four words, and be no longer than 100 characters. Bare feature
   labels and the old “feature in Perl” titles are rejected before execution.
   Approval requires `approved: true` and an empty issues list.
6. Send validation/review feedback back to the writer when a draft fails, up
   to three drafts total. Exhaustion exits unsuccessfully without saving an
   article or changing the covered list. Invalid writer API responses abort.
7. Only after every check succeeds, render Markdown and escaped front matter,
   create the post without overwriting another file, and atomically replace
   the covered-feature list. A failure writing the list rolls back the new post.
   An abrupt process/machine crash between the two file writes still requires
   manual reconciliation.

Both writing and review use the existing `gpt-6.1-sol` model with low reasoning
effort. There is no model-based topic-selection request. The implementation
uses strict JSON schemas and also validates returned data locally, following
[OpenAI's Structured Outputs guidance](https://developers.openai.com/api/docs/guides/structured-outputs?api-mode=chat).
A model review remains fallible; these checks greatly reduce errors but do not
prove every technical statement. Review the published result as well.

The sandbox has no network, host mounts, or API credentials, runs as an
unprivileged user with a read-only root, and has memory, CPU, process, output,
and time limits. Even `perl -c` can execute `BEGIN` and `use` blocks, so generated
code is never compiled on the host. A runner self-check precedes the first API
request. Missing Docker access or a missing image prevents generation.

The initial catalogue has 18 topics. It deliberately stops when all are covered.
To extend it, review a new topic against the linked official documentation,
verify that it is stable on Perl 5.36, supply accurate introduction/version notes,
and add all known aliases. Keep one ID per subject. The linked
[feature documentation](https://perldoc.perl.org/5.36.0/feature),
[operator documentation](https://perldoc.perl.org/5.36.0/perlop), and
[regular-expression documentation](https://perldoc.perl.org/5.36.0/perlre)
are useful starting points. No live documentation fetch is performed during
article generation; the reviewed catalogue notes are supplied to both requests.

## Local development

Perl 5.36+, Ruby/Bundler, Docker, and an OpenAI API key are needed for generation.
Install dependencies and prepare the example image:

```sh
cpanm --installdeps .
bundle install
docker pull perl:5.36
```

Run the checks without API requests:

```sh
perl -c bin/generate_post
prove -Ilib t
PERL_TIPS_CONTAINER_TEST=1 prove -Ilib t/sandbox.t
bundle check
```

The default tests use injected API responses and a fake Docker executable to
exercise rejection, repair, output comparison, API errors, aliases, state
handling, locks, and sandbox failure handling. The opt-in container tests run
real Perl 5.36 programs, including broken examples and filesystem-isolation
checks. They require Docker access and the prepared image.

Configure `OPENAI_API_KEY` in the environment, then generate an article:

```sh
bin/generate_post
# Or an explicit publication date:
bin/generate_post 2026-10-18
```

This makes live API requests and changes `_posts/` and
`data/covered-features.json` only on success. The date argument cannot overwrite
an existing publication day. Posts from the original experiment and its feature
list are still present; resetting those for launch is a separate task.

Preview or build the site:

```sh
bundle exec jekyll serve
JEKYLL_ENV=production bundle exec jekyll build
```

Jekyll downloads the Minimal Mistakes remote theme, so a fresh build requires
network access even when gems are already installed. `_site/` is generated
output. Development code, tests, the catalogue, and this README are excluded
from the site build.

## Repository map

| Path | Purpose |
| --- | --- |
| [`bin/generate_post`](bin/generate_post) | CLI and OpenAI client setup. |
| [`lib/PerlTips/Generator.pm`](lib/PerlTips/Generator.pm) | Topic selection, prompts, validation, repair, review, rendering, and saving. |
| [`lib/PerlTips/Sandbox.pm`](lib/PerlTips/Sandbox.pm) | Isolated example execution and resource limits. |
| [`data/topics.json`](data/topics.json) | Reviewed topic catalogue and legacy aliases. |
| [`data/covered-features.json`](data/covered-features.json) | Covered names/IDs; appended only after approval. |
| [`t/`](t/) | Offline regression tests and opt-in container tests. |
| [`cpanfile`](cpanfile) | Perl dependencies, including JSON::Validator and IPC::Run. |
| [`_posts/`](_posts/) | Article source with YAML front matter and fenced examples. |
| [`_pages/index.md`](_pages/index.md) | Homepage copy using the local `home` layout. |
| [`_pages/all-tips.html`](_pages/all-tips.html) | Complete tip index, grouped by year with newest tips first. |
| [`_layouts/home.html`](_layouts/home.html) | Homepage layout with the five most recent tips. |
| [`_includes/seo.html`](_includes/seo.html) | Canonical URLs, descriptions, social cards, and JSON-LD. |
| [`assets/js/code-copy.js`](assets/js/code-copy.js), [`assets/css/code-copy.css`](assets/css/code-copy.css) | Copy buttons and feedback for code blocks. |
| [`_config.yml`](_config.yml) | Site identity, remote theme, plugins, analytics, URLs, and exclusions. |
| [`_data/`](_data/) | Navigation and legacy footer-link data; active footer links are configured in `_config.yml`. |
| [`Gemfile`](Gemfile), [`Gemfile.lock`](Gemfile.lock) | Ruby dependencies; currently locks Jekyll 4.4.1 and Bundler 2.5.22 for x86_64 Linux. |
| [`Gemfile.old`](Gemfile.old) | Previous Jekyll 3.9 manifest; not active. |
| [`.github/workflows/daily-css.yml`](.github/workflows/daily-css.yml) | Daily generation, checks, and commit/push automation. |

The workflow runs at 03:00 UTC or via manual dispatch. It installs Perl 5.36,
runs the offline tests and real container checks, and then generates an article
with the `OPENAI_API_KEY` secret. A failed check prevents the commit/push step.
Workflow concurrency and a local lock prevent overlapping generation. No site
build or deployment step is defined in this workflow; hosting settings must be
checked separately.

## Findings still relevant before launch

The inherited CSS homepage, image references, footer repository link, and
custom-domain file have been replaced with Modern Perl Tips branding. Navigation
now points to Home, All tips, and perldelta. The theme's automatic footer feed
link is the single visible feed link on each page. `CNAME` and `_config.yml`
agree on `tips.perlhacks.com`; DNS and hosting settings still need checking
before launch. The old CSS images remain as unused files.

The original articles contain technical errors and repeated subjects; they are
planned for deletion before launch. The generator tests use independent fixtures
and do not require those historical posts to pass.

Local verification on 2026-10-18 passed generator syntax and offline regression
checks with Perl 5.42.3, JavaScript copy-interaction checks, and workflow lint.
The site built using the installed Minimal Mistakes 4.28.0 theme with a temporary
configuration. Checks covered all 26 rendered pages' SEO and social metadata,
the five-tip homepage limit, the complete archive, updated article and feed
titles, stable URLs, image dimensions, the single footer feed link, and GA4.

Real Docker tests and visual browser checks were blocked by the workspace
sandbox; real container checks are mandatory in the daily workflow. Downloading
the remote theme was also blocked in this workspace. Live API compatibility,
hosting configuration, and live-site behavior have not been verified.
