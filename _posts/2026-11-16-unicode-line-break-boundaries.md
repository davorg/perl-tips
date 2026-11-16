---
title: "Find possible wrap positions without matching newline characters"
feature: "unicode-line-break-boundaries"
feature_name: "Unicode line-break opportunities"
perl_version: "5.36"
description: "Learn about Unicode line-break opportunities in Perl. \\b{lb} matches Unicode line-break opportunities, not existing newline characters. Contrast it with matc..."
date: 2026-11-16
tags: ["unicode-line-break-boundaries"]
layout: single
---

A text formatter needs places where it may wrap a line, not merely locations where the input already contains newline characters. Searching for `\n` answers only the latter question. Perl's `\b{lb}` assertion exposes Unicode line-break opportunities directly. This program compares both searches on the same fixed text, making the distinction visible through character offsets.

```perl
use v5.36;

my $text = "red blue\nnext";

my @opportunities;
while ($text =~ /\b{lb}/g) {
    push @opportunities, pos($text);
}

my @newlines;
while ($text =~ /\n/g) {
    push @newlines, $-[0];
}

say 'Text: red blue\\nnext';
say 'Line-break opportunity offsets: ', join(', ', @opportunities);
say 'Newline character offsets: ', join(', ', @newlines);

```

Expected output:

```text
Text: red blue\nnext
Line-break opportunity offsets: 4, 9, 13
Newline character offsets: 8

```

The first loop searches with `\b{lb}`, Perl's Unicode line-break boundary assertion, introduced and stable in Perl 5.24. It is available without experimental features in the target Perl 5.36. The program starts with `use v5.36;`, which also enables strictness and warnings.

Unlike a character-matching pattern, `\b{lb}` consumes no text. Each successful match identifies a position where Unicode line-breaking rules permit a break. With `/g`, successive matches visit those positions; `pos($text)` records each offset. Perl advances appropriately after zero-length matches, so this loop does not get stuck at one boundary.

Offsets are zero-based positions between characters. In this fixed input, offset 4 is after the space following the first word. Offset 9 is immediately after the newline, and offset 13 is the end of the string. The final boundary is useful evidence that these matches are positions, not newline characters. The displayed input escapes its newline for readability; the stored string contains an actual newline.

The second loop deliberately asks a different question. Its `\n` pattern consumes an actual newline character, and `$-[0]` reports that match's starting offset: 8. Thus the newline character and the boundary following it have different offsets.

Use these boundaries as candidate split positions, not as a complete text-wrapping system. The assertion neither inserts newlines nor chooses breaks to fit a display width. Your application must still measure segments and select appropriate candidates. Likewise, the comparison here searches specifically for `\n`; it is not a general recognizer for every possible line-ending convention.

Example tested with Perl 5.36.

## More details

[Unicode line-break opportunities in the Perl documentation](https://perldoc.perl.org/5.36.0/perlrebackslash).

[Read the perldelta behind this tip](https://perldoc.perl.org/5.36.0/perl5240delta).
