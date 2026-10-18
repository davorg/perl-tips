use v5.36;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Path::Tiny;
use PerlTips::Sandbox;

sub fails ($code, $pattern, $name) {
    my $ok = eval { $code->(); 1 };
    ok(!$ok, $name);
    like($@, $pattern, 'failure reported');
}

my $root = Path::Tiny->tempdir;
my $docker = $root->child('docker');
$docker->spew_utf8(<<'FAKE');
#!/usr/bin/env perl
use v5.36;
use JSON::PP;
open my $log, '>>', $ENV{PERL_TIPS_TEST_LOG} or die $!;
say {$log} encode_json(\@ARGV);
close $log;
exit 0 if $ARGV[0] eq 'rm';
my $input = do {local $/; <STDIN>};
if ($input =~ /bad syntax/) { print STDERR "syntax error\n"; exit 255 }
if ($input =~ /warning/) { print STDERR "warning\n" }
if ($input =~ /flood/) { print 'x' x 100_000; exit }
if ($input =~ /hang/) { sleep 30 }
print "ok\n";
FAKE
$docker->chmod(0755);
local $ENV{PERL_TIPS_TEST_LOG} = $root->child('commands');
my $sandbox = PerlTips::Sandbox->new(docker => "$docker");
is($sandbox->check('valid example'), "ok\n", 'stdout returned from runner');
my $commands = $root->child('commands')->slurp_utf8;
like($commands, qr/--network=none/, 'network disabled');
like($commands, qr/--read-only/, 'read-only root');
like($commands, qr/--user=65534:65534/, 'unprivileged user');
like($commands, qr/perl:5\.36/, 'fixed baseline interpreter');
unlike($commands, qr/OPENAI_API_KEY|--volume|--mount/, 'no secrets or host mounts');
fails(sub { $sandbox->check('bad syntax') }, qr/Example failed.*syntax error/s, 'compile failure rejected');
fails(sub { $sandbox->check('warning') }, qr/emitted warnings/, 'warnings rejected');
fails(sub { $sandbox->check('flood') }, qr/exceeded 64 KiB/, 'unbounded output rejected');
my $quick = PerlTips::Sandbox->new(docker => "$docker", timeout_seconds => 0.2);
fails(sub { $quick->check('hang') }, qr/timeout/i, 'nonterminating examples rejected');
like($root->child('commands')->slurp_utf8, qr/"rm","-f","perl-tips-/, 'failed containers cleaned up');

SKIP: {
    skip 'Set PERL_TIPS_CONTAINER_TEST=1 to test real Docker/Perl 5.36 isolation', 12
        unless $ENV{PERL_TIPS_CONTAINER_TEST};
    my $real = PerlTips::Sandbox->new;
    like($real->check("use v5.36;\nsay \$^V;\n"),
        qr/\Av5\.36\.\d+\n\z/, 'actual Perl 5.36 container');
    is($real->check("use v5.36;\nsub count { state \$n = 0; say ++\$n }\ncount(); count();\n"),
        "1\n2\n", 'standalone program compiles and runs');
    fails(sub { $real->check("use v5.36;\nuse feature 'say_underscore';\n") }, qr/Example failed/, 'invented feature rejected');
    fails(sub { $real->check("use v5.36;\nmy \$x = [1]; say \$x->\@*->[0];\n") }, qr/Example failed/, 'invalid postderef rejected');
    fails(sub { $real->check("use v5.36;\nwarn 'unexpected warning';\n") }, qr/emitted warnings/, 'runtime warnings rejected');
    fails(sub { $real->check("use v5.36;\nopen my \$fh, '>', '/escape' or die \$!;\n") }, qr/Example failed/, 'root filesystem is unwritable');
    is($real->check("use v5.36;\nsay exists \$ENV{OPENAI_API_KEY} ? 'leaked' : 'absent';\n"),
        "absent\n", 'API key absent');
    is($real->check("use v5.36;\nsay -e '/home/dave/git/perl-tips' ? 'mounted' : 'absent';\n"),
        "absent\n", 'repository absent');
}

done_testing;
