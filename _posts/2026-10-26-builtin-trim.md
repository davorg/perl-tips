---
title: "Clean label boundaries without changing internal spacing"
feature: "builtin-trim"
feature_name: "builtin trim"
perl_version: "5.44"
description: "Learn about builtin trim in Perl. trim returns a string without leading or trailing whitespace; the original is unchanged. Internal whitespace remains."
date: 2026-10-26
tags: ["builtin-trim"]
layout: single
---

Labels copied from forms or assembled by other code often arrive with unwanted spaces, tabs, or newlines at their edges. Removing every whitespace character would damage legitimate spacing inside a name. You may also need to preserve the original input while preparing a clean display value.

Use `builtin::trim` to create cleaned strings, then decide explicitly whether empty results should be retained. This example removes blank labels without accidentally discarding the valid label `"0"`.

```perl
use v5.44;
use strict;
use warnings;
use builtin ();

my @raw_labels = (
    "  Ada  Lovelace \t",
    "\tGrace Hopper\n",
    "  0  ",
    " \t\n",
);

my @labels;
for my $raw (@raw_labels) {
    my $label = builtin::trim($raw);
    push @labels, $label if length($label);
}

say 'Labels ready for display:';
for my $label (@labels) {
    say "[$label]";
}

say 'First input unchanged: ',
    $raw_labels[0] eq "  Ada  Lovelace \t" ? 'yes' : 'no';
say 'Input records: ', scalar @raw_labels;
say 'Nonblank labels: ', scalar @labels;

```

Expected output:

```text
Labels ready for display:
[Ada  Lovelace]
[Grace Hopper]
[0]
First input unchanged: yes
Input records: 4
Nonblank labels: 3

```

The program loads the core `builtin` module without importing names and calls `builtin::trim` explicitly. This avoids redeclaring the `trim` name already available under `use v5.44;`. The function was introduced in Perl 5.36 and became stable in Perl 5.40, so it needs no experimental opt-in when targeting Perl 5.44. Both `strict` and `warnings` remain enabled.

For each input record, `builtin::trim($raw)` returns a string with leading and trailing whitespace removed. Assigning that result to `$label` leaves the original element in `@raw_labels` unchanged. The equality check confirms this for the first record, including its surrounding spaces and trailing tab.

Internal whitespace remains untouched: the first displayed name still contains two spaces between its words. The brackets make the cleaned boundaries visible, while the tab and newline surrounding the second name disappear. This is boundary cleanup, not general whitespace normalization.

The `length($label)` test rejects the whitespace-only record after trimming turns it into an empty string. It deliberately avoids a truth-value test: the label `"0"` has a nonzero length and must remain in the results even though Perl treats that string as false.

Separate input and output arrays preserve original records for auditing or later validation. Trimming alone does not establish that a label is valid for an application; apply content rules separately.

Example tested with Perl 5.44.

## More details

[builtin trim in the Perl documentation](https://perldoc.perl.org/5.44.0/builtin).

[Read the perldelta behind this tip](https://perldoc.perl.org/5.44.0/perl5400delta).
