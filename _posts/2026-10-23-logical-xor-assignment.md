---
title: "Toggle a setting only when requests are true"
feature: "logical-xor-assignment"
feature_name: "logical xor assignment"
perl_version: "5.44"
description: "Learn about logical xor assignment in Perl. ^^= assigns the logical exclusive-or result back to its left operand. Distinguish truth-value toggling from numer..."
date: 2026-10-23
tags: ["logical-xor-assignment"]
layout: single
---

A stream of requests may mean either “toggle this setting” or “leave it alone.” Writing a conditional for every request adds noise when all you need is a change in logical state. Perl's logical exclusive-or assignment operator, `^^=`, expresses that update directly. It is useful when incoming values follow Perl's ordinary truth rules rather than being restricted to numeric flags.

```perl
use v5.44;
use warnings;

my $enabled = 7;
my @requests = (
    ['Keep current setting', 0],
    ['Toggle setting',       1],
    ['Ignore empty request', ''],
    ['Toggle with text',     'yes'],
    ['Keep setting again',   0],
);

printf "Initial: %s\n", $enabled ? 'enabled' : 'disabled';

for my $request (@requests) {
    my ($label, $toggle) = @$request;
    $enabled ^^= $toggle;
    printf "%s: %s\n", $label, $enabled ? 'enabled' : 'disabled';
}

```

Expected output:

```text
Initial: enabled
Keep current setting: enabled
Toggle setting: disabled
Ignore empty request: disabled
Toggle with text: enabled
Keep setting again: enabled

```

The logical exclusive-or assignment operator, `^^=`, was introduced in Perl 5.42 and has been stable since that release. This program targets Perl 5.44 with `use v5.44;`, which enables strictness; `use warnings;` explicitly enables warnings.

Each request contains a description and a toggle value. Inside the loop, `$enabled ^^= $toggle` computes the logical exclusive-or of the current setting and the request, then assigns that result back to `$enabled`. Exclusive-or is true when exactly one operand is true. Consequently, a true request reverses the setting's truth value, while a false request preserves its truth value.

The input deliberately includes more than numeric flags. Both `1` and the nonempty string `'yes'` trigger a toggle. Both `0` and the empty string `''` leave the logical state unchanged. The initial value `7` is also true, so the first false request leaves the setting logically enabled. The conditional operator `?:` converts each resulting state into a readable label without depending on its underlying representation.

Use this operator for logical state, not for preserving the original scalar value. A false request preserves truth, not necessarily the original number or string: assignment stores the logical result. Also distinguish `^^=` from numeric bitwise `^=`, which operates on individual bits rather than treating each operand as one truth value. If the setting contains a bitmask or meaningful nonboolean data, logical exclusive-or assignment is not a substitute for manipulating that data.

Example tested with Perl 5.44.

## More details

[logical xor assignment in the Perl documentation](https://perldoc.perl.org/5.44.0/perlop).

[Read the perldelta behind this tip](https://perldoc.perl.org/5.44.0/perl5420delta).
