---
title: "Apply defaults without replacing zero or empty strings"
feature: "defined-or"
perl_version: "5.36"
description: "Learn about defined-or in Perl. // selects the fallback only for undef; zero and empty strings are defined."
date: 2026-10-14
tags: ["defined-or"]
layout: single
---

Configuration defaults should fill gaps without overwriting deliberate choices. A retry count of zero can mean “do not retry,” while an empty label can mean “display no label.” Using logical-or, `||`, for these defaults would replace both values because they are false. Use defined-or when `undef`, rather than falseness, means a setting needs a fallback.

```perl
use v5.36;

my @jobs = (
    { name => 'missing', retries => undef, label => undef },
    { name => 'zero',    retries => 0,     label => ''    },
    { name => 'custom',  retries => 5,     label => 'QA'  },
);

my $fallback_calls = 0;
my $default_label = sub {
    ++$fallback_calls;
    return 'worker';
};

for my $job (@jobs) {
    my $retries = $job->{retries} // 3;
    my $label = $job->{label} // $default_label->();

    printf "%s: retries=%d, label=[%s]\n",
        $job->{name}, $retries, $label;
}

say "Label fallbacks evaluated: $fallback_calls";

```

Expected output:

```text
missing: retries=3, label=[worker]
zero: retries=0, label=[]
custom: retries=5, label=[QA]
Label fallbacks evaluated: 1

```

The defined-or operator, `//`, was introduced in Perl 5.10. It evaluates its left operand and returns that value when it is defined. Only when the left operand is `undef` does it evaluate and return the right operand. This makes it suitable for defaults where zero and empty strings carry meaning.

The program processes three job configurations in a fixed order. For the first job, both settings are `undef`, so the retry count becomes 3 and the label becomes `worker`. The second job explicitly requests zero retries and an empty label. Both values survive unchanged; the brackets in the output make the empty label visible. The third job supplies ordinary defined values, which also pass through unchanged.

The label fallback is a subroutine reference that increments a counter before returning its default. The final count demonstrates short-circuit evaluation: the fallback runs only for the undefined label, not for every job. That matters when calculating a default requires work or has side effects.

These assignments put the selected values into local variables; they do not modify the job hashes. Also, `//` is not a validation rule. A defined but unsuitable value still passes through, so check acceptable ranges or formats separately when necessary. The program starts with `use v5.36;`, which keeps `strict` and `warnings` enabled.

Example tested with Perl 5.36.

## More details

[defined-or in the Perl documentation](https://perldoc.perl.org/5.36.0/perlop#Logical-Defined-Or).
