# Topic catalogue review

Reviewed on 2026-10-18 against the official Perl release notes and versioned
documentation. `data/topics.json` is the active queue, not publication history.
The queue has 65 topics; the seven launch topics are already covered, leaving
58. Keep the existing IDs when changing the ordering or improving the notes.

## Runtime and release metadata

Each entry records `introduced`, `stable_since`, `perl_version`, `status`,
`reference_url`, `release_notes_url`, aliases and factual notes. Introduction
means the first production release containing the capability, which may have
been experimental then. Stability is a separate milestone. For the builtin
topics, the capability is specifically the builtin function, rather than older
equivalents from modules such as Scalar::Util or POSIX.

Existing topics and older additions use the `perl:5.36` example runner. Newer
additions use `perl:5.44`. The generator itself still runs on Perl 5.36+. A
topic's test version must cover its stability milestone, and its documentation
links must be pinned to that version. The selected container is checked before
the first API request; the writer, reviewer, required version declaration and
example runner all receive the same version. New posts record and display the
tested version and link to the perldelta used for review. Existing posts keep
their original examples and requirements.

Perl 5.44 version bundles check for ASCII source by default. Put `use utf8;` or
`use source::encoding 'utf8';` on its own line before the first line containing
non-ASCII source. The container test deliberately covers this boundary.

## Release notes used

The 5.44 notes were checked online; older perldeltas were also read from the
official POD installed with Perl. Every catalogue entry links to the relevant
versioned perldelta, usually the release that made the feature stable.

| Release | Additions or review findings |
| --- | --- |
| [5.44](https://perldoc.perl.org/5.44.0/perldelta) | Unicode 17 properties; named parameters, aliased multi-variable loops and enhanced `/xx` remain experimental. |
| [5.42](https://perldoc.perl.org/5.44.0/perl5420delta) | Source encoding, logical xor assignment and lexical method invocation. |
| [5.40](https://perldoc.perl.org/5.44.0/perl5400delta) | Stable try/catch, multi-variable iteration and selected builtins; logical xor. |
| [5.38](https://perldoc.perl.org/5.44.0/perl5380delta) | Defined-or and logical-or signature defaults. |
| [5.36](https://perldoc.perl.org/5.36.0/perl5360delta) | Stable regex sets and noncapturing variable-length lookbehind. |
| [5.34](https://perldoc.perl.org/5.36.0/perl5340delta) | Explicit octal literals and whitespace within braced regex constructs. |
| [5.32](https://perldoc.perl.org/5.36.0/perl5320delta) | Chained comparisons and stable Unicode script runs. |
| [5.28](https://perldoc.perl.org/5.36.0/perl5280delta) | Aggregate state initialization and deleting key/value slices. |
| [5.26](https://perldoc.perl.org/5.36.0/perl5260delta) | Indented heredocs and the capture array. |
| [5.24](https://perldoc.perl.org/5.36.0/perl5240delta) | Unicode line-break boundaries. |
| [5.22](https://perldoc.perl.org/5.36.0/perl5220delta) | Unicode word and grapheme boundaries. |
| [5.20](https://perldoc.perl.org/5.36.0/perl5200delta) | Key/value and index/value slices. |
| [5.16](https://perldoc.perl.org/5.36.0/perl5160delta) | Automatic named-character support. |
| [5.14](https://perldoc.perl.org/5.36.0/perl5140delta) | Regex modifier controls, ASCII classes and scoped package declarations. |
| [5.12](https://perldoc.perl.org/5.36.0/perl5120delta) | Package versions, array iteration functions and temporary hash deletion. |
| [5.10](https://perldoc.perl.org/5.36.0/perl5100delta) | Regex enhancements, binary byte-order controls, C3 resolution and UNITCHECK. |

The Unicode 17 example notes additionally use the Unicode Consortium's
[Unicode 17 release information](https://www.unicode.org/versions/Unicode17.0.0/)
for the Sidetic block. Builtin status was checked against the
[5.44 builtin documentation](https://perldoc.perl.org/5.44.0/builtin), not inferred
from the module's overall stability: individual functions can remain experimental.

## Ideas held for later review

These are useful future subjects but are not active stable topics. Current
generation keeps warnings enabled and does not suppress experimental warnings.
Recheck the [current experimental-feature list](https://perldoc.perl.org/5.44.0/perlexperiment)
when a new Perl release arrives.

| Idea | First production release | Reason to hold |
| --- | --- | --- |
| Named parameters in signatures | 5.44 | `experimental::signature_named_parameters`; distinct from stable positional signatures. |
| Aliased references in multi-variable loops | 5.44 | Requires experimental `refaliasing` and `declared_refs`. |
| Enhanced `/xx` character classes | 5.44 | `experimental::enhanced_xx`; distinct from the existing stable `/xx` modifier. |
| Native `any` and `all` keywords | 5.42 | Experimental keyword features; do not confuse these with List::Util functions. |
| The new `class` system, fields and accessors | 5.38 onward | The class system remains experimental, including related reader/writer and lexical-method declarations. Ordinary lexical-sub invocation via `->&` does not require it. |
| `defer` and `finally` | 5.36 | Remain experimental; stable try/catch does not make these stable. |
| Other builtin utilities | Various | `is_bool`, `inf`, `nan`, `created_as_*`, `stringify`, `export_lexically` and `load_module` are not part of the stable builtin bundle. |

## Replenishing the queue

For each new stable Perl release, read its perldelta first, then work backwards
through older deltas for missed practical changes. Confirm each idea in the
versioned reference documentation and check its experimental status. Add
accurate introduction and stability milestones, a supported test version,
reviewed notes, aliases and both documentation links. Keep one canonical ID per
subject and preserve covered IDs; do not reset publication history to replenish
the queue. One-time initialization of aggregate state variables is separate from
the original scalar-state introduction, for example, while renamed aliases of
the same feature belong in one entry.

Add a new interpreter version to the generator and sandbox allowlists, workflow
image preparation and container tests before activating topics that need it.
Run the offline tests and real container checks for both supported runtimes.
Topic exhaustion still fails explicitly instead of allowing invented subjects.

## Validation

The [validation run](https://github.com/davorg/perl-tips/actions/runs/39116410630)
passed the 103-test offline suite and all 41 sandbox tests with both real Docker
images. New smoke examples cover the actual 5.44 interpreter, stable try/catch,
multi-variable loops, builtin imports, signature defaults, Unicode 17, logical
xor assignment, lexical-sub method invocation and UTF-8 source. An initial
encoding test exposed the same-line pragma issue described above; the corrected
test passes with the pragma on its own earlier line. Local workflow lint and
the site build also passed. The internal review document is excluded from the
published site. These checks verify the generator and representative syntax;
every future article still goes through execution and independent prose review.
