---
title: "Make regex repetition limits easier to read"
feature: "readable-regex-braces"
feature_name: "whitespace inside braced regex constructs"
perl_version: "5.36"
description: "Learn about whitespace inside braced regex constructs in Perl. Blanks beside braces and around a quantifier comma are permitted, as in a{ 2, 4 }, even withou..."
date: 2026-11-08
tags: ["readable-regex-braces"]
layout: single
---

Compact validation patterns can become hard to review when character classes, repetition limits, and separators run together. For a product code consisting of two to four uppercase ASCII letters, a hyphen, and three digits, the repetition counts deserve to stand out. Perl lets you add blanks inside braced quantifiers, making those bounds easier to scan without enabling `/x` or changing the accepted input. The program below checks both valid codes and deliberately malformed candidates.

```perl
use v5.36;

my @codes = (
    'AB-123',
    'ABCD-007',
    'A-123',
    'ABCDE-123',
    'AB-12',
    'AB-1234',
    'AB -123',
);

my $code_pattern = qr/\A[A-Z]{ 2, 4 }-[0-9]{ 3 }\z/;

for my $code (@codes) {
    my $result = $code =~ $code_pattern ? 'valid' : 'invalid';
    say "$code: $result";
}

```

Expected output:

```text
AB-123: valid
ABCD-007: valid
A-123: invalid
ABCDE-123: invalid
AB-12: invalid
AB-1234: invalid
AB -123: invalid

```

The program builds a reusable pattern with `qr//` and checks each candidate using `=~`. The character class `[A-Z]` accepts an uppercase ASCII letter, and `{ 2, 4 }` requires between two and four occurrences. After a literal hyphen, `[0-9]{ 3 }` requires exactly three ASCII digits. The anchors `\A` and `\z` require the entire string to match, so an otherwise valid fragment cannot hide inside a longer value.

Whitespace inside these braced quantifiers became available in Perl 5.34 and was stable in that release. It is available without experimental syntax in the targeted Perl 5.36. This example deliberately does not use `/x`: the blanks beside the braces and around the quantifier comma are permitted independently of extended regex mode.

The first two candidates demonstrate the accepted letter-count boundaries, and the remaining candidates expose common validation mistakes. Short and long components fail. The candidate containing a space before the hyphen also fails: formatting spaces inside a quantifier do not make spaces in the input optional.

Use this spacing to separate repetition limits visually when reviewing a dense pattern. Keep each numeric bound intact; do not split a multi-digit number with spaces. This permission is specific to the supported brace syntax, not a general instruction to scatter whitespace throughout a regex. Outside that syntax, whitespace can still affect what the pattern matches.

Example tested with Perl 5.36.

## More details

[whitespace inside braced regex constructs in the Perl documentation](https://perldoc.perl.org/5.36.0/perlre).

[Read the perldelta behind this tip](https://perldoc.perl.org/5.36.0/perl5340delta).
