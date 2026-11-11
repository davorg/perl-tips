---
title: "Extract selected hash keys together with their values"
feature: "key-value-hash-slices"
feature_name: "key/value hash slices"
perl_version: "5.36"
description: "Learn about key/value hash slices in Perl. %hash{LIST} returns alternating keys and values. Use a fixed key list to control output order; distinguish it from..."
date: 2026-11-11
tags: ["key-value-hash-slices"]
layout: single
---

When preparing a configuration summary or extracting a subset of settings, you often need both the selected names and their values. A value-only hash slice loses the names, while iterating over the whole hash includes unwanted entries. A key/value hash slice lets you request exactly the entries you need in an explicit order, then use the resulting list for reporting or constructing a smaller hash.

```perl
use v5.36;

my %settings = (
    host    => 'localhost',
    port    => 8080,
    retries => 0,
    debug   => 0,
);
my @keys = qw(host port retries);

my @pairs = %settings{@keys};
my @values = @settings{@keys};

say 'Selected key/value pairs:';
for my $i (0 .. $#keys) {
    my $offset = 2 * $i;
    say "$pairs[$offset]=$pairs[$offset + 1]";
}

say 'Values only: ', join(', ', @values);

my %selected = %settings{@keys};
$selected{port} = 9090;

say "Selected port: $selected{port}";
say "Original port: $settings{port}";

```

Expected output:

```text
Selected key/value pairs:
host=localhost
port=8080
retries=0
Values only: localhost, 8080, 0
Selected port: 9090
Original port: 8080

```

A key/value hash slice, introduced and stable in Perl 5.20, uses the syntax `%hash{LIST}`. It returns an alternating list of keys and their corresponding values. Here, `%settings{@keys}` produces six elements: three requested keys, each immediately followed by its value. The order follows `@keys`, so the program does not depend on hash iteration order.

The first assignment stores that flat list in `@pairs`. The loop visits each requested position, calculates its offset in the alternating list, and prints the adjacent key and value. No sorting or search is needed because the selection list already specifies the desired presentation order. The zero retry count is retained just like any other value.

Compare this with `@settings{@keys}`: changing the leading sigil selects a value-only slice. Its three elements contain no key names, as the second output section demonstrates. Both expressions access the same underlying hash; their returned list shapes differ.

Assigning the key/value slice directly to `%selected` creates a smaller hash from the selected entries. Changing `$selected{port}` afterward does not change `$settings{port}`. This is an ordinary copy of the selected scalar values, not a deep copy of any referenced structures they might contain.

Keep the ordered key list when presentation order matters: storing the result in another hash does not preserve that ordering. This example deliberately selects existing keys; it is not a missing-key validation routine.

Example tested with Perl 5.36.

## More details

[key/value hash slices in the Perl documentation](https://perldoc.perl.org/5.36.0/perldata).

[Read the perldelta behind this tip](https://perldoc.perl.org/5.36.0/perl5200delta).
