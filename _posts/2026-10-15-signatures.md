---
title: "Declare positional arguments and reject incorrect argument counts"
feature: "signatures"
feature_name: "subroutine signatures"
perl_version: "5.36"
description: "Learn about subroutine signatures in Perl. Positional parameters with arity checks; stable since 5.36, not named parameters."
date: 2026-10-15
tags: ["signatures"]
layout: single
---

Small utility subroutines often begin by unpacking arguments, assigning defaults, and checking whether callers supplied enough values. Subroutine signatures put parameter names and argument-count rules directly in the declaration. Introduced in Perl 5.20 and stable since Perl 5.36, they are enabled by `use v5.36`, which also keeps `strict` and `warnings` enabled. This invoice formatter demonstrates required arguments, an optional discount, and rejection of incorrect argument counts.

```perl
use v5.36;

sub invoice_line ($sku, $quantity, $unit_price, $discount = 0) {
    my $total = $quantity * $unit_price * (1 - $discount);
    return sprintf '%s: %d units, total %.2f', $sku, $quantity, $total;
}

say invoice_line('PEN', 3, 2.50);
say invoice_line('PAD', 2, 5.00, 0.10);

my @invalid_calls = (
    ['Missing price', ['PEN', 3]],
    ['Extra argument', ['PAD', 2, 5.00, 0.10, 'unexpected']],
);

for my $case (@invalid_calls) {
    my ($label, $arguments) = @$case;
    my $ok = eval {
        invoice_line(@$arguments);
        1;
    };
    say "$label: rejected" unless $ok;
}

```

Expected output:

```text
PEN: 3 units, total 7.50
PAD: 2 units, total 9.00
Missing price: rejected
Extra argument: rejected

```

The signature immediately after `invoice_line` names three required positional parameters and one optional parameter. Perl binds arguments to these lexical variables in order, so the body can calculate the total without manually unpacking `@_`. The first call omits the discount and receives its default of zero. The second supplies a ten-percent discount, producing a total of 9.00.

The signature also defines the accepted argument count: this subroutine takes three or four arguments. The two deliberately invalid calls supply two and five arguments. Each runs inside `eval`, which catches the resulting exception before it can terminate the program. The final 1 inside `eval` distinguishes a successful call from an exception without depending on the subroutine's return value. Fixed rejection messages keep the output independent of diagnostic wording and source line numbers.

A default applies when its argument is omitted, not merely because the caller passes `undef`. These parameters are positional, not named: callers must preserve their order, and parameter names do not create a named-argument interface.

Signatures check argument counts here, not business rules or data types. Production code would still need to validate quantities, prices, and discount ranges. This compact example uses ordinary numeric arithmetic and `sprintf` for display; it is not a financial rounding policy.

Example tested with Perl 5.36.

## More details

[subroutine signatures in the Perl documentation](https://perldoc.perl.org/5.36.0/perlsub#Signatures).
