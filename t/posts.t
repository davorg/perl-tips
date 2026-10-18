use v5.36;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Path::Tiny;
use PerlTips::Generator;

# Check the current articles too, so manual prose edits cannot reintroduce
# variable/emphasis or operator/table bugs unnoticed by the regular checks.
my $posts_directory = path("$FindBin::Bin/../_posts");
my @posts = sort { $a cmp $b } $posts_directory->children(qr/\.md$/);
plan skip_all => 'No posts to check' unless @posts;
for my $post (@posts) {
    subtest $post->basename => sub {
        my $text = $post->slurp_utf8;
        my ($body) = $text =~ /\A---\r?\n.*?^---\r?\n(.*)\z/ms;
        ok(defined($body), 'article body follows front matter');
        return unless defined $body;
        # The app supplies documentation links after this heading. Their URLs
        # and link labels are not the generated introduction/explanation.
        ($body) = split /^## More details\s*$/m, $body, 2;
        $body =~ s/^```(?:perl|text)\s*\n.*?^```[ \t]*$//msg;
        my $ok = eval { PerlTips::Generator::_check_prose_format($body, 'Post prose'); 1 };
        ok($ok, 'inline Perl syntax is protected from Markdown') or diag $@;
    };
}

done_testing;
