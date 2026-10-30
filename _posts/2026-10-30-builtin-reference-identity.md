---
title: "Deduplicate shared references without comparing their contents"
feature: "builtin-reference-identity"
feature_name: "builtin refaddr"
perl_version: "5.44"
description: "Learn about builtin refaddr in Perl. refaddr identifies a referent. Compare addresses for equality; never print addresses because their values vary between r..."
date: 2026-10-30
tags: ["builtin-reference-identity"]
layout: single
---

A work queue can contain several references to the same hash, alongside separate hashes whose contents happen to match. Comparing field values cannot tell those cases apart. If processing must happen once per actual object, deduplicate by referent identity rather than by content. This example keeps the first occurrence of each hash reference and reports later aliases without exposing process-dependent addresses.

```perl
use v5.44;
use warnings;
use builtin ();

my $original = { name => 'worker', retries => 0 };
my $alias = $original;
my $independent = { name => 'worker', retries => 0 };

my @candidates = (
    [ primary => $original ],
    [ alias   => $alias ],
    [ copy    => $independent ],
);

my %first_label;
my @unique;

for my $candidate (@candidates) {
    my ($label, $reference) = @$candidate;
    my $address = builtin::refaddr($reference);

    if (exists $first_label{$address}) {
        say "$label: same referent as $first_label{$address}";
        next;
    }

    $first_label{$address} = $label;
    push @unique, $reference;
    say "$label: new referent";
}

say 'Unique referents: ', scalar @unique;
say 'Original and alias match: ',
    builtin::refaddr($original) == builtin::refaddr($alias) ? 'yes' : 'no';
say 'Original and copy match: ',
    builtin::refaddr($original) == builtin::refaddr($independent) ? 'yes' : 'no';

```

Expected output:

```text
primary: new referent
alias: same referent as primary
copy: new referent
Unique referents: 2
Original and alias match: yes
Original and copy match: no

```

The `builtin::refaddr` function identifies a reference's referent. It was introduced in Perl 5.36 and became stable in Perl 5.40; this program targets Perl 5.44 and uses no experimental features. The declaration `use builtin ();` loads the module without importing names. Fully qualified calls avoid redeclaring the short name already supplied by the Perl 5.44 feature bundle. Strict checking remains enabled through `use v5.44;`, and `use warnings;` enables warnings.

Assigning `$original` to `$alias` copies the reference, not the hash it points to. Both therefore identify the same referent. By contrast, `$independent` points to a separately constructed hash, even though its contents match the original exactly.

The loop obtains each referent's address with `builtin::refaddr` and uses it as a key in `%first_label`. An `exists` check determines whether that referent has already appeared. Only first encounters enter `@unique`, preserving input order without relying on hash iteration. The final comparisons use numeric equality, `==`, to make the identity distinction explicit.

Treat these addresses as temporary identity tokens, not persistent identifiers. Keep the referents alive while tracking them: an address can be reused after its referent is destroyed. Here, `@candidates` and `@unique` retain references throughout processing. Never print the addresses themselves, because their values vary between runs; print stable labels or comparison results instead.

Example tested with Perl 5.44.

## More details

[builtin refaddr in the Perl documentation](https://perldoc.perl.org/5.44.0/builtin).

[Read the perldelta behind this tip](https://perldoc.perl.org/5.44.0/perl5400delta).
