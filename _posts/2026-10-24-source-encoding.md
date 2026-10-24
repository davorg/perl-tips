---
title: "Keep Perl source ASCII while handling Unicode text"
feature: "source-encoding"
feature_name: "explicit source encoding"
perl_version: "5.44"
description: "Learn about explicit source encoding in Perl. source::encoding accepts ascii or utf8, checking source text rather than decoding external input. The utf8 form..."
date: 2026-10-24
tags: ["source-encoding"]
layout: single
---

A project may require ASCII-only Perl source to simplify reviews and prevent accidentally pasted non-ASCII characters, while still needing Unicode product names at runtime. Those requirements are compatible. An explicit source-encoding policy separates what developers may type directly into a program from the characters that program can construct, process, and print. This inventory report keeps its source entirely ASCII while displaying accented names.

```perl
use v5.44;
use source::encoding 'ascii';
use strict;
use warnings;

binmode STDOUT, ':encoding(UTF-8)';

my @products = (
    { name => "caf\x{E9}",     stock => 3 },
    { name => "pi\x{F1}ata",   stock => 0 },
    { name => "tea",           stock => 5 },
);

say 'Inventory (Unicode names, ASCII source):';
for my $product (@products) {
    my $name = $product->{name};
    my $characters = length $name;
    say "$name: $product->{stock} in stock; $characters characters";
}

```

Expected output:

```text
Inventory (Unicode names, ASCII source):
café: 3 in stock; 4 characters
piñata: 0 in stock; 6 characters
tea: 5 in stock; 3 characters

```

The `source::encoding` pragma was introduced in Perl 5.42 and has been stable since that release. It accepts `ascii` or `utf8` and checks source text, rather than decoding external input. Here, `use source::encoding 'ascii';` makes the source policy explicit. Keeping that declaration near the top makes the restriction visible during review, instead of leaving readers to infer the intended encoding from the file's contents.

The inventory names contain Unicode characters, but their source representations use ASCII-only `\x{...}` escapes. Perl constructs the corresponding characters in memory. The loop preserves the input order and uses `length` to report character counts: the accented letters each count as one character in these names. ASCII source therefore does not mean ASCII-only application data.

Output encoding is a separate decision. `binmode STDOUT, ':encoding(UTF-8)';` explicitly encodes the printed names as UTF-8. The source pragma neither configures that output layer nor chooses how files, sockets, or other external input should be decoded.

The alternative `utf8` form is equivalent to `use utf8;` and permits UTF-8 source text. When using that policy, put the encoding pragma on its own line before the first line containing non-ASCII source. This program deliberately retains the `ascii` policy instead: it demonstrates how to enforce an ASCII source convention without giving up Unicode strings or correctly encoded output.

Example tested with Perl 5.44.

## More details

[explicit source encoding in the Perl documentation](https://perldoc.perl.org/5.44.0/source::encoding).

[Read the perldelta behind this tip](https://perldoc.perl.org/5.44.0/perl5420delta).
