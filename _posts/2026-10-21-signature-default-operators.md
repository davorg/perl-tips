---
title: "Choose signature defaults that preserve meaningful false values"
feature: "signature-default-operators"
feature_name: "defined-or and logical-or signature defaults"
perl_version: "5.44"
description: "Learn about defined-or and logical-or signature defaults in Perl. Signature defaults using $value //= EXPR or $value ||= EXPR also handle supplied undef or f..."
date: 2026-10-21
tags: ["signature-default-operators"]
layout: single
---

Optional arguments need a precise policy: should a fallback replace only a missing argument, an explicit `undef`, or every false value? Ordinary signature defaults handle only omission. Defined-or and logical-or signature defaults let you express the other policies directly in the parameter declaration, without repeating checks inside the subroutine. This comparison uses identical fallback values so the behavioral differences are visible.

```perl
use v5.44;
use warnings;

sub omitted_only ($value = 'fallback') {
    return $value;
}

sub undefined_too ($value //= 'fallback') {
    return $value;
}

sub false_too ($value ||= 'fallback') {
    return $value;
}

sub display ($value) {
    return '<undef>' unless defined $value;
    return '<empty>' if $value eq '';
    return $value;
}

my @cases = (
    ['omitted'],
    ['undef', undef],
    ['zero', 0],
    ['empty', ''],
    ['text', 'custom'],
);

say 'input | = | //= | ||=';
for my $case (@cases) {
    my ($label, @args) = @$case;
    say join ' | ',
        $label,
        display(omitted_only(@args)),
        display(undefined_too(@args)),
        display(false_too(@args));
}

```

Expected output:

```text
input | = | //= | ||=
omitted | fallback | fallback | fallback
undef | <undef> | fallback | fallback
zero | 0 | 0 | fallback
empty | <empty> | <empty> | fallback
text | custom | custom | custom

```

The three subroutines differ only in their signature default syntax. With `$value = 'fallback'`, the default applies only when the caller omits the argument. Explicitly passing `undef` still supplies an argument, so that value reaches the body unchanged.

With `$value //= 'fallback'`, either omission or a supplied undefined value selects the default. Defined false values, including numeric zero and the empty string, survive. This is usually the appropriate policy when zero is a meaningful quantity or an empty string deliberately suppresses text.

With `$value ||= 'fallback'`, omission or any supplied false value selects the default. That includes `undef`, zero, the empty string, and the string `'0'`. Choose this form only when replacing all false inputs matches the interface contract; it is not interchangeable with `//=`.

Each case stores a label followed by its arguments. Expanding `@args` therefore tests a genuinely omitted argument separately from an explicit `undef`. The `display` helper makes undefined and empty results visible without triggering warnings. The rows follow array order, so output is deterministic.

The `//=` and `||=` signature default forms were introduced and became stable in Perl 5.38. Ordinary `=` signature defaults predate that release. The program targets Perl 5.44 with `use v5.44;`, which enables strictness; `use warnings;` explicitly enables warnings. Defaults provide a fallback policy, not input validation: a supplied true value passes through all three signatures unchanged.

Example tested with Perl 5.44.

## More details

[defined-or and logical-or signature defaults in the Perl documentation](https://perldoc.perl.org/5.44.0/perlsub).

[Read the perldelta behind this tip](https://perldoc.perl.org/5.44.0/perl5380delta).
