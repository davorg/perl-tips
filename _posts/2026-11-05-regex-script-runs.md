---
title: "Reject mixed-script names while accepting Latin and Cyrillic"
feature: "regex-script-runs"
feature_name: "regular expression script runs"
perl_version: "5.36"
description: "Learn about regular expression script runs in Perl. (*script_run:...) constrains a match to a compatible Unicode script run. Demonstrate fixed Latin and Cyri..."
date: 2026-11-05
tags: ["regex-script-runs"]
layout: single
---

A name validator that accepts Unicode letters can accidentally admit strings mixing Latin and Cyrillic lookalikes. Rejecting all non-ASCII text avoids that mixture but also excludes legitimate Cyrillic names. Perl's `(*script_run:...)` regular-expression construct lets you constrain a match to a compatible Unicode script run while retaining multilingual input. Introduced in Perl 5.28, it became stable in Perl 5.32 and is available without experimental features in the Perl 5.36 target used here.

```perl
use v5.36;
use utf8;

binmode STDOUT, ':encoding(UTF-8)';

my @candidates = (
    ['Latin',    'London'],
    ['Cyrillic', 'Москва'],
    ['Mixed',    'Lоndon'],
    ['Digits',   '123'],
);

my $name_pattern = qr/\A(*script_run:\p{L}+)\z/;

for my $candidate (@candidates) {
    my ($label, $name) = @$candidate;
    my $result = $name =~ $name_pattern ? 'accepted' : 'rejected';
    say "$label: $name => $result";
}

```

Expected output:

```text
Latin: London => accepted
Cyrillic: Москва => accepted
Mixed: Lоndon => rejected
Digits: 123 => rejected

```

The pattern combines two independent requirements. Inside `(*script_run:...)`, `\p{L}+` requires one or more Unicode letters. The script-run constraint additionally requires those matched characters to form a compatible Unicode script run. The anchors `\A` and `\z` require the entire string to satisfy the pattern, rather than allowing a valid substring to hide invalid surrounding characters.

The fixed inputs make the distinction visible. London contains Latin letters, and Москва contains Cyrillic letters; both pass. The mixed spelling Lоndon contains a Cyrillic small letter o after the Latin capital L, so it fails despite looking similar to the accepted Latin spelling. The digits fail for a separate reason: `\p{L}` permits letters, not numbers. Thus the script-run constraint supplements the character policy rather than replacing it.

The program uses `use utf8;` to interpret its non-ASCII source literals correctly and configures `STDOUT` with a UTF-8 encoding layer. The ordered array keeps the report deterministic. `use v5.36;` enables strictness and warnings, and the example requires no experimental feature switch.

This deliberately narrow validator excludes spaces, punctuation, and combining marks because its character rule accepts only letters. Adapt that rule to your application's requirements before adopting it. Script compatibility is not a complete spoofing defence: acceptance does not establish identity, uniqueness, or visual distinctness. Treat this as one validation layer, not proof that a name is trustworthy.

Example tested with Perl 5.36.

## More details

[regular expression script runs in the Perl documentation](https://perldoc.perl.org/5.36.0/perlre).

[Read the perldelta behind this tip](https://perldoc.perl.org/5.36.0/perl5320delta).
