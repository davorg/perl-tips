---
title: "Restrict regex character classes to ASCII input"
feature: "ascii-regex-classes"
feature_name: "ASCII-restricted regular expressions"
perl_version: "5.36"
description: "Learn about ASCII-restricted regular expressions in Perl. /a restricts \\d, \\s, \\w and POSIX classes to ASCII. /aa additionally prevents ASCII/non-ASCII casel..."
date: 2026-11-25
tags: ["ascii-regex-classes"]
layout: single
---

A machine-readable field may require ASCII digits, whitespace, or word characters even when the surrounding application handles Unicode. Broad regular-expression classes can otherwise accept characters outside that contract. The `/a` modifier, introduced and stable in Perl 5.14, restricts `\d`, `\s`, `\w`, and POSIX character classes to ASCII. This Perl 5.36 example compares those restrictions with Unicode matching, then shows why case-insensitive validation may need `/aa` instead.

```perl
use v5.36;

my @checks = (
    ['ASCII digits', '2048', qr/\A\d+\z/u, qr/\A\d+\z/a],
    ['Arabic-Indic digits', chr(0x0664) . chr(0x0662),
        qr/\A\d+\z/u, qr/\A\d+\z/a],
    ['Accented identifier', 'caf' . chr(0x00E9),
        qr/\A\w+\z/u, qr/\A\w+\z/a],
    ['Nonbreaking space', chr(0x00A0),
        qr/\A\s+\z/u, qr/\A\s+\z/a],
);

for my $check (@checks) {
    my ($label, $text, $unicode_pattern, $ascii_pattern) = @$check;
    my $unicode = $text =~ $unicode_pattern ? 'yes' : 'no';
    my $ascii = $text =~ $ascii_pattern ? 'yes' : 'no';
    say "$label: Unicode=$unicode, ASCII=$ascii";
}

my $kelvin = chr(0x212A);
my $single = $kelvin =~ /\Ak\z/ia ? 'yes' : 'no';
my $double = $kelvin =~ /\Ak\z/iaa ? 'yes' : 'no';
say "Kelvin sign matches k: /a=$single, /aa=$double";

```

Expected output:

```text
ASCII digits: Unicode=yes, ASCII=yes
Arabic-Indic digits: Unicode=yes, ASCII=no
Accented identifier: Unicode=yes, ASCII=no
Nonbreaking space: Unicode=yes, ASCII=no
Kelvin sign matches k: /a=yes, /aa=no

```

Each table entry contains a label, input text, and two compiled patterns created with `qr//`: one using `/u` for Unicode rules and one using `/a`. The loop applies both patterns to the same input. The anchors `\A` and `\z` require the entire string to satisfy the selected class, rather than accepting a matching substring.

Ordinary ASCII digits pass both checks. Arabic-Indic digits, an accented word, and a nonbreaking space pass their corresponding Unicode checks but fail the ASCII-restricted checks. The program constructs non-ASCII characters with `chr` and prints only ASCII labels and results, so it needs no output encoding setup.

The final check demonstrates an important limitation: `/a` alone does not prevent case-insensitive matches between ASCII and non-ASCII characters. Under `/ia`, the Kelvin sign matches the literal ASCII letter k. Using `/iaa` blocks that cross-boundary match. Choose `/aa` when case-insensitive protocol keywords must not accept such equivalents.

Neither modifier is a general ASCII-only filter: a pattern can still explicitly match non-ASCII characters. Also, ASCII `\w` includes digits and underscore, so it is not by itself a complete identifier policy. Add whatever structural restrictions your application requires.

Example tested with Perl 5.36.

## More details

[ASCII-restricted regular expressions in the Perl documentation](https://perldoc.perl.org/5.36.0/perlre).

[Read the perldelta behind this tip](https://perldoc.perl.org/5.36.0/perl5140delta).
