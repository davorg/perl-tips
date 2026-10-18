---
title: "Read several input files as one stream"
feature: "stacked-files"
date: 2025-10-06
tags: [stacked files]
layout: single
---

Have you ever needed to quickly iterate over multiple input files in a Perl script as if they were concatenated into a single stream? This is a common scenario when dealing with log files split into parts or multiple data files that need similar processing. The "stacked files" feature in Perl offers a powerful yet straightforward solution to this problem.

Let's say you have a directory full of data files named `data1.txt`, `data2.txt`, ..., `dataN.txt`, and you want to process them consecutively. Instead of writing a tedious loop to open, read, and close each file, you can take advantage of Perl's ability to handle stacked files with a simple command-line trick.

Here’s an example of how you might write a script to sum all the numbers in all files you provide as arguments:

```perl
use strict;
use warnings;

my $total_sum = 0;

while (<>) {
    chomp;
    $total_sum += $_ if /^\d+$/;  # Add to total if $_ contains a number
}

print "The total sum is: $total_sum\n";
```

**Explanation:**

1. The `while (<>)` loop processes each line from the input files one-by-one, as if from a single continuous file. The `<>` operator is key here; it reads from each file provided to the script as an argument on the command line.

2. Within the loop, `chomp` is used to remove the newline character from the end of each line.

3. A simple regex checks if the line is a number (`/^\d+$/`) and, if true, adds it to `$total_sum`.

4. Finally, the total sum is printed after processing all lines in all files.

**More Details:**

For a deeper dive into the `<>` filehandle and its capabilities, check out the official Perl documentation on I/O operators [here](https://perldoc.perl.org/perlop#I/O-Operators). This page covers all you need to make efficient use of stacked files in Perl.
