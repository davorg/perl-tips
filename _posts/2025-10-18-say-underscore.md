---
title: "Print each message on its own line"
feature: "say-underscore"
date: 2025-10-18
tags: [say_underscore]
layout: single
---

In the world of Perl, developers often find themselves needing to print data for debugging or logging purposes. Traditionally, this involves using the `print` function, which can be cumbersome due to its requirement for explicitly handling newline characters. This is particularly evident when you quickly need to output multiple lines of strings or variables. Here's where Perl's `say_underscore` feature comes into play, providing a streamlined way to print output with implicit newline handling.

Consider a scenario where you're debugging a list of error messages. Using `say_underscore`, you can enhance readability and maintainability without repetitive and manual newline management.

Here's a sample code snippet illustrating how `say_underscore` can simplify this task:

```perl
use feature 'say_underscore';

my @errors = ('File not found', 'Access denied', 'Unknown error');
foreach (@errors) {
    say_ _;  # Automatically appends a newline
}
```

In the above code, we introduce the `say_underscore` feature, which becomes available when you include `use feature 'say_underscore';`. This feature allows us to use `say_ _` within our loop. The underscore represents the default Perl variable `$_`, which in a `foreach` loop contains the current element of the list being iterated. When using `say_ _`, each element of the `@errors` array is printed with an appended newline, much like how `say` enhances `print` with automatic newline functionality. It provides a succinct and efficient means to output each error message on a new line.

For more details on using `say_underscore`, including nuances and additional examples, visit the official Perl documentation page: [perldoc.perl.org](https://perldoc.perl.org). You'll find comprehensive explanations on many modern Perl features and how they can be leveraged to write more concise and readable code.
