---
title: "Control byte order when encoding binary records"
feature: "pack-byte-order"
feature_name: "explicit byte order in binary templates"
perl_version: "5.36"
description: "Learn about explicit byte order in binary templates in Perl. > and < modifiers select big- or little-endian order for supported pack/unpack template types. U..."
date: 2026-11-27
tags: ["pack-byte-order"]
layout: single
---

Binary records can contain the right numbers yet become unreadable when the writer and reader disagree about byte order. For a portable layout, specify the order of each multibyte field instead of relying on the machine's native representation. Perl introduced the stable `>` and `<` modifiers for supported `pack` and `unpack` template types in Perl 5.10. This Perl 5.36 program builds a small record in both orders and shows what happens when a reader chooses incorrectly.

```perl
use v5.36;

my $record_id = 0x1234;
my $item_count = 0x01020304;

my $big_endian = pack('S> L>', $record_id, $item_count);
my $little_endian = pack('S< L<', $record_id, $item_count);

say 'Big-endian bytes:    ', unpack('H*', $big_endian);
say 'Little-endian bytes: ', unpack('H*', $little_endian);
say 'Record length: ', length($big_endian), ' bytes';

my ($decoded_id, $decoded_count) = unpack('S> L>', $big_endian);
printf "Decoded correctly: id=%u, count=%u\n", $decoded_id, $decoded_count;

my ($wrong_id, $wrong_count) = unpack('S< L<', $big_endian);
printf "Wrong byte order:  id=%u, count=%u\n", $wrong_id, $wrong_count;

```

Expected output:

```text
Big-endian bytes:    123401020304
Little-endian bytes: 341204030201
Record length: 6 bytes
Decoded correctly: id=4660, count=16909060
Wrong byte order:  id=13330, count=67305985

```

The record contains an unsigned 16-bit identifier followed by an unsigned 32-bit count. The fixed-width templates `S` and `L` describe those fields. Appending `>` selects big-endian order, putting each field's most significant byte first; appending `<` selects little-endian order, putting its least significant byte first. Spaces separate the template fields for readability and do not add bytes.

The two `pack` calls encode identical values with different byte orders. Notice that little-endian order reverses the bytes within each field, not across the entire record: the identifier still comes before the count. Both records occupy six bytes.

Using `unpack('H*', ...)` converts the binary strings into printable hexadecimal, with two hexadecimal digits per byte. This avoids sending raw binary to the terminal and makes the layout easy to inspect.

The matching `unpack('S> L>', ...)` recovers the original numbers. Decoding those same bytes with the opposite modifiers produces different, still valid numbers without diagnosing the mismatch. The final line therefore demonstrates why byte order must come from the format specification rather than guesswork.

These modifiers apply only to supported template types. Keep values within the chosen fields' unsigned ranges, and validate record lengths separately when handling real input; explicit byte order is not input validation.

Example tested with Perl 5.36.

## More details

[explicit byte order in binary templates in the Perl documentation](https://perldoc.perl.org/5.36.0/perlpacktut).

[Read the perldelta behind this tip](https://perldoc.perl.org/5.36.0/perl5100delta).
