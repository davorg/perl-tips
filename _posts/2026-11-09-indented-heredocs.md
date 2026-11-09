---
title: "Indent multiline templates without indenting their output"
feature: "indented-heredocs"
feature_name: "indented here-documents"
perl_version: "5.36"
description: "Learn about indented here-documents in Perl. <<~ permits an indented closing delimiter and strips its matching leading whitespace from every content line. Li..."
date: 2026-11-09
tags: ["indented-heredocs"]
layout: single
---

Multiline messages often belong inside a subroutine, but ordinary here-documents can force an awkward choice: put the closing delimiter against the left margin, or carry source indentation into the generated text. Indented here-documents, written with `<<~`, let you keep the message aligned with surrounding code while controlling the whitespace callers receive. Here, a deployment notice preserves indentation for its detail lines without adding spaces before its heading.

```perl
use v5.36;

sub deployment_notice {
    my ($service, $port) = @_;

    return <<~"NOTICE";
        Deployment summary
          Service: $service
          Port: $port
        Status: ready
        NOTICE
}

my $notice = deployment_notice('inventory', 8080);
print $notice;
print "--- end of notice ---\n";

```

Expected output:

```text
Deployment summary
  Service: inventory
  Port: 8080
Status: ready
--- end of notice ---

```

The `<<~` form allows the closing delimiter to be indented. Its leading whitespace establishes the indentation removed from every content line. In this program, the closing `NOTICE` delimiter has eight leading spaces, so Perl removes eight spaces from each line of the notice. The heading and status become flush left, while the service and port retain their two additional spaces.

The double-quoted delimiter in `<<~"NOTICE"` gives the body double-quoted string behavior: `$service` and `$port` are interpolated when the subroutine builds the string. The closing delimiter is not part of that string. The newline after the last content line is retained, which is why the end marker printed afterward appears on its own line without an extra newline being added first.

Every content line must have the required indentation. Use a consistent whitespace prefix rather than mixing tabs and spaces and relying on their visual alignment. Intentional indentation belongs after that shared prefix; it survives the stripping operation. This is not automatic dedenting based on whichever content line happens to be least indented.

Indented here-documents were introduced and became stable in Perl 5.26. This program targets Perl 5.36 with `use v5.36;`, which keeps strictness and warnings enabled. No experimental feature switch or additional module is needed.

Example tested with Perl 5.36.

## More details

[indented here-documents in the Perl documentation](https://perldoc.perl.org/5.36.0/perlop).

[Read the perldelta behind this tip](https://perldoc.perl.org/5.36.0/perl5260delta).
