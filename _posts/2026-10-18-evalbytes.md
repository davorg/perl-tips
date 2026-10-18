---
title: "Evaluate trusted Perl source with byte-oriented semantics"
feature: "evalbytes"
description: "Learn about evalbytes in Perl. Evaluates a byte string as Perl; never evaluate untrusted input."
date: 2026-10-18
tags: ["evalbytes"]
layout: single
---

When an application deliberately stores trusted Perl code as bytes, its evaluation should preserve that byte-oriented contract. evalbytes provides that behavior explicitly. This example evaluates a fixed UTF-8 source fragment whose own use utf8 declaration controls how its non-ASCII string literal is parsed, then verifies the resulting character count.

```perl
use v5.36;

binmode STDOUT, ':encoding(UTF-8)' or die "Cannot set STDOUT encoding: $!";

my $name_bytes = pack 'C*', 0x63, 0x61, 0x66, 0xC3, 0xA9;
my $source = q{use utf8; my $label = "}
    . $name_bytes
    . q{"; [ $label, length($label) ];};

my $result = evalbytes $source;
my $error = $@;
die "Embedded source failed: $error" if length $error;

my ($label, $characters) = @$result;
printf "Label: %s\n", $label;
printf "Characters: %d\n", $characters;
printf "Final code point: U+%04X\n", ord substr($label, -1);

```

Expected output:

```text
Label: café
Characters: 4
Final code point: U+00E9

```

The evalbytes feature was introduced in Perl 5.16. This program targets Perl 5.36, whose version declaration enables it along with strict and warnings. evalbytes evaluates a byte string as Perl source, rather than treating the input as already decoded character text.

The setup constructs the UTF-8 bytes for café explicitly with pack. This keeps the standalone program itself ASCII-only and makes the byte representation visible: the final character occupies two bytes, C3 A9. Those bytes are inserted into a fixed, trusted Perl source template.

Inside that template, use utf8 tells the Perl parser to interpret the source as UTF-8. Consequently, the string literal becomes four characters, not five separate byte values. The evaluated source finishes with an array reference containing the decoded label and its character count; that final expression becomes the result of evalbytes.

The caller saves $@ immediately after evaluation and checks it before using the result. A compilation error or runtime exception in the embedded source would therefore stop the program instead of letting it dereference an invalid result. STDOUT is explicitly configured for UTF-8 so the decoded label prints correctly.

This is execution, not a general-purpose text decoder or a sandbox. Never evaluate untrusted input. In particular, interpolating externally supplied text into this template would introduce code-injection risks; the example is safe because every source byte is fixed within the program.

## More details

[evalbytes in the Perl documentation](https://perldoc.perl.org/5.36.0/feature#The-'unicode_eval'-and-'evalbytes'-features).
