---
title: "Observe objects without keeping them alive"
feature: "builtin-weak-references"
feature_name: "builtin weak-reference utilities"
perl_version: "5.44"
description: "Learn about builtin weak-reference utilities in Perl. weaken, unweaken and is_weak control reference strength. A weak reference becomes undef when no strong ..."
date: 2026-10-29
tags: ["builtin-weak-references"]
layout: single
---

An observer, registry, or back-reference often needs access to an object without becoming another owner. Ordinary references keep their targets alive, which can make temporary bookkeeping retain data unexpectedly. A weak reference lets you inspect an existing object while leaving its lifetime under the control of strong references. This example also shows how to turn a weak reference back into an owning reference when you deliberately need to keep the object alive.

```perl
use v5.44;
use strict;
use warnings;

my $owner = { name => 'report' };
my $observer = $owner;
weaken($observer);

say 'Observer is weak: ', is_weak($observer) ? 'yes' : 'no';

my $pinned = $owner;
weaken($pinned);
say 'Pin starts weak: ', is_weak($pinned) ? 'yes' : 'no';

unweaken($pinned);
say 'Pin is now strong: ', is_weak($pinned) ? 'no' : 'yes';

undef $owner;
say 'After releasing owner: ',
    defined($observer) ? $observer->{name} : 'gone';

undef $pinned;
say 'After releasing pin: ',
    defined($observer) ? $observer->{name} : 'gone';
say 'Observer is defined: ', defined($observer) ? 'yes' : 'no';

```

Expected output:

```text
Observer is weak: yes
Pin starts weak: yes
Pin is now strong: yes
After releasing owner: report
After releasing pin: gone
Observer is defined: no

```

The `use v5.44;` declaration makes `weaken`, `unweaken`, and `is_weak` available without an explicit import from `builtin`. Importing them again would produce declaration-masking warnings. These utilities were introduced in Perl 5.36 and became stable in Perl 5.40; this program uses no experimental features.

Initially, `$owner` holds a strong reference to a hash. Assigning it to `$observer` creates another reference to the same hash. Calling `weaken($observer)` changes the reference stored in that variable: it can still access the hash, but it no longer keeps the hash alive. `is_weak($observer)` checks its strength without changing it.

The `$pinned` variable demonstrates the reverse operation. After weakening its reference, the program calls `unweaken($pinned)` to restore a strong reference. Releasing `$owner` therefore does not destroy the hash: `$pinned` still owns it, and `$observer` can still read its name.

Releasing `$pinned` removes the final strong reference. Perl then automatically changes `$observer` to `undef`. The final checks demonstrate that the observer itself is no longer defined, rather than referring to an empty hash.

Use this pattern when an observer should follow an object's lifetime rather than extend it. Check `defined($observer)` before dereferencing a weak reference that may have expired. At least one strong reference must remain for as long as the object is needed. Restoring strength deliberately extends that lifetime, so release the restored reference when its ownership role ends.

Example tested with Perl 5.44.

## More details

[builtin weak-reference utilities in the Perl documentation](https://perldoc.perl.org/5.44.0/builtin).

[Read the perldelta behind this tip](https://perldoc.perl.org/5.44.0/perl5400delta).
