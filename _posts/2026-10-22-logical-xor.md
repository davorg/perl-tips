---
title: "Require exactly one logging backend to be enabled"
feature: "logical-xor"
feature_name: "high-precedence logical xor"
perl_version: "5.44"
description: "Learn about high-precedence logical xor in Perl. ^^ tests whether exactly one operand is true. It is logical, not bitwise ^, and unlike && and || must evalua..."
date: 2026-10-22
tags: ["logical-xor"]
layout: single
---

A logging configuration may require exactly one destination: a file or the system logger. Ordinary logical OR, `||`, accepts either destination but also accepts both, so it cannot enforce that requirement by itself.

Perl's high-precedence logical exclusive-or operator, `^^`, expresses this two-choice rule directly. It was introduced and became stable in Perl 5.40, and is available in the Perl 5.44 target used here. This program checks every combination and records the operand evaluations so you can see an important difference from short-circuit logic.

```perl
use v5.44;
use strict;
use warnings;

sub enabled {
    my ($name, $flag, $checks) = @_;
    push @$checks, $name;
    return $flag;
}

my @configurations = (
    ['neither',     0, 0],
    ['file only',   1, 0],
    ['syslog only', 0, 1],
    ['both',        1, 1],
);

for my $configuration (@configurations) {
    my ($label, $file, $syslog) = @$configuration;
    my @checks;

    my $valid = enabled('file', $file, \@checks)
             ^^ enabled('syslog', $syslog, \@checks);

    printf "%s: %s; checked %s\n",
        $label,
        ($valid ? 'accept' : 'reject'),
        join(',', @checks);
}

```

Expected output:

```text
neither: reject; checked file,syslog
file only: accept; checked file,syslog
syslog only: accept; checked file,syslog
both: reject; checked file,syslog

```

The configuration rows cover all four combinations of two Boolean flags. Each call to `enabled` records which backend was checked and returns its flag. The `^^` operator tests whether exactly one returned value is true. Consequently, the two single-backend configurations pass, while enabling neither backend or both backends fails.

Unlike `&&` and `||`, `^^` must evaluate both operands. The recorded checks make that behavior visible: every output line includes both backend names, even when the first flag is false. This matters when operands perform validation, collect diagnostics, or have other side effects. Do not treat `^^` as a guard that can prevent the second expression from running.

This is logical exclusive-or, not the bitwise `^` operator. It uses Perl truth values rather than comparing individual bits. The sample deliberately supplies numeric Boolean flags; normalize external configuration values before applying this rule if their textual representations do not match Perl's truth conventions.

The example uses the result only as a condition, selecting an acceptance message with `?:`. The helper demonstrates evaluation behavior; it does not open a log file or contact a logging service.

Example tested with Perl 5.44.

## More details

[high-precedence logical xor in the Perl documentation](https://perldoc.perl.org/5.44.0/perlop).

[Read the perldelta behind this tip](https://perldoc.perl.org/5.44.0/perl5400delta).
