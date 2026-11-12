---
title: "Report selected array values with their original indices"
feature: "index-value-array-slices"
feature_name: "index/value array slices"
perl_version: "5.36"
description: "Learn about index/value array slices in Perl. %array[LIST] returns alternating indices and values for selected array elements. The percent sigil does not tur..."
date: 2026-11-12
tags: ["index-value-array-slices"]
layout: single
---

When reporting selected entries from an array, values alone can lose useful context: which original slots did they come from? Keeping a separate position counter is awkward when the requested positions are out of order. An index/value array slice retrieves both pieces together. This example reports selected job statuses while preserving the requested order and leaving the source array intact.

```perl
use v5.36;

my @jobs = qw(queued running done failed waiting);
my @selected = (3, 1, 4);

my @pairs = %jobs[@selected];

say 'Selected job slots:';
while (@pairs) {
    my ($index, $status) = splice @pairs, 0, 2;
    say "slot $index: $status";
}

say 'All job statuses: ', join ', ', @jobs;

```

Expected output:

```text
Selected job slots:
slot 3: failed
slot 1: running
slot 4: waiting
All job statuses: queued, running, done, failed, waiting

```

The index/value array slice `%jobs[@selected]` produces a flat list containing each requested index followed by its corresponding value. Unlike the ordinary value slice `@jobs[@selected]`, it includes the positions themselves. This syntax was introduced in Perl 5.20 and has been stable since that release; the program targets Perl 5.36.

The selection list controls the result order. Here, `@selected` requests positions 3, 1, and 4, so `@pairs` receives six items: three alternating index/value pairs. Array indices are zero-based, making position 3 the fourth element. The slice does not sort the selection or scan every array element.

Each loop iteration uses `splice` to remove the next two items from `@pairs`. List assignment puts those items into `$index` and `$status`, and `say` prints a labeled report. Consuming the temporary list leaves `@jobs` unchanged, as the final line demonstrates.

Despite its leading percent sigil, `%jobs[@selected]` reads from the array `@jobs`; it does not turn that array into a hash or require a separate hash declaration. Keep the result as a list when selection order matters. It is not a list of two-element array references, so process its elements in pairs rather than treating each element as a complete record.

This example selects only existing positions. For application data, validate requested positions when missing elements would make the report misleading.

Example tested with Perl 5.36.

## More details

[index/value array slices in the Perl documentation](https://perldoc.perl.org/5.36.0/perldata).

[Read the perldelta behind this tip](https://perldoc.perl.org/5.36.0/perl5200delta).
