---
title: "Apply Unicode rules without confusing bytes and characters"
feature: "unicode-strings"
perl_version: "5.36"
description: "Learn about unicode_strings in Perl. Uses Unicode string semantics; does not decode input or enable UTF-8 source."
date: 2026-10-18
tags: ["unicode-strings"]
layout: single
---

Case conversion and character classes should follow character meaning, not a string's internal representation. The `unicode_strings` feature supplies Unicode semantics, but it does not turn encoded bytes into characters. This program separates those responsibilities while processing an accented word.

```perl
use v5.36;
use feature 'unicode_strings';
use Encode qw(decode FB_CROAK);

binmode STDOUT, ':encoding(UTF-8)';

my $byte_valued_word = 'caf' . chr(0xE9);
my $encoded_input = pack 'C*', 0x63, 0x61, 0x66, 0xC3, 0xA9;
my $byte_count = length $encoded_input;
my $decoded_word = decode('UTF-8', $encoded_input, FB_CROAK);

say 'Encoded bytes: ', $byte_count;
say 'Decoded characters: ', length $decoded_word;
say 'Byte-valued uppercase: ', uc $byte_valued_word;
say 'Decoded uppercase: ', uc $decoded_word;
say 'Word characters only: ',
    ($byte_valued_word =~ /\A\w+\z/ ? 'yes' : 'no');

```

Expected output:

```text
Encoded bytes: 5
Decoded characters: 4
Byte-valued uppercase: CAFÉ
Decoded uppercase: CAFÉ
Word characters only: yes

```

The `unicode_strings` feature, introduced in Perl 5.12, selects Unicode string semantics. Perl 5.36's version declaration already enables it; the explicit feature declaration makes the dependency visible. Strictness and warnings remain enabled.

The first word is built from ASCII text and `chr(0xE9)`, the character U+00E9, LATIN SMALL LETTER E WITH ACUTE. Its values fit in a byte, but Unicode semantics still apply: `uc` produces U+00C9, and the anchored `\w` pattern accepts the entire word. This avoids treating character behavior as dependent on whether Perl happens to store a string in its internal UTF-8 form.

The second word starts as five explicitly supplied UTF-8 bytes. `Encode`'s `decode` converts them into four characters before case conversion. `FB_CROAK` makes invalid UTF-8 a decoding failure rather than silently accepting malformed data. Both character strings then uppercase identically.

The output encoding layer explicitly writes UTF-8, so the accented uppercase letters have a defined external representation. It handles output, not input decoding.

The important boundary is between bytes and characters. `unicode_strings` does not `decode` incoming data, identify an encoding, or enable UTF-8 source text. Applying character operations directly to encoded UTF-8 bytes would operate on the wrong values. Decode external text using its known encoding first. The program uses ASCII-only source and constructs the accented character numerically, so it needs no UTF-8 source declaration.

Example tested with Perl 5.36.

## More details

[unicode_strings in the Perl documentation](https://perldoc.perl.org/5.36.0/feature#The-'unicode_strings'-feature).
