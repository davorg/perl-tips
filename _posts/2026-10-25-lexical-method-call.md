---
title: "Call local object helpers without package method lookup"
feature: "lexical-method-call"
feature_name: "lexical method invocation"
perl_version: "5.44"
description: "Learn about lexical method invocation in Perl. The ->& syntax invokes a lexical subroutine with the invocant as its first argument, bypassing name-based meth..."
date: 2026-10-25
tags: ["lexical-method-call"]
layout: single
---

Sometimes a caller needs an object-oriented-looking helper without adding a public method to the object's package. A local formatting routine, for example, may need the object plus caller-specific arguments, while the object already has a method with the same name. Perl's `->&` syntax lets you invoke a lexical subroutine with the object supplied first, keeping the helper local and avoiding name-based method resolution.

```perl
use v5.44;
use strict;
use warnings;

{
    package Parcel;

    sub new {
        my ($class, $id) = @_;
        return bless { id => $id }, $class;
    }

    sub label {
        my ($self) = @_;
        return "Parcel $self->{id}";
    }
}

my sub label {
    my ($parcel, $prefix) = @_;
    return "$prefix: $parcel->{id}";
}

my $parcel = Parcel->new('A17');
say 'Package method: ', $parcel->label();
say $parcel->&label('Dispatch');
say $parcel->&label('Returns');

```

Expected output:

```text
Package method: Parcel A17
Dispatch: A17
Returns: A17

```

The program creates an ordinary blessed object with a package method named `label`. It also declares a separate lexical subroutine using `my sub label`. Despite sharing a spelling, these are distinct routines with different selection rules.

The first call, `$parcel->label()`, uses ordinary name-based method resolution and reaches the package method. The next two calls use `$parcel->&label(...)`. This syntax selects the lexical subroutine directly, bypassing name-based method resolution, and supplies `$parcel` as its first argument. The explicit prefix follows it, so unpacking `@_` yields the object and then the prefix. The two different prefixes demonstrate that ordinary arguments still pass through normally.

Lexical method invocation was introduced in Perl 5.42 and has been stable since that release. The example targets Perl 5.44 and needs no experimental feature pragma or experimental class syntax.

This is useful for helpers that belong to the calling code rather than the object's public interface. It does not install a method in the object's package, and it does not provide polymorphic selection through inheritance. Here the helper reads `$parcel->{id}` directly, which deliberately couples it to this object's representation; keep that limitation in mind when using the pattern with objects maintained elsewhere.

Example tested with Perl 5.44.

## More details

[lexical method invocation in the Perl documentation](https://perldoc.perl.org/5.44.0/perlop).

[Read the perldelta behind this tip](https://perldoc.perl.org/5.44.0/perl5420delta).
