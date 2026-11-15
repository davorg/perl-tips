---
title: "Keep contractions together when splitting text into words"
feature: "unicode-word-boundaries"
feature_name: "Unicode word boundaries"
perl_version: "5.36"
description: "Learn about Unicode word boundaries in Perl. \\b{wb} follows Unicode word-boundary rules, including apostrophes within words. It differs from ordinary \\b and ..."
date: 2026-11-15
tags: ["unicode-word-boundaries"]
layout: single
---

Splitting prose at ordinary `\b` boundaries can break contractions into misleading fragments. If you are preparing search terms or counting word-like segments, an apostrophe inside a word should not necessarily end that word. Perl's `\b{wb}` provides Unicode word-boundary rules for this task.

```perl
use v5.36;

my $text = "Don't stop: we're ready.";

my @ordinary = grep { /\w/ } split /\b/, $text;
my @unicode  = grep { /\w/ } split /\b{wb}/, $text;

say "Text: $text";
say 'Ordinary boundaries: ', join(' / ', @ordinary);
say 'Unicode boundaries:  ', join(' / ', @unicode);
say 'Selected segment count: ', scalar @unicode;

```

Expected output:

```text
Text: Don't stop: we're ready.
Ordinary boundaries: Don / t / stop / we / re / ready
Unicode boundaries:  Don't / stop / we're / ready
Selected segment count: 4

```

The program applies two boundary patterns to exactly the same text. Ordinary `\b` marks transitions between word and non-word characters. An apostrophe is not a word character, so this pattern puts boundaries on both sides of the apostrophes in the contractions. After filtering, the first result contains six fragments rather than the intended four words.

The second pattern uses `\b{wb}`, which follows Unicode word-boundary rules, including rules for apostrophes within words. Here, it keeps `Don't` and `we're` together while still separating the surrounding words and punctuation. The input is deliberately ASCII: Unicode boundary rules can improve segmentation even when the text contains no non-ASCII characters.

Each `split` uses a zero-width boundary pattern, so the boundary itself consumes no text. The resulting pieces can include spaces and punctuation. The `grep { /\w/ }` expression retains only pieces containing a word character; it does not remove punctuation from within a retained piece. That distinction is why the apostrophes survive in the Unicode result. The final `scalar @unicode` reports the number of retained segments.

Unicode word boundaries were introduced in Perl 5.22 and were stable in that release. This program targets Perl 5.36; `use v5.36;` also enables strictness and warnings.

Treat this as boundary-based segmentation, not a complete language-aware tokenizer. The filtering rule is an application choice, and different text may require different handling. Test representative input before using the resulting segment count as a linguistic word count.

Example tested with Perl 5.36.

## More details

[Unicode word boundaries in the Perl documentation](https://perldoc.perl.org/5.36.0/perlrebackslash).

[Read the perldelta behind this tip](https://perldoc.perl.org/5.36.0/perl5220delta).
