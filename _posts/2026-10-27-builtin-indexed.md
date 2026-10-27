---
title: "Pair array values with positions for numbered reports"
feature: "builtin-indexed"
feature_name: "builtin indexed"
perl_version: "5.44"
description: "Learn about builtin indexed in Perl. indexed returns alternating zero-based indices and copied values in list context. Do not call it in scalar context."
date: 2026-10-27
tags: ["builtin-indexed"]
layout: single
---

A checklist or diagnostic report often needs both an array element and its position. Maintaining a separate counter adds bookkeeping and can obscure whether displayed numbers start at zero or one. The `indexed` built-in supplies zero-based positions alongside copied values, letting you keep those two numbering conventions explicit. Here, a small task list becomes a numbered report, while one copied label is reformatted without changing the source array.

```perl
use v5.44;
use strict;
use warnings;

my @tasks = ('validate input', 'build report', 'send summary');
my @numbered = indexed @tasks;

# Change a copied value without changing the source array.
$numbered[1] = uc $numbered[1];

print "Run checklist:\n";
while (@numbered) {
    my ($index, $task) = splice @numbered, 0, 2;
    printf "%d. %s [index %d]\n", $index + 1, $task, $index;
}

print "Original first task: $tasks[0]\n";

```

Expected output:

```text
Run checklist:
1. VALIDATE INPUT [index 0]
2. build report [index 1]
3. send summary [index 2]
Original first task: validate input

```

The declaration `use v5.44;` makes `indexed` available without a separate import from `builtin`. Avoid importing it again in the same scope. The function was introduced in Perl 5.36 and became stable in Perl 5.40; this program uses no experimental features.

The assignment to `@numbered` supplies list context. For each element of `@tasks`, `indexed` returns two consecutive items: its zero-based index and a copy of its value. The resulting list contains twice as many items as the input. Its order follows the input order, so the first pair describes the first task, and subsequent pairs describe the remaining tasks.

The uppercase assignment changes the first copied task in `@numbered`. The final output confirms that `$tasks[0]` retains its original spelling. The returned values are not aliases to the source array elements.

Each loop iteration uses `splice` to remove the next two items, assigning them to `$index` and `$task`. The displayed checklist number adds one for readers, while the bracketed index preserves the zero-based position for diagnostics. Consuming pairs together keeps each position attached to the corresponding label.

Call `indexed` only in list context, not scalar context. This example materializes the entire alternating list and consumes it pair by pair, so it requires extra storage proportional to the input size.

Example tested with Perl 5.44.

## More details

[builtin indexed in the Perl documentation](https://perldoc.perl.org/5.44.0/builtin).

[Read the perldelta behind this tip](https://perldoc.perl.org/5.44.0/perl5400delta).
