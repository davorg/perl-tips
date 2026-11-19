---
title: "Prevent regex quantifiers from giving characters back"
feature: "possessive-quantifiers"
feature_name: "possessive regex quantifiers"
perl_version: "5.36"
description: "Learn about possessive regex quantifiers in Perl. Quantifiers such as ++ and *+ never give matched characters back. Contrast success and failure with greedy ..."
date: 2026-11-19
tags: ["possessive-quantifiers"]
layout: single
---

A greedy regex quantifier can consume text and then return characters when a later part of the pattern fails. Sometimes you want that flexibility; sometimes you want the consumed text to stay committed. Perl's possessive quantifiers, including `++` and `*+`, express that commitment directly.

```perl
use v5.36;

my @checks = (
    ['greedy shared suffix',     'aaaa',  qr/\Aa+a\z/],
    ['possessive shared suffix', 'aaaa',  qr/\Aa++a\z/],
    ['greedy delimiter',         'aaaa!', qr/\Aa+!\z/],
    ['possessive delimiter',     'aaaa!', qr/\Aa++!\z/],
);

for my $check (@checks) {
    my ($label, $input, $pattern) = @$check;
    my $result = $input =~ $pattern ? 'match' : 'no match';
    say "$label: $result";
}

```

Expected output:

```text
greedy shared suffix: match
possessive shared suffix: no match
greedy delimiter: match
possessive delimiter: match

```

The program tests two suffix arrangements with both greedy and possessive quantifiers. Each entry contains a descriptive label, an input string, and a compiled pattern created with `qr//`. The anchors `\A` and `\z` require a match against the entire string, so a successful substring cannot hide a failed validation.

In the first pattern, `a+` initially consumes all four letters. The final literal `a` still needs a character, so the greedy quantifier gives one back. That lets the whole pattern succeed. Replacing `a+` with `a++` changes the result: all four letters remain consumed, leaving nothing for the required suffix. Possessive matching therefore changes which strings this pattern accepts; it is not merely a performance annotation.

The delimiter cases show a situation where both forms succeed. Neither `a+` nor `a++` can consume the exclamation mark, so the following literal `!` matches without requiring either quantifier to retreat. This is the key design question when considering a possessive quantifier: could a later part of the pattern need characters that this quantified piece can consume?

The same commitment rule applies to `*+`, which permits zero or more repetitions, whereas `++` requires one or more. Both are stable features introduced in Perl 5.10 and available in the targeted Perl 5.36. They can eliminate backtracking choices, but they are not always faster and are not generally equivalent to their greedy counterparts. Use them when refusing to return consumed characters is part of the intended matching behavior, and test both accepted and rejected inputs.

Example tested with Perl 5.36.

## More details

[possessive regex quantifiers in the Perl documentation](https://perldoc.perl.org/5.36.0/perlre).

[Read the perldelta behind this tip](https://perldoc.perl.org/5.36.0/perl5100delta).
