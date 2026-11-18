---
title: "Replace field values without capturing their labels"
feature: "regex-keep"
feature_name: "resetting the start of a regex match"
perl_version: "5.36"
description: "Learn about resetting the start of a regex match in Perl. \\K keeps the consumed prefix outside the reported match and replacement. Use it to replace a suffix..."
date: 2026-11-18
tags: ["regex-keep"]
layout: single
---

Redacting a field in diagnostic output often means keeping its label while replacing its value. Capturing the label and inserting it again works, but makes the replacement responsible for preserving text that should never change. The regex escape `\K`, introduced and stable in Perl 5.10, lets the pattern consume that context without including it in the reported match. This Perl 5.36 program uses it to redact nonempty token values while preserving the surrounding fields.

```perl
use v5.36;

my @lines = (
    'service=api token=abc123 retries=0',
    'service=worker token=secret-42 retries=3',
    'service=cache token= retries=1',
    'service=proxy token=xyz789 retries=2',
);

my $redacted = 0;
for my $line (@lines) {
    $redacted += ($line =~ s/\btoken=\K\S+/[REDACTED]/g);
    say $line;
}
say "Values redacted: $redacted";

```

Expected output:

```text
service=api token=[REDACTED] retries=0
service=worker token=[REDACTED] retries=3
service=cache token= retries=1
service=proxy token=[REDACTED] retries=2
Values redacted: 3

```

The pattern first matches the field label with `\btoken=`. The word boundary `\b` prevents that match from starting within a longer word, such as a field named `access_token`. Next, `\K` resets the start of the reported match. The engine has consumed the label, but the label is outside the text that the substitution replaces. Finally, `\S+` matches one or more non-whitespace characters: the value to redact.

Consequently, the replacement text `[REDACTED]` overwrites only the value. There is no prefix capture to maintain and no captured prefix to interpolate into the replacement. The `/g` modifier applies the substitution to every matching field on a line, and the return value of `s///` supplies the number of substitutions. Adding those counts to `$redacted` produces the final summary.

The empty value is deliberately unchanged because `+` requires at least one character. The other fields, including their spacing and zero values, remain intact. The input array is processed in its original order, so the output is deterministic.

This is a whitespace-delimited field example, not a general log parser. Quoted values containing spaces require a pattern appropriate to that format. Also, the boundary check does not enforce a complete field grammar; punctuation before the label may still permit a match. Use this technique when a prefix establishes context but should not become part of the replacement.

Example tested with Perl 5.36.

## More details

[resetting the start of a regex match in the Perl documentation](https://perldoc.perl.org/5.36.0/perlre).

[Read the perldelta behind this tip](https://perldoc.perl.org/5.36.0/perl5100delta).
