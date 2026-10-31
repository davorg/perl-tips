---
title: "Distinguish plain hash records from hash-backed objects"
feature: "builtin-reference-types"
feature_name: "builtin reftype and blessed"
perl_version: "5.44"
description: "Learn about builtin reftype and blessed in Perl. reftype reports the underlying container type; blessed reports an object class or undef. Avoid printing unde..."
date: 2026-10-31
tags: ["builtin-reference-types"]
layout: single
---

Code that receives mixed values often needs two separate answers: what kind of reference is this, and is it an object? A blessed hash reference is still backed by a hash, but treating it as an ordinary record can bypass the object's interface. Use `builtin::reftype` to inspect the underlying reference type and `builtin::blessed` to identify object membership. Keeping those questions separate lets a validator distinguish plain records from objects without assuming that every reference supports hash access.

```perl
use v5.44;
use strict;
use warnings;

{
    package Local::Job;

    sub new {
        my ($class, $name) = @_;
        return bless { name => $name }, $class;
    }
}

my @samples = (
    ['plain hash', { name => 'backup' }],
    ['job object', Local::Job->new('index')],
    ['array',      [qw(alpha beta)]],
    ['text',       'not a reference'],
);

for my $sample (@samples) {
    my ($label, $value) = @$sample;
    my $type  = builtin::reftype($value) // 'not a reference';
    my $class = builtin::blessed($value) // 'unblessed';

    say "$label: type=$type; class=$class";

    if ($type eq 'HASH' && !defined builtin::blessed($value)) {
        say "  plain record: $value->{name}";
    }
}

```

Expected output:

```text
plain hash: type=HASH; class=unblessed
  plain record: backup
job object: type=HASH; class=Local::Job
array: type=ARRAY; class=unblessed
text: type=not a reference; class=unblessed

```

The program calls `builtin::reftype` and `builtin::blessed` by their qualified names, without an explicit import. These functions were introduced in Perl 5.36 and became stable in Perl 5.40, so this Perl 5.44 program needs no experimental opt-in. Avoiding redundant imports also avoids declaration-masking warnings with the version bundle.

The sample data contains an ordinary hash reference, a hash-backed object, an array reference, and a string. The constructor uses `bless` to associate its hash reference with `Local::Job`. That association does not change its underlying container: `builtin::reftype($value)` returns `HASH` for both the ordinary hash reference and the object. Meanwhile, `builtin::blessed($value)` returns `Local::Job` only for the object.

For the string, `builtin::reftype` returns `undef`. For every non-object value, `builtin::blessed` returns `undef`. Each `//` supplies a printable fallback only when its left operand is undefined, avoiding warnings from interpolating an undefined result.

The conditional accepts a hash container only when `builtin::blessed` is undefined. Consequently, only the plain hash reaches the field access. Using `defined` tests whether an object class exists rather than whether its name is true.

Container inspection is not schema validation. A `HASH` result does not establish that a particular key exists. Here, the supplied plain record has the required `name` key; production validation should check its schema before reading fields.

Example tested with Perl 5.44.

## More details

[builtin reftype and blessed in the Perl documentation](https://perldoc.perl.org/5.44.0/builtin).

[Read the perldelta behind this tip](https://perldoc.perl.org/5.44.0/perl5400delta).
