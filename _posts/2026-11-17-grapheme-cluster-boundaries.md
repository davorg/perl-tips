---
title: "Truncate Unicode labels without separating combining accents"
feature: "grapheme-cluster-boundaries"
feature_name: "Unicode grapheme boundaries"
perl_version: "5.36"
description: "Learn about Unicode grapheme boundaries in Perl. \\b{gcb} identifies boundaries of grapheme clusters. A base character plus combining mark can form one cluste..."
date: 2026-11-17
tags: ["grapheme-cluster-boundaries"]
layout: single
---

A short label preview should not discard an accent merely because the display limit falls between a letter and its combining mark. Counting with `length` alone does not protect that pair: a base letter and combining accent can count as two characters while forming one grapheme cluster. For already-decoded Unicode text, split at grapheme boundaries before selecting the preview.

```perl
use v5.36;
binmode STDOUT, ':encoding(UTF-8)';

my $label = "Cafe\x{301}!";
my $limit = 4;

my @clusters = split /\b{gcb}/, $label;
my $preview = join '', @clusters[0 .. $limit - 1];

say 'Character count: ', length($label);
say 'Grapheme cluster count: ', scalar @clusters;
say "Original: $label";
say "Preview: $preview";
say 'Preview code points: ', join ' ',
    map { sprintf 'U+%04X', ord($_) } split //, $preview;

```

Expected output:

```text
Character count: 6
Grapheme cluster count: 5
Original: Café!
Preview: Café
Preview code points: U+0043 U+0061 U+0066 U+0065 U+0301

```

The regex boundary assertion `\b{gcb}`, introduced and stable in Perl 5.22, identifies grapheme cluster boundaries. Unlike an ordinary word boundary, it separates grapheme clusters rather than words. Because it is zero-width, it consumes no characters itself. Using it as the separator for `split` preserves each cluster's contents in an element of `@clusters`.

The sample constructs the label with `\x{301}`, a combining acute accent following the final letter. Thus `length($label)` reports six characters, while `scalar @clusters` reports five clusters. The letter and its combining accent occupy one array element even though they remain two characters in the string.

The slice `@clusters[0 .. $limit - 1]` selects four complete clusters, and `join` reconstructs the preview without the exclamation mark. The code-point listing makes the result unambiguous: the preview still ends with both `U+0065` and `U+0301`. Nothing has converted those two characters into a single precomposed character.

This standalone example deliberately uses a positive limit smaller than the cluster count. In a reusable truncation routine, handle a zero limit separately and cap the selected range at the available number of clusters; otherwise, an oversized slice can introduce undefined elements. Splitting also materializes the entire cluster list, so consider that memory cost for large strings. Finally, `binmode` explicitly encodes standard output as UTF-8 so the retained accent is emitted correctly.

Example tested with Perl 5.36.

## More details

[Unicode grapheme boundaries in the Perl documentation](https://perldoc.perl.org/5.36.0/perlrebackslash).

[Read the perldelta behind this tip](https://perldoc.perl.org/5.36.0/perl5220delta).
