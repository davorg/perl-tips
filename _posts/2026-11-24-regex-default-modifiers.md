---
title: "Match exact tokens inside case-insensitive regular expressions"
feature: "regex-default-modifiers"
feature_name: "resetting embedded regex modifiers"
perl_version: "5.36"
description: "Learn about resetting embedded regex modifiers in Perl. (?^:...) resets the usual imsx flags and character-set mode to defaults for a group. Explicitly state..."
date: 2026-11-24
tags: ["regex-default-modifiers"]
layout: single
---

A record format may allow a case-insensitive prefix while requiring an exact, case-sensitive status token. Applying `/i` to the whole regular expression accidentally relaxes both parts. Rather than splitting validation into separate matches, use a local modifier-reset group to give the token its own matching rules. This keeps the format in one expression while making the exception visible where it matters.

```perl
use v5.36;

my @inputs = (
    'report:OK',
    'REPORT:OK',
    'report:ok',
    'Report:Ok',
    'report:OKextra',
);

for my $input (@inputs) {
    my $accepted = $input =~ /\A report: (?^:OK) \z/ix;
    say "$input => ", ($accepted ? 'accept' : 'reject');
}

```

Expected output:

```text
report:OK => accept
REPORT:OK => accept
report:ok => reject
Report:Ok => reject
report:OKextra => reject

```

The surrounding pattern uses `/ix`: `/i` makes matching case-insensitive, while `/x` allows formatting whitespace in the pattern. Consequently, the prefix accepts both lowercase and uppercase spellings. The embedded `(?^:OK)` group explicitly overrides the surrounding `/i`, so only uppercase `OK` satisfies that part. Lowercase or mixed-case status tokens fail even though the prefix remains flexible.

The reset also overrides the surrounding `/x` inside the group. There are deliberately no formatting spaces around `OK` within that group: spaces placed there would become literal matching requirements. Formatting spaces outside the group remain ignored. This boundary matters when expanding a readable pattern over several lines; indentation that is harmless outside the reset group can change what its contents match.

The anchors `\A` and `\z` require the entire input to match, which is why the final record fails despite containing an otherwise valid prefix and token. The conditional output makes each decision visible without depending on captures or external data.

Introduced and stable in Perl 5.14, `(?^:...)` resets the usual `imsx` flags and character-set mode to defaults for its group. It is broader than merely disabling case-insensitive matching, so use it when that complete local reset is intended. The surrounding modifiers resume after the group ends. This example targets Perl 5.36, and `use v5.36;` keeps strictness and warnings enabled.

Example tested with Perl 5.36.

## More details

[resetting embedded regex modifiers in the Perl documentation](https://perldoc.perl.org/5.36.0/perlre).

[Read the perldelta behind this tip](https://perldoc.perl.org/5.36.0/perl5140delta).
