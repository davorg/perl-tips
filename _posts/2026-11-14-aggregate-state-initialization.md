---
title: "Keep a private work queue between subroutine calls"
feature: "aggregate-state-initialization"
feature_name: "initializing persistent arrays and hashes"
perl_version: "5.36"
description: "Learn about initializing persistent arrays and hashes in Perl. state @items = (...) and state %counts = (...) support one-time aggregate initialization. This..."
date: 2026-11-14
tags: ["aggregate-state-initialization"]
layout: single
---

A subroutine that consumes queued work often needs both pending items and running counts to survive between calls. Ordinary initialized lexical aggregates would restart on every call. Package variables avoid that reset but expose implementation details more broadly. Initialized `state` arrays and hashes keep this mutable bookkeeping local while preserving it across calls.

```perl
use v5.36;

sub next_job {
    state @items = qw(email report email report);
    state %counts = (email => 0, report => 10);

    return if !@items;

    my $item = shift @items;
    my $number = ++$counts{$item};
    return "$item run $number";
}

while (defined(my $message = next_job())) {
    say $message;
}

say 'Queue empty';
say 'Still empty' unless defined next_job();

```

Expected output:

```text
email run 1
report run 11
email run 2
report run 12
Queue empty
Still empty

```

The program models a small work queue with per-job counters. Inside `next_job`, `state @items` initializes the pending jobs, while `state %counts` initializes the counters. The report counter starts at ten to represent earlier work; its next value is eleven rather than one. Both aggregates remain private to the subroutine's lexical scope.

Each declaration initializes its aggregate only the first time execution reaches it. Later calls reuse the same array and hash, including mutations made by earlier calls. Here, `shift @items` removes the next job, and `++$counts{$item}` advances that job's counter before the message is returned. Repeated job names therefore receive increasing numbers without rebuilding either aggregate.

Once the array is empty, the bare `return` supplies an undefined result in the caller's scalar context. The loop tests `defined` rather than truth, making the end-of-work condition explicit. A final call confirms that exhaustion persists: the original queue is not reconstructed after the loop ends.

One-time initialization of arrays and hashes declared with `state` was introduced and stable in Perl 5.28. This program targets Perl 5.36, where `use v5.36;` enables the required feature while keeping strictness and warnings enabled.

Declare each persistent aggregate separately. This capability does not permit initializing a list of state variables. Also distinguish persistence between calls from durable storage: these values live in the running program, not in a database or file. Use this pattern when one shared queue and its counters are appropriate; it does not provide an independent queue for each caller.

Example tested with Perl 5.36.

## More details

[initializing persistent arrays and hashes in the Perl documentation](https://perldoc.perl.org/5.36.0/perlsub).

[Read the perldelta behind this tip](https://perldoc.perl.org/5.36.0/perl5280delta).
