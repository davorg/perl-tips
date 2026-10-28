---
title: "Use explicit boolean flags to control notification jobs"
feature: "builtin-booleans"
feature_name: "builtin true and false"
perl_version: "5.44"
description: "Learn about builtin true and false in Perl. true and false provide boolean values, not strings. Do not use experimental is_bool to demonstrate them."
date: 2026-10-28
tags: ["builtin-booleans"]
layout: single
---

Configuration records often need clear yes-or-no settings: whether a notification is enabled, or whether it should only be previewed. Quoted words can be misleading because `'false'` is a nonempty string and therefore true in a condition. Perl's built-in functions `true` and `false` let you express those decisions directly. This small notification planner stores boolean flags and returns a boolean decision before choosing a readable action for each job.

```perl
use v5.44;
use strict;
use warnings;

my @jobs = (
    { name => 'welcome', enabled => true,  preview => true  },
    { name => 'receipt', enabled => false, preview => false },
    { name => 'renewal', enabled => true,  preview => false },
);

sub should_send ($job) {
    return ($job->{enabled} && !$job->{preview}) ? true : false;
}

my $sent = 0;
for my $job (@jobs) {
    my $send = should_send($job);
    my $action = $send ? 'send'
               : $job->{enabled} ? 'preview'
               : 'skip';

    say "$job->{name}: $action";
    ++$sent if $send;
}
say "Messages to send: $sent";

```

Expected output:

```text
welcome: preview
receipt: skip
renewal: send
Messages to send: 1

```

The declaration `use v5.44;` makes the built-in functions `true` and `false` available, so the program does not import them again. These functions provide boolean values, not the strings `'true'` and `'false'`. They were introduced in Perl 5.36 and became stable in Perl 5.40; this example uses no experimental features.

Each job carries two explicit flags. The `enabled` field determines whether the job participates at all, while `preview` prevents an enabled job from sending. Using `true` and `false` makes those choices visible where the records are constructed, without requiring readers to interpret numeric conventions.

The `should_send` subroutine combines the flags using `&&` and `!`, then uses `? :` to return either `true` or `false`. That explicit return contract is useful when a predicate should expose a yes-or-no result rather than pass through an arbitrary operand value. The loop uses the returned boolean both to select an action and to update `$sent`.

Only the renewal job qualifies for sending. The welcome job remains a preview, and the disabled receipt job is skipped. Iterating over an array keeps the report in its declared order.

These booleans do not validate or parse external configuration. In particular, the nonempty string `'false'` is true in an ordinary Perl condition. Convert textual settings deliberately before placing them into flags like these. Printing a boolean directly does not produce a human-readable word: choose explicit labels with `? :`, as the report does.

Example tested with Perl 5.44.

## More details

[builtin true and false in the Perl documentation](https://perldoc.perl.org/5.44.0/builtin).

[Read the perldelta behind this tip](https://perldoc.perl.org/5.44.0/perl5400delta).
