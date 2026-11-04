---
title: "Extract reference numbers after prefixes with variable spacing"
feature: "variable-length-lookbehind"
feature_name: "noncapturing variable-length lookbehind"
perl_version: "5.36"
description: "Learn about noncapturing variable-length lookbehind in Perl. Variable-length lookbehind without capturing parentheses is stable in 5.36. Use bounded lengths ..."
date: 2026-11-04
tags: ["variable-length-lookbehind"]
layout: single
---

Extracting reference numbers from compact logs can become awkward when a required prefix allows inconsistent spacing. You may want only the digits, without stripping prefixes afterward or introducing captures solely to discard surrounding text. A bounded variable-length lookbehind lets the regular expression check that context while leaving it outside the match. This Perl 5.36 example accepts one to three spaces after a reference prefix.

```perl
use v5.36;

my $text = 'ref: 104; ref:   208; ref:    999; alt: 310; ref:  412';

my @references = $text =~ /(?<=\bref:[ ]{1,3})[0-9]+\b/g;

say "Reference: $_" for @references;
say 'Total: ', scalar @references;

```

Expected output:

```text
Reference: 104
Reference: 208
Reference: 412
Total: 3

```

The positive lookbehind `(?<=...)` checks the text immediately before the current matching position without consuming it. Here, `\bref:[ ]{1,3}` requires the literal prefix `ref:` followed by one, two, or three ASCII spaces. Because that spacing has several permitted lengths, the assertion is a variable-length lookbehind.

The consuming portion, `[0-9]+\b`, selects the reference number. Applying `/g` in list context collects successive matches into `@references`. There are no capturing parentheses, so each array element contains the complete match: just the digits, not the prefix or its spacing. The first loop prints those matches in input order, and `scalar @references` supplies the count.

The sample deliberately includes two rejected entries. The entry containing `999` has four spaces after its prefix, exceeding the explicit bound. The entry containing `310` uses a different prefix. Neither contributes a result, while all three permitted spacing lengths are demonstrated by the accepted entries.

Variable-length lookbehind was introduced in Perl 5.30; its form without capturing parentheses is stable in Perl 5.36. Captures inside variable-length lookbehind remain experimental and are intentionally absent here. Keep the permitted lengths bounded rather than replacing `{1,3}` with an unbounded quantifier.

This is a targeted extractor, not a complete record validator. Its spacing rule accepts ASCII spaces only, and the final `\b` requires a word boundary after the digits. Adjust the surrounding data contract deliberately rather than assuming this pattern validates arbitrary input.

Example tested with Perl 5.36.

## More details

[noncapturing variable-length lookbehind in the Perl documentation](https://perldoc.perl.org/5.36.0/perlre).

[Read the perldelta behind this tip](https://perldoc.perl.org/5.36.0/perl5360delta).
