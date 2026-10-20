---
title: "Process alternating names and values without manual indexing"
feature: "multi-variable-for"
feature_name: "multi-variable foreach loops"
perl_version: "5.44"
description: "Learn about multi-variable foreach loops in Perl. A for my ($key, $value) (...) loop consumes successive pairs. Use a deterministic even-length list; do not ..."
date: 2026-10-20
tags: ["multi-variable-for"]
layout: single
---

Flat lists often hold alternating names and values: inventory items and quantities, configuration keys and settings, or labels and measurements. Processing them one scalar at a time forces you to manage an index or remember whether the current element is a name or a value.

A multi-variable `for` loop lets you name both parts directly. This inventory report reads an ordered list in pairs, totals the available units, and identifies items needing replenishment without manual indexing or removing elements from the input.

```perl
use v5.44;
use strict;
use warnings;

my @stock = (
    notebooks => 12,
    pens      => 0,
    folders   => 7,
    markers   => 3,
);

my $reorder_below = 5;
my $total = 0;
my @reorder;

for my ($item, $quantity) (@stock) {
    $total += $quantity;
    printf "%s: %d\n", $item, $quantity;

    if ($quantity < $reorder_below) {
        push @reorder, $item;
    }
}

printf "Total units: %d\n", $total;
print "Reorder: ", join(', ', @reorder), "\n";

```

Expected output:

```text
notebooks: 12
pens: 0
folders: 7
markers: 3
Total units: 22
Reorder: pens, markers

```

The declaration `for my ($item, $quantity) (@stock)` consumes successive pairs from `@stock`. On the first iteration, `$item` is `notebooks` and `$quantity` is `12`; the next iteration receives `pens` and `0`. Each loop body therefore works with one complete inventory entry rather than one scalar at a time.

The body adds each quantity to `$total`, prints the current entry with `printf`, and uses `push` to collect names whose quantities are below `$reorder_below`. After the loop, `join` formats the reorder list. The zero quantity remains ordinary data: it is neither skipped nor mistaken for the end of the input.

The explicit array order makes both the item report and the reorder summary deterministic. This example deliberately supplies an even-length list, so every item has a corresponding quantity. For production data, validate that pairing requirement before processing; grouping values does not establish that they represent valid inventory records. Likewise, the loop does not check whether quantities are numeric or item names are unique.

Multi-variable iteration was introduced in Perl 5.36 and became stable in Perl 5.40. This program targets Perl 5.44 with `use v5.44;` and explicitly keeps `strict` and `warnings` enabled. It uses no experimental reference-alias syntax.

Example tested with Perl 5.44.

## More details

[multi-variable foreach loops in the Perl documentation](https://perldoc.perl.org/5.44.0/perlsyn).

[Read the perldelta behind this tip](https://perldoc.perl.org/5.44.0/perl5400delta).
