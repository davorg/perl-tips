---
title: "Preserve captured fields before another match replaces them"
feature: "capture-array"
feature_name: "the capture array"
perl_version: "5.36"
description: "Learn about the capture array in Perl. @{^CAPTURE} contains captures from the last successful match; index zero corresponds to $1. Copy results before anothe..."
date: 2026-11-10
tags: ["capture-array"]
layout: single
---

A record parser often needs several captured fields, but manually listing `$1`, `$2`, and `$3` becomes repetitive. Worse, a later successful match can replace those values before processing finishes. The capture array, `@{^CAPTURE}`, introduced and stable in Perl 5.26, lets you copy the captures together. This Perl 5.36 example preserves parsed task fields before another match extracts a numeric identifier.

```perl
use v5.36;

my @records = (
    'TASK-104 owner=maya state=open',
    'TASK-205 owner=liam state=closed',
);

for my $record (@records) {
    next unless $record =~ /\A(TASK-\d+) owner=(\w+) state=(\w+)\z/;

    my @fields = @{^CAPTURE};

    # This second match replaces the current captures.
    my ($number) = $fields[0] =~ /\ATASK-(\d+)\z/;

    say join ' | ', @fields;
    say "Numeric ID: $number; current captures: ",
        join ', ', @{^CAPTURE};
}

```

Expected output:

```text
TASK-104 | maya | open
Numeric ID: 104; current captures: 104
TASK-205 | liam | closed
Numeric ID: 205; current captures: 205

```

The first regular expression recognizes a complete task record and captures its identifier, owner, and state. The anchors `\A` and `\z` require the entire string to match. Only matching records enter the processing block, so malformed input is skipped rather than accidentally processed using captures from an earlier successful match.

Immediately after that match, `my @fields = @{^CAPTURE};` copies all three captured values into an ordinary lexical array. Index zero of `@{^CAPTURE}` corresponds to `$1`, index one to `$2`, and so on. The array provides the captured groups, not the complete matched text.

The second match extracts the numeric portion of the saved identifier. Because it succeeds, it replaces the current captures: `@{^CAPTURE}` now contains just that number. The output deliberately prints both the saved fields and the current captures, making the difference visible. The original identifier, owner, and state remain available in `@fields` despite the intervening match.

Make the copy before calling other matching code, not afterward. Treat `@{^CAPTURE}` as transient match state rather than storage belonging to a record. A failed match does not provide a fresh set of captures, which is another reason to check success before copying.

This example assumes simple word-character owner and state values and silently skips invalid records; adapt those choices to your input format.

Example tested with Perl 5.36.

## More details

[the capture array in the Perl documentation](https://perldoc.perl.org/5.36.0/perlvar).

[Read the perldelta behind this tip](https://perldoc.perl.org/5.36.0/perl5260delta).
