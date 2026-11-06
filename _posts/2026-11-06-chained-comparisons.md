---
title: "Check numeric ranges with readable chained comparisons"
feature: "chained-comparisons"
feature_name: "chained comparisons"
perl_version: "5.36"
description: "Learn about chained comparisons in Perl. Compatible comparisons of the same precedence can chain, as in 0 <= $value < 10. Do not mix precedence groups or tre..."
date: 2026-11-06
tags: ["chained-comparisons"]
layout: single
---

Range checks often repeat the same value on both sides of a logical conjunction. For numeric validation, that repetition can obscure the interval you actually intend. Perl lets compatible comparisons form a chain, so a lower-inclusive, upper-exclusive interval can read directly as `0 <= $value < 10`. This is useful when screening numeric measurements, offsets, or batch inputs against clear boundaries.

```perl
use v5.36;

my @values = (-1, 0, 4, 9, 10, 12);
my $accepted = 0;

for my $value (@values) {
    my $in_range = 0 <= $value < 10;
    my $status = $in_range ? 'accepted' : 'rejected';
    ++$accepted if $in_range;
    say "$value: $status";
}

say "Accepted: $accepted of " . scalar(@values);

```

Expected output:

```text
-1: rejected
0: accepted
4: accepted
9: accepted
10: rejected
12: rejected
Accepted: 3 of 6

```

The expression `0 <= $value < 10` is a chained comparison. It requires both neighboring comparisons to hold: the value must be at least zero and strictly less than ten. The result becomes the range-test flag in `$in_range`; the program uses that flag both to choose a status and to increment `$accepted`.

The supplied values exercise the important boundaries. Negative one fails the lower bound, zero passes because `<=` includes equality, and nine passes because it remains below ten. Ten and twelve fail the exclusive upper bound. Four supplies an ordinary interior value. The final count makes the batch result visible without hiding which individual inputs passed.

Chained comparisons were introduced in Perl 5.32 and have been stable since that release. This program targets Perl 5.36 with `use v5.36;`, which also enables strictness and warnings. No experimental feature is needed.

Keep the chain structurally simple: compatible comparisons must belong to the same precedence group. Here, `<=` and `<` meet that requirement. Do not generalize this notation to arbitrary operators or mix comparison precedence groups and assume the expression remains a single chain. When a validation rule combines unrelated conditions, write those conditions explicitly rather than forcing them into interval notation.

This example assumes numeric input. Chaining expresses the bounds check; it does not validate or convert arbitrary text into a suitable number.

Example tested with Perl 5.36.

## More details

[chained comparisons in the Perl documentation](https://perldoc.perl.org/5.36.0/perlop).

[Read the perldelta behind this tip](https://perldoc.perl.org/5.36.0/perl5320delta).
