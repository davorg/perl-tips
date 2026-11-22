---
title: "Split mixed line endings without leftover carriage returns"
feature: "generic-linebreaks"
feature_name: "generic linebreak matching"
perl_version: "5.36"
description: "Learn about generic linebreak matching in Perl. \\R matches Unicode linebreaks and treats CRLF as one sequence. Demonstrate splitting fixed mixed line endings..."
date: 2026-11-22
tags: ["generic-linebreaks"]
layout: single
---

Text copied between systems can contain more than one line-ending convention. Splitting only on `\n` can leave carriage returns attached to content and miss Unicode line separators entirely. For text already held in a Perl string, `split /\R/` provides a single delimiter for mixed linebreaks without first rewriting the input.

```perl
use v5.36;

my $text = "alpha\r\nbeta\ngamma\rdelta\x{2028}epsilon\x{85}zeta\n\n";

my @lines = split /\R/, $text;
say 'Content lines: ', scalar @lines;
for my $index (0 .. $#lines) {
    say $index + 1, ': ', $lines[$index];
}

my @all_fields = split /\R/, $text, -1;
say 'Fields with trailing empties: ', scalar @all_fields;
say 'Trailing empty fields: ', scalar(@all_fields) - scalar(@lines);

```

Expected output:

```text
Content lines: 6
1: alpha
2: beta
3: gamma
4: delta
5: epsilon
6: zeta
Fields with trailing empties: 8
Trailing empty fields: 2

```

The regex escape `\R`, introduced and stable in Perl 5.10, matches Unicode linebreaks. It also recognizes the two-character CRLF sequence as one linebreak. This makes it useful as the delimiter in `split /\R/`: the Windows-style ending after alpha produces one boundary, not an extra empty field between carriage return and line feed.

The fixed input in `$text` combines CRLF, LF, CR, a Unicode line separator written as `\x{2028}`, and a next-line character written as `\x{85}`. Escaped characters keep the source ASCII-only. The program prints only ASCII labels and content, so no output encoding setup is needed for this demonstration.

The first `split` uses its default trailing-empty-field behavior. Although the input ends with two LF characters, trailing empty fields are discarded, leaving six content lines. Empty fields between content lines would still be retained; the default does not remove every blank line.

The second `split` supplies a negative limit, `-1`, which preserves trailing empty fields. Its eight fields consist of the six content lines and two empty strings after the final two delimiters. Choose this form when trailing blank records matter to your processing.

Use `\R` as a standalone regex atom, not inside a character class. It describes a linebreak sequence rather than merely a choice of individual characters. Splitting removes the matched separators, so this approach does not preserve which line-ending convention each original line used.

Example tested with Perl 5.36.

## More details

[generic linebreak matching in the Perl documentation](https://perldoc.perl.org/5.36.0/perlrebackslash).

[Read the perldelta behind this tip](https://perldoc.perl.org/5.36.0/perl5100delta).
