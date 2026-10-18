---
title: "Print array contents directly from references in strings"
feature: "postderef-qq"
feature_name: "postfix dereferencing in strings"
perl_version: "5.36"
description: "Learn about postfix dereferencing in strings in Perl. Enables interpolated postfix dereferences; stable since 5.24. Ordinary ->{key} needs no new pragma."
date: 2026-10-17
tags: ["postderef-qq"]
layout: single
---

Status messages often need to display task names held in an array reference. Building temporary arrays just to interpolate them adds clutter, especially when the collection changes during processing. Interpolated postfix dereferencing lets a double-quoted string display the referenced elements directly, while a localized separator keeps the resulting report readable.

```perl
use v5.36;
use feature 'postderef_qq';

my $pending = [qw(validate compile test package)];
my $finished = [];

{
    local $" = ', ';
    print "Before: $pending->@*\n";

    push $finished->@*, splice($pending->@*, 0, 2);

    print "Finished: $finished->@*\n";
    print "Remaining: $pending->@*\n";
}

printf "Counts: %d finished, %d remaining\n",
    scalar($finished->@*), scalar($pending->@*);

```

Expected output:

```text
Before: validate, compile, test, package
Finished: validate, compile
Remaining: test, package
Counts: 2 finished, 2 remaining

```

The program keeps pending and finished task names in array references. Inside each double-quoted status string, `$pending->@*` or `$finished->@*` dereferences the corresponding array and interpolates its elements. The reference stays on the left, making the expression read in the same direction as other arrow-based access.

The `postderef_qq` feature enables this interpolated postfix dereferencing. It was introduced in Perl 5.20 and became stable in Perl 5.24. This program targets Perl 5.36, where the syntax is stable. The explicit feature declaration identifies the capability being demonstrated; `use v5.36` also keeps `strict` and `warnings` enabled.

Array interpolation separates elements using the value of Perl's special `$"` variable. The localized assignment changes that separator to a comma and space only within the surrounding block. It does not change either array or permanently alter the separator for later output. For more elaborate formatting, an explicit `join` outside the string may be clearer.

The `splice` removes two tasks from the pending array, and `push` appends those tasks to the finished array. Those operations use ordinary postfix dereferencing outside strings; the selected feature concerns its use during interpolation. The later status lines therefore reflect changed data rather than prewritten summaries. Finally, `scalar` postfix dereferencing supplies the two counts to `printf`.

Use this interpolation when you want all array elements rendered as text. It does not add quoting or escaping to individual elements. Ordinary hash-element access such as `->{key}` needs no new pragma.

Example tested with Perl 5.36.

## More details

[postfix dereferencing in strings in the Perl documentation](https://perldoc.perl.org/5.36.0/feature#The-'postderef'-and-'postderef_qq'-features).
