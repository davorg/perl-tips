---
title: "Set readable regex defaults within a lexical scope"
feature: "lexical-regex-flags"
feature_name: "lexical regular expression defaults"
perl_version: "5.36"
description: "Learn about lexical regular expression defaults in Perl. use re '/x' applies a regex flag within its lexical scope. The flags are chosen when the pattern is ..."
date: 2026-11-26
tags: ["lexical-regex-flags"]
layout: single
---

A small configuration parser can quickly accumulate regular expressions whose dense punctuation hides their intent. Extended mode lets you lay out patterns and annotate their parts, but repeating `/x` on each pattern is easy to forget. On Perl 5.36, `use re '/x';` supplies that default within a lexical scope. This example keeps a readable setting parser in a dedicated block while leaving a later space-sensitive pattern unchanged.

```perl
use v5.36;

my $setting;
{
    use re '/x';

    $setting = qr/
        \A
        ([A-Z]+)    # Setting name
        [ ]* = [ ]* # Separator with optional spaces
        ([0-9]+)    # Nonnegative integer value
        \z
    /;
}

my @lines = ('PORT = 8080', 'RETRIES=0', 'BAD = many');

for my $line (@lines) {
    if ($line =~ $setting) {
        say "$1=$2";
    } else {
        say "Rejected: $line";
    }
}

my $literal_space = qr/\AA B\z/;
for my $text ('A B', 'AB') {
    my $result = $text =~ $literal_space ? 'match' : 'no match';
    say "Outside scope [$text]: $result";
}

```

Expected output:

```text
PORT=8080
RETRIES=0
Rejected: BAD = many
Outside scope [A B]: match
Outside scope [AB]: no match

```

The block containing `use re '/x';` establishes extended-mode defaults for patterns compiled within that lexical scope. This stable capability was introduced in Perl 5.14. Here, `qr//` compiles the setting pattern while that default applies, so indentation and comments make its structure readable without becoming input requirements.

The pattern uses `\A` and `\z` to require a complete-line match. Its two capturing groups extract an uppercase setting name and a nonnegative integer. Under `/x`, ordinary formatting spaces are ignored, so `[ ]*` explicitly accepts optional ASCII spaces around the equals sign. The comments beginning with `#` describe the adjacent pattern components rather than matching text.

The compiled pattern is assigned to `$setting`, which was declared outside the block. After the block ends, the loop still matches using that compiled pattern's extended-mode behavior. Successful matches expose the captured name and value through `$1` and `$2`; the invalid value follows the rejection branch. Those captures are used only after a successful match.

By contrast, `$literal_space` is compiled outside the pragma's scope. Its embedded space remains significant, so it accepts `A B` but rejects `AB`. The pragma therefore does not globally change every future match: the relevant flags are chosen when each pattern is compiled.

This parser deliberately accepts only uppercase ASCII names, decimal digits, and ordinary spaces around the separator. It does not accept tabs, signed values, or trailing text.

Example tested with Perl 5.36.

## More details

[lexical regular expression defaults in the Perl documentation](https://perldoc.perl.org/5.36.0/re).

[Read the perldelta behind this tip](https://perldoc.perl.org/5.36.0/perl5140delta).
