---
title: "Remove hash entries while retaining keys and values"
feature: "delete-key-value-slices"
feature_name: "deleting key/value hash slices"
perl_version: "5.36"
description: "Learn about deleting key/value hash slices in Perl. delete %hash{LIST} removes selected entries and returns their keys and old values. Use an explicit key or..."
date: 2026-11-13
tags: ["delete-key-value-slices"]
layout: single
---

When removing temporary settings from a hash, you may also need a report of exactly what was removed. Collecting values separately can duplicate lookup logic and make it easier to lose the association between each key and its former value. Deleting a key/value hash slice handles both tasks together. This capability was introduced in Perl 5.28 and was stable from that release; the program below targets Perl 5.36.

```perl
use v5.36;

my %settings = (
    debug   => 1,
    trace   => 0,
    retries => 3,
    timeout => 30,
);

my @remove = qw(trace debug);
my @removed = delete %settings{@remove};

say 'Removed settings:';
while (@removed) {
    my ($key, $value) = splice @removed, 0, 2;
    say "$key=$value";
}

say 'Remaining settings:';
for my $key (sort keys %settings) {
    say "$key=$settings{$key}";
}

```

Expected output:

```text
Removed settings:
trace=0
debug=1
Remaining settings:
retries=3
timeout=30

```

The key/value hash slice `%settings{@remove}` identifies entries using the explicit order in `@remove`. Applying `delete` removes those entries and, in list context, returns an alternating sequence of keys and their old values. Assigning that result to `@removed` captures the information before the deleted settings disappear from `%settings`.

Here, the returned list contains `trace`, `0`, `debug`, and `1`, in that order. The `while` loop consumes two elements at a time with `splice`, giving each output line a key and its corresponding former value. The zero value is retained normally: deletion does not depend on whether a stored value is true.

The final loop uses `sort keys %settings` to inspect what remains. Sorting is important for reproducible output because hash traversal order should not be used as a presentation order. The removal report instead follows the explicitly supplied key order.

Use the `%settings{...}` form when you need both keys and values. By contrast, deleting an ordinary value slice with `delete @settings{@remove}` returns only the old values. This example selects existing keys; if your application must distinguish an absent key from a stored undefined value, check membership with `exists` before deleting. The operation mutates the original hash, so capture its return value when you need an audit record.

Example tested with Perl 5.36.

## More details

[deleting key/value hash slices in the Perl documentation](https://perldoc.perl.org/5.36.0/perlfunc).

[Read the perldelta behind this tip](https://perldoc.perl.org/5.36.0/perl5280delta).
