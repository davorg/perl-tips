---
title: "Reuse quoted-value patterns without renumbering their backreferences"
feature: "relative-backreferences"
feature_name: "relative regular expression backreferences"
perl_version: "5.36"
description: "Learn about relative regular expression backreferences in Perl. \\g{-1} refers to the most recently opened capturing group. It can keep embedded patterns inde..."
date: 2026-11-21
tags: ["relative-backreferences"]
layout: single
---

Reusable regular expressions become fragile when a fragment refers to a capture by its absolute number. Adding a capture earlier in the surrounding expression can change which group the reference names. Relative backreferences avoid that dependency. Here, a quoted-value fragment checks that opening and closing quotes agree, even after a setting-name capture is placed before it.

```perl
use v5.36;

my $quoted = qr/(["'])[^"'\n]*\g{-1}/;

my @records = (
    q{color="blue"},
    q{status='ready'},
    q{empty=""},
    q{broken="blue'},
    q{extra="blue"tail},
);

for my $record (@records) {
    if ($record =~ /\A([a-z]+)=$quoted\z/) {
        say "$record => accepted (key: $1)";
    } else {
        say "$record => rejected";
    }
}

```

Expected output:

```text
color="blue" => accepted (key: color)
status='ready' => accepted (key: status)
empty="" => accepted (key: empty)
broken="blue' => rejected
extra="blue"tail => rejected

```

The reusable fragment is compiled with `qr//`. Its first component, `(["'])`, captures either a double quote or a single quote. The character class `[^"'\n]*` consumes zero or more characters other than either quote or a newline. Finally, `\g{-1}` matches the exact text captured by the most recently opened capturing group: the opening delimiter. An empty value therefore succeeds, while mismatched delimiters fail.

The enclosing expression adds `([a-z]+)` before the fragment to capture the setting name. That earlier capture becomes `$1`, which the program prints for accepted records. The fragment's delimiter capture now follows it, but the relative backreference still identifies the correct group. An absolute numbered reference would instead depend on the capture's position in the complete expression. This is especially useful when a shared fragment appears inside several larger validators with different capture layouts.

The anchors `\A` and `\z` require the entire record to match. Consequently, the trailing text in the final record is rejected rather than silently ignored.

Relative backreferences were introduced in Perl 5.10 and have been stable since that release. This program targets Perl 5.36; `use v5.36;` keeps strictness and warnings enabled.

Keep the fragment's capture layout in mind when editing it. Adding another capturing group before `\g{-1}` changes which group that reference identifies. This deliberately narrow validator also excludes both quote characters from values and does not implement escaped quotes or multiline values.

Example tested with Perl 5.36.

## More details

[relative regular expression backreferences in the Perl documentation](https://perldoc.perl.org/5.36.0/perlre).

[Read the perldelta behind this tip](https://perldoc.perl.org/5.36.0/perl5100delta).
