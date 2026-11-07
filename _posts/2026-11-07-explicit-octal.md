---
title: "Make permission masks unmistakable with explicit octal literals"
feature: "explicit-octal"
feature_name: "explicit octal literals"
perl_version: "5.36"
description: "Learn about explicit octal literals in Perl. 0o prefixes make octal literals explicit; oct also accepts that prefix. Demonstrate conversion with fixed numeri..."
date: 2026-11-07
tags: ["explicit-octal"]
layout: single
---

Permission-style bitmasks are easier to review when their numeric base is unmistakable. A leading zero can be overlooked, leaving readers to interpret an octal constant as decimal. Use explicit octal literals to make that intent visible, then display both representations when checking configuration values. This example inspects fixed permission masks entirely in memory.

```perl
use v5.36;

my $read_mask  = 0o444;
my $write_mask = 0o222;
my $exec_mask  = 0o111;

my @settings = (
    ['private', 0o600],
    ['shared',  0o640],
    ['public',  0o755],
);

say 'Label    Octal  Decimal  Read  Write  Execute';
for my $setting (@settings) {
    my ($label, $mode) = @$setting;
    printf "%-8s %04o   %3d      %03o   %03o    %03o\n",
        $label, $mode, $mode,
        $mode & $read_mask,
        $mode & $write_mask,
        $mode & $exec_mask;
}

my $text = '0o640';
my $parsed = oct($text);
printf "Parsed %s: decimal %d; matches shared: %s\n",
    $text, $parsed, ($parsed == $settings[1][1] ? 'yes' : 'no');

```

Expected output:

```text
Label    Octal  Decimal  Read  Write  Execute
private  0600   384      400   200    000
shared   0640   416      440   200    000
public   0755   493      444   200    111
Parsed 0o640: decimal 416; matches shared: yes

```

The `0o` prefix explicitly marks a numeric literal as octal. This syntax was introduced in Perl 5.34 and was stable starting in that release. The program targets Perl 5.36; `use v5.36;` keeps strict checking and warnings enabled.

Each entry in `@settings` pairs a descriptive label with a numeric value written in octal. These are ordinary numbers, not strings carrying a special octal type. Consequently, `printf` can display the same `$mode` in octal with `%04o` and in decimal with `%d`. The field widths and zero padding make the representations easy to compare.

The three masks isolate the read, write, and execute positions across the owner, group, and other permission fields. Bitwise `&` retains only bits present in both operands. Printing those results with `%03o` preserves their positions: the shared setting has read bits `440`, write bits `200`, and no execute bits. These columns are masks, not counts of permitted users.

The final conversion starts with the fixed string `'0o640'`. The `oct` function accepts that explicit prefix and returns the corresponding numeric value. Comparing it with the shared setting using `==` confirms that parsing the string and writing the literal produce the same number.

Use literals for constants known when writing the program, and `oct` when converting octal text. This example uses only valid, fixed input; it does not demonstrate input validation. Nothing calls `chmod` or accesses a file, so no real permissions change.

Example tested with Perl 5.36.

## More details

[explicit octal literals in the Perl documentation](https://perldoc.perl.org/5.36.0/perldata).

[Read the perldelta behind this tip](https://perldoc.perl.org/5.36.0/perl5340delta).
