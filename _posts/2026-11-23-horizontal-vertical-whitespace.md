---
title: "Normalize horizontal spacing without losing line breaks"
feature: "horizontal-vertical-whitespace"
feature_name: "horizontal and vertical whitespace classes"
perl_version: "5.36"
description: "Learn about horizontal and vertical whitespace classes in Perl. \\h and \\v distinguish horizontal and vertical whitespace; \\H and \\V are complements. Use fixe..."
date: 2026-11-23
tags: ["horizontal-vertical-whitespace"]
layout: single
---

Pasted reports often mix tabs and repeated spaces while relying on line breaks to separate records. Replacing every run of `\s` with a space can flatten the report because that class includes vertical whitespace. Use `\h` to normalize horizontal gaps without consuming line breaks, and `\v` when you need to recognize vertical whitespace separately. These classes were introduced and stable in Perl 5.10; this program targets Perl 5.36.

```perl
use v5.36;

my $text = "\tName\t  Qty\n\n  bolts\t  0\n\tnuts  \t12\n";
my $vertical_before = () = $text =~ /\v/g;

my $normalized = $text;
$normalized =~ s/\h+/ /g;
$normalized =~ s/^ //mg;
$normalized =~ s/ $//mg;

my $vertical_after = () = $normalized =~ /\v/g;

print "Normalized:\n", $normalized;
say "Vertical whitespace: $vertical_before -> $vertical_after";

```

Expected output:

```text
Normalized:
Name Qty

bolts 0
nuts 12
Vertical whitespace: 4 -> 4

```

The program keeps its input in a fixed string containing tabs, repeated spaces, a blank line, and a final newline. Keeping the original in `$text` makes it possible to compare the vertical whitespace before and after processing.

The substitution `s/\h+/ /g` replaces each run of horizontal whitespace with one ordinary space. The `+` quantifier consumes the whole run, and the `g` modifier processes every run rather than stopping at the first. Because `\h` does not match line breaks, this step leaves the blank line and all newline characters intact.

Collapsing gaps also turns indentation and trailing horizontal whitespace into single spaces. The next two substitutions remove those spaces at line boundaries. Their `m` modifier lets `^` and `$` identify individual line boundaries within the string. These cleanup steps deliberately discard indentation, so omit them when leading spacing carries meaning.

The expressions using `/\v/g` count vertical whitespace characters before and after normalization. Assigning the matches to `()` puts matching in list context; assigning that result to a scalar records the number of matches. Both counts are four. This counts characters, not logical lines: a carriage-return/newline pair contains two vertical whitespace characters.

The complementary classes are `\H`, which matches a character that is not horizontal whitespace, and `\V`, which matches one that is not vertical whitespace. In particular, `\H` can match a newline; it does not mean a non-whitespace character.

Example tested with Perl 5.36.

## More details

[horizontal and vertical whitespace classes in the Perl documentation](https://perldoc.perl.org/5.36.0/perlrebackslash).

[Read the perldelta behind this tip](https://perldoc.perl.org/5.36.0/perl5100delta).
