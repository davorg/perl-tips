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
Both lists show a small publication date with a calendar icon beneath each title,
using day-month-year format. Individual tips show
the reviewed feature name in small caps directly below the title. The name comes
from `feature_name` metadata, with the internal `feature` ID retained for tracking.
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

The original posts and covered-topic history were reset on 2026-10-18. Seven
new tips cover 12–18 October 2026, one per day, generated with the current
execution checks and technical review. The covered-feature list contains only
those seven topics; subsequent daily runs continue with the next uncovered topic.

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
   Topics have canonical IDs, legacy aliases, factual notes, introduction/stability
   versions, a test version, and fixed documentation and perldelta links. The model
   cannot invent the topic or the documentation URL. Aliases such as `signatures`,
   `sub signatures`, and `subroutine signatures` count as one topic.
3. Request a structured JSON draft with a helpful title, a problem, one
   standalone Perl program, its exact expected stdout, and an explanation.
   The prompt targets the topic's tested Perl version (5.36 or 5.44), requires
   stable features and all setup and inputs, and rules out placeholders,
   external dependencies, warning suppression, and nondeterministic output.
4. Check the HTTP response, completion status, refusal, JSON schema, and draft
   format. Prose must use balanced, single-line backtick spans for inline code;
   bare pipes, variables, underscored identifiers, dereferences, regex escapes
   and asterisks are rejected because Markdown or typography can alter them.
   Formatting failures go back to the writer for repair before execution or saving.
   Run the program in an isolated Docker container for the selected Perl version. Compilation
   failures, runtime failures, stderr, timeouts, excessive output, or stdout
   that differs from the promised output reject the draft.
5. Ask a separate technical-review request to check that the example actually
   demonstrates the topic, the title describes its practical benefit, and the
   prose and version claims are accurate. The writing and review prompts require
   inline Perl syntax to use backtick code spans. Titles must be plain text on one line,
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

The catalogue has 65 topics, expanded from the Perl 5.10–5.44 release notes.
Seven are covered by the launch posts, leaving 58. `topics.json` is the queue;
`covered-features.json` is publication history. The next topic is stable
try/catch, with newer and older subjects following. Generation deliberately stops
when all topics are covered.

Each topic records `introduced`, `stable_since`, `perl_version`, `status`,
aliases, factual notes, and versioned reference and perldelta URLs. Only stable
topics can be selected; experimental subjects are recorded separately in
[the catalogue review](docs/topic-catalogue.md), including named parameters and
enhanced `/xx` from 5.44. That document also describes the research sources and
how to replenish the queue after future releases. The selected Docker image is
checked before any API request. Writer, reviewer, version declaration and
example execution all use the same selected version. New posts display that
version and link to the perldelta behind the topic. Existing posts retain their
original version declarations. No live documentation fetch is performed during
article generation; reviewed catalogue metadata is supplied to both requests.

## Local development

Perl 5.36+, Ruby/Bundler, Docker, and an OpenAI API key are needed for generation.
Install dependencies and prepare the example images:

```sh
cpanm --installdeps .
bundle install
docker pull perl:5.36
docker pull perl:5.44
```

Run the checks without API requests:

```sh
perl -c bin/generate_post
prove -Ilib t
PERL_TIPS_CONTAINER_TEST=1 prove -Ilib t/sandbox.t
bundle check
```

The generator tests use injected API responses and a fake Docker executable to
exercise rejection, repair, output comparison, API errors, aliases, state
handling, locks, and sandbox failure handling. The opt-in container tests run
real Perl 5.36 and 5.44 programs, including broken examples, filesystem-isolation
checks, and newer stable syntax. They require Docker access and both prepared images.

`t/posts.t` also checks the current articles' prose for unprotected inline Perl
syntax, covering manual edits as well as generated drafts. Fenced examples and
expected output are left literal, and the app-supplied documentation links are
outside this prose check.

Configure `OPENAI_API_KEY` in the environment, then generate an article:

```sh
bin/generate_post
# Or an explicit publication date:
bin/generate_post 2026-10-18
```

This makes live API requests and changes `_posts/` and
`data/covered-features.json` only on success. The date argument cannot overwrite
an existing publication day. The original experimental posts and their feature
history have been replaced by the validated launch tips.

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
| [`docs/topic-catalogue.md`](docs/topic-catalogue.md) | Release-note research, experimental-topic backlog and replenishment process. |
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
| [`.github/workflows/daily-tip.yml`](.github/workflows/daily-tip.yml) | Daily generation, checks, commit/push automation, and deployment call. |
| [`.github/workflows/pages.yml`](.github/workflows/pages.yml) | Reusable Jekyll build and GitHub Pages deployment. |

The daily workflow runs at 03:00 UTC or via manual dispatch. It installs Perl 5.36,
runs the offline tests and real container checks, and then generates an article
with the `OPENAI_API_KEY` secret. A failed check prevents the commit/push step.
Workflow concurrency and a local lock prevent overlapping generation.

## Deployment

The Pages workflow runs on pushes to `main`, via manual dispatch on `main`, or
as a reusable workflow called after successful daily generation on `main`.
The daily workflow passes the resulting commit SHA so the build includes the
new article. This explicit call is needed because pushes made with
`GITHUB_TOKEN` do not trigger another push workflow.

The build uses Ruby 3.3, the locked Bundler dependencies, and
`JEKYLL_ENV=production`, then uploads `_site/` as a Pages artifact. A separate
job deploys that artifact to the `github-pages` environment with Pages and OIDC
permissions. Pages runs share a concurrency group and do not cancel an active
deployment. No additional deployment secret is required.

In repository Settings → Pages, select **GitHub Actions** as the source and set
the custom domain to `tips.perlhacks.com`. The domain's DNS CNAME should point
to `davorg.github.io`; enable HTTPS when available. The repository's `CNAME`
file does not configure the custom domain for an Actions deployment. The
repository settings and initial Pages deployment have been confirmed working.

## Findings still relevant before launch

The inherited CSS homepage, image references, footer repository link, and
custom-domain file have been replaced with Modern Perl Tips branding. Navigation
now points to Home, All tips, and perldelta. The theme's automatic footer feed
link is the single visible feed link on each page. `CNAME` and `_config.yml`
agree on `tips.perlhacks.com`. GitHub Pages deployment has been confirmed working.
The old CSS images remain as unused files.

The original articles with technical errors and repeated subjects have been
removed. The generator tests use independent fixtures.

Initial local verification on 2026-10-18 passed generator syntax and offline regression
checks with Perl 5.42.3, JavaScript copy-interaction checks, and workflow lint.
The site built using the installed Minimal Mistakes 4.28.0 theme with a temporary
configuration. Before the content reset, checks covered all 26 rendered pages' SEO and social metadata,
the five-tip homepage limit, the complete archive, updated article and feed
titles, stable URLs, image dimensions, the single footer feed link, and GA4.

Local Docker access and visual browser checks were blocked by the workspace
sandbox. The seven replacement posts were generated in a temporary GitHub
Actions branch using the existing generator and API secret. The
[generation run](https://github.com/davorg/perl-tips/actions/runs/39114218421)
passed all 65 regression tests, all 27 real-container checks, and exact-output
execution and technical review for every saved tip. One draft was rejected for
an uninitialized-value warning and repaired before saving. Local site checks
after the reset verified seven dated tips, five homepage entries, the complete
archive and feed, and removal of old post URLs from the generated site and sitemap.
The local build used the installed theme because remote-theme downloads remain
blocked in this workspace.

Inline-formatting safeguards subsequently brought the offline suite to 75 tests.
They cover rejection and repair of bare prose pipes and malformed backtick spans,
while preserving operators in inline code, executable examples, and expected
output. The rebuilt 14 October post was checked for literal inline operators
and the absence of an accidental Markdown table.

The catalogue expansion passed 103 offline tests and all 41 sandbox checks
using real Perl 5.36 and 5.44 Docker images in
[GitHub Actions](https://github.com/davorg/perl-tips/actions/runs/39116410630).
Workflow lint and a local site build passed; catalogue review notes are excluded
from the published site. See [the review record](docs/topic-catalogue.md) for
sources, the encoding-pragma finding, and experimental subjects held for later.

The broader prose-formatting checks bring the suite to 124 tests. All seven
posts now use inline code for Perl syntax, including `$_`, `@_`, `$"`, variable
names and dereferences. Their rendered HTML was checked against the literal
inline code in the Markdown: no unintended emphasis or tables, and the original
documentation URLs remain intact. Executable examples and expected output were
preserved exactly.
