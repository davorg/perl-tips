---
title: "Find integer boundaries correctly for signed measurements"
feature: "builtin-rounding"
feature_name: "builtin ceil and floor"
perl_version: "5.44"
description: "Learn about builtin ceil and floor in Perl. ceil rounds toward positive infinity and floor toward negative infinity. Use finite, exactly representable exampl..."
date: 2026-11-01
tags: ["builtin-rounding"]
layout: single
---

When measurements can fall on either side of zero, converting them to enclosing integer boundaries requires directional rounding. Simply discarding a fractional part gives the wrong lower boundary for negative values. Perl's `builtin::floor` and `builtin::ceil` make the intended direction explicit, which is useful when finding integer bounds around signed coordinates. This example prints both boundaries for fractional and integral measurements.

```perl
use v5.44;
use strict;
use warnings;

my @measurements = (-2.75, -2, -0.25, 0, 0.25, 2, 2.75);

say 'value -> [lower, upper]';
for my $value (@measurements) {
    my $lower = builtin::floor($value);
    my $upper = builtin::ceil($value);
    printf "%s -> [%s, %s]\n", $value, $lower, $upper;
}

```

Expected output:

```text
value -> [lower, upper]
-2.75 -> [-3, -2]
-2 -> [-2, -2]
-0.25 -> [-1, 0]
0 -> [0, 0]
0.25 -> [0, 1]
2 -> [2, 2]
2.75 -> [2, 3]

```

The program calls `builtin::floor` and `builtin::ceil` by their fully qualified names, without an explicit import. This avoids redeclaring the names supplied by the Perl 5.44 version bundle. Both functions were introduced in Perl 5.36 and became stable in Perl 5.40. This program targets Perl 5.44, keeps `strict` and `warnings` enabled, and uses no experimental features.

For each measurement, `builtin::floor($value)` finds the greatest integer less than or equal to the input. Conversely, `builtin::ceil($value)` finds the least integer greater than or equal to it. The resulting pair encloses the measurement between integer boundaries. `printf` prints those boundaries in input order, making the output deterministic.

The negative values are the important check. For negative 2.75, the lower boundary is negative 3, while the upper boundary is negative 2. Rounding downward therefore does not mean removing the fractional part. Likewise, rounding upward means moving toward positive infinity, not increasing the absolute magnitude. Existing integer values remain unchanged, so their two boundaries coincide.

All inputs here are finite and exactly representable in binary, avoiding ambiguity from decimal approximation. In real calculations, inspect the value being rounded: a result slightly above an integer still has a higher ceiling, even if its displayed decimal form looks integral. Neither function implements a tolerance policy or rounding to the nearest integer.

Example tested with Perl 5.44.

## More details

[builtin ceil and floor in the Perl documentation](https://perldoc.perl.org/5.44.0/builtin).

[Read the perldelta behind this tip](https://perldoc.perl.org/5.44.0/perl5400delta).
