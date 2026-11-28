---
title: "Temporarily hide hash entries without losing their state"
feature: "delete-local"
feature_name: "temporarily deleting hash entries"
perl_version: "5.36"
description: "Learn about temporarily deleting hash entries in Perl. delete local $hash{key} hides an entry until scope exit, restoring its previous existence and value. D..."
date: 2026-11-28
tags: ["delete-local"]
layout: single
---

Configuration code sometimes needs to behave as though a setting was never supplied, then recover the original state afterward. Assigning `undef` is insufficient when downstream code uses `exists`, while manually deleting and restoring an entry risks losing the distinction between an absent key and an undefined value. Introduced and stable in Perl 5.12, `delete local` provides scoped removal of individual hash entries. This Perl 5.36 example temporarily hides settings and restores them automatically when the block ends.

```perl
use v5.36;

my %config = (
    mode  => 'production',
    token => undef,
);

sub show_config {
    my ($label) = @_;
    my @entries;

    for my $key (qw(mode token missing)) {
        my $value = !exists $config{$key} ? '<absent>'
                  : !defined $config{$key} ? '<undef>'
                  : $config{$key};
        push @entries, "$key=$value";
    }

    say "$label: ", join ', ', @entries;
}

show_config('Before');

{
    delete local $config{mode};
    delete local $config{token};
    delete local $config{missing};

    show_config('Hidden');

    $config{mode} = 'debug';
    $config{token} = 'temporary';
    $config{missing} = 'created';

    show_config('Changed');
}

show_config('Restored');

```

Expected output:

```text
Before: mode=production, token=<undef>, missing=<absent>
Hidden: mode=<absent>, token=<absent>, missing=<absent>
Changed: mode=debug, token=temporary, missing=created
Restored: mode=production, token=<undef>, missing=<absent>

```

The program starts with three distinct states: `mode` has a string value, `token` exists but holds `undef`, and `missing` does not exist. The reporting subroutine checks `exists` before `defined`, so it does not mistake an undefined value for an absent entry. It visits a fixed list of keys to keep output deterministic.

Inside the block, each `delete local` expression saves the entry's previous state and removes it for the current scope. The Hidden line confirms that all three keys are absent. Assignments then create temporary entries, demonstrating that the hash remains usable while those saved states are pending restoration.

Leaving the block restores the original string and the existing entry containing `undef`. It also removes the newly created `missing` entry, because that key was originally absent. Restoration therefore preserves existence as well as value; it does not merely assign an old value back.

This localization is dynamically scoped: subroutines called while the block is active observe the temporary hash state, as the reporting calls demonstrate. It is not a private copy of the hash, and unrelated entries are not rolled back. Use it when called code should temporarily see selected keys as absent, rather than when you need an isolated configuration structure.

Example tested with Perl 5.36.

## More details

[temporarily deleting hash entries in the Perl documentation](https://perldoc.perl.org/5.36.0/perlfunc).

[Read the perldelta behind this tip](https://perldoc.perl.org/5.36.0/perl5120delta).
