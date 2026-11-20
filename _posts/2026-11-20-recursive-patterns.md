---
title: "Validate small nested parenthesized values with one pattern"
feature: "recursive-patterns"
feature_name: "recursive regular expression subpatterns"
perl_version: "5.36"
description: "Learn about recursive regular expression subpatterns in Perl. (?1) reuses capture group 1 as a subpattern and supports recursion for small balanced structure..."
date: 2026-11-20
tags: ["recursive-patterns"]
layout: single
---

A flat character check cannot validate nested parentheses: each opening delimiter needs a corresponding closing delimiter in the right position. For small, bounded values such as parenthesized configuration fragments, recursive regular expression subpatterns let one rule describe both the outer structure and its nested contents. This Perl 5.36 program validates exactly one outer parenthesized unit.

```perl
use v5.36;

my $balanced = qr{
    \A
    (                           # Capture group 1: one balanced unit
        \(
        (?:
            [^()\r\n]++         # Ordinary text, without parentheses
            |
            (?1)                # Another balanced unit
        )*
        \)
    )
    \z
}x;

my @inputs = (
    '()',
    '(alpha(beta)gamma)',
    '((x)(y))',
    '(alpha(beta)',
    '(x)tail',
    '(a)(b)',
);

for my $text (@inputs) {
    my $valid = length($text) <= 80 && $text =~ $balanced;
    say "$text => ", ($valid ? 'valid' : 'invalid');
}

```

Expected output:

```text
() => valid
(alpha(beta)gamma) => valid
((x)(y)) => valid
(alpha(beta) => invalid
(x)tail => invalid
(a)(b) => invalid

```

The pattern stored in `$balanced` defines one parenthesized unit as capture group 1. Inside that unit, the repeated alternatives accept either ordinary text or another complete unit. The recursive subpattern call `(?1)` invokes the pattern belonging to capture group 1, allowing the same rule to handle nested parentheses. This syntax was introduced in Perl 5.10 and has been stable since that release.

The character class `[^()\r\n]` excludes parentheses and line breaks. Its possessive quantifier `++` consumes a run of ordinary text without giving characters back during backtracking. Because ordinary text cannot contain parentheses, this does not prevent the recursive alternative from recognizing a nested unit. The surrounding `*` permits empty contents as well as mixtures of text and nested units.

The anchors `\A` and `\z` require the entire string to match. Consequently, trailing text and two adjacent outer units are rejected rather than accepted as partial matches. The `length` check limits candidates to 80 characters before matching; all supplied inputs are fixed and small.

This is a validator for a deliberately narrow format, not a general parser. It provides no quoting or escaping rules, and it does not construct a nested data structure. Keep recursive matching bounded; for larger grammars or structured output, use a parser instead.

Example tested with Perl 5.36.

## More details

[recursive regular expression subpatterns in the Perl documentation](https://perldoc.perl.org/5.36.0/perlre).

[Read the perldelta behind this tip](https://perldoc.perl.org/5.36.0/perl5100delta).
