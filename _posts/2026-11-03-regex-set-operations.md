---
title: "Filter characters with intersection, subtraction, and union"
feature: "regex-set-operations"
feature_name: "regular expression set operations"
perl_version: "5.36"
description: "Learn about regular expression set operations in Perl. Extended bracketed classes (?[ ... ]) combine character sets with intersection, subtraction and union...."
date: 2026-11-03
tags: ["regex-set-operations"]
layout: single
---

When cleaning identifiers or defining token rules, you may need characters shared by two sets, characters remaining after exclusions, or characters from either set. Extended bracketed classes, written as `(?[ ... ])`, express those rules directly inside a regular expression. They were introduced in Perl 5.18 and became stable in Perl 5.36. This example compares three literal character-set rules against one mixed input string.

```perl
use v5.36;

my $sample = 'abczXYZ019_-';

my $early_letters = qr/(?[ [a-z] & [a-f] ])/;
my $consonants    = qr/(?[ [a-z] - [aeiou] ])/;
my $token_chars   = qr/(?[ [a-z] + [0-9] ])/;

my @checks = (
    ['Intersection', $early_letters],
    ['Subtraction',  $consonants],
    ['Union',        $token_chars],
);

for my $check (@checks) {
    my ($label, $pattern) = @$check;
    my $selected = join '', ($sample =~ /$pattern/g);
    say "$label: $selected";
}

```

Expected output:

```text
Intersection: abc
Subtraction: bcz
Union: abcz019

```

Each extended bracketed class describes a set of characters, and each match consumes one character from that set. The program builds three patterns with `qr//`, then applies each pattern to the same sample so the differences are visible.

Intersection uses `&`: only characters belonging to both operands survive. Here, intersecting `[a-z]` with `[a-f]` selects the sample's first three letters. Subtraction uses `-`: characters in the right operand are removed from the left operand. Removing `[aeiou]` from `[a-z]` therefore retains the lowercase consonants. Union uses `+`: a character may belong to either operand, so the final pattern accepts lowercase letters and decimal digits.

The outer `(?[ ... ])` syntax is important: these are regex set expressions, not ordinary bracketed classes with punctuation added. Keeping each operand's brackets visible makes the intended sets easier to review. Whitespace between operands and operators makes the expressions readable without becoming part of the selected character set.

The loop uses `/g` in list context to collect all matching characters. `join` combines those matches in their original order, including any duplicates. It does not sort or deduplicate them.

These patterns deliberately use literal ASCII ranges. They do not describe every Unicode letter or digit, and uppercase letters are excluded. Also, extracting acceptable characters is not validation: this program silently skips punctuation and uppercase input. If rejected characters matter, validate the entire value rather than treating the filtered result as proof that the original input was acceptable.

Example tested with Perl 5.36.

## More details

[regular expression set operations in the Perl documentation](https://perldoc.perl.org/5.36.0/perlrecharclass).

[Read the perldelta behind this tip](https://perldoc.perl.org/5.36.0/perl5360delta).
