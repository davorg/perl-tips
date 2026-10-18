---
title: "Read nested queue data with postfix dereferencing"
feature: "postderef"
perl_version: "5.36"
description: "Learn about postfix dereferencing in Perl. Postfix ->@* and ->%* dereference collections; stable since 5.24."
date: 2026-10-16
tags: ["postderef"]
layout: single
---

Configuration data often arrives as a hash reference whose values are array references. Reporting on it means accessing both collections, which can make expressions harder to scan when dereferencing wraps the reference expression. Postfix dereferencing lets you read from the reference expression toward the collection operation. This queue report uses that order to list jobs and count them.

```perl
use v5.36;

my $queue_config = {
    urgent  => ['restore backup', 'renew certificate'],
    routine => ['rotate logs', 'archive reports', 'check disk space'],
};

my %queues = $queue_config->%*;

for my $name (sort keys %queues) {
    my @jobs = $queues{$name}->@*;
    say "$name: " . scalar(@jobs) . " jobs";
    say "  $_" for @jobs;
}

```

Expected output:

```text
routine: 3 jobs
  rotate logs
  archive reports
  check disk space
urgent: 2 jobs
  restore backup
  renew certificate

```

Postfix dereferencing puts the collection operation after the expression that produces the reference. The `->%*` form dereferences a hash reference, while `->@*` dereferences an array reference. This syntax was introduced in Perl 5.20 and has been stable since Perl 5.24. The program targets Perl 5.36 and needs no additional feature pragma; `use v5.36` also enables `strict` and `warnings`.

The first dereference assigns the configuration hash's key/value pairs to `%queues`. Each value remains a reference to an array of job descriptions. Sorting the hash keys gives the report a predictable queue order rather than relying on hash iteration order.

Inside the loop, `$queues{$name}->@*` supplies the selected array's elements to `@jobs`. The report counts that local array and prints its descriptions in their original order. Both dereferences appear in list context here, so they supply collection contents rather than a single reference.

These assignments create shallow copies, not recursive clones. `%queues` still contains the original array references. `@jobs` is a separate array containing the selected job values; if those values were themselves references, their referents would remain shared too.

Use the suffix that matches the referenced collection. This example assumes every configuration value is an array reference; postfix syntax does not validate or repair malformed configuration data.

Example tested with Perl 5.36.

## More details

[postfix dereferencing in the Perl documentation](https://perldoc.perl.org/5.36.0/perlref#Postfix-Dereference-Syntax).
