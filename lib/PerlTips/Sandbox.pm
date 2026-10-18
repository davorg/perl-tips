package PerlTips::Sandbox;
use v5.36;
use Encode qw(encode decode FB_CROAK);
use IPC::Run qw(start run timeout);

sub new ($class, %args) {
    return bless {docker => 'docker', %args}, $class;
}

sub check ($self, $code, $perl_version = '5.36') {
    die "Unsupported example Perl version\n" unless $perl_version =~ /\A5\.(?:36|44)\z/;
    # Compilation can execute BEGIN/use blocks: never check on the host.
    # No host mounts or API credentials are passed into this container.
    my $name = "perl-tips-$$-" . int(rand(1_000_000_000));
    my @command = (
        $self->{docker}, 'run', '--rm', '--pull=never', '--name', $name,
        '--network=none', '--read-only', '--cap-drop=ALL',
        '--security-opt=no-new-privileges', '--pids-limit=32',
        '--memory=128m', '--memory-swap=128m', '--cpus=0.5',
        '--user=65534:65534', '--workdir=/tmp',
        '--tmpfs=/tmp:rw,noexec,nosuid,size=16m',
        '--env=LANG=C.UTF-8', '-i', "perl:$perl_version", 'perl', '-',
    );
    my $input = encode('UTF-8', $code);
    my ($stdout, $stderr) = ('', '');
    my $collect = sub ($target) {
        return sub ($chunk) {
            $$target .= $chunk;
            die "Example output exceeded 64 KiB\n" if length($$target) > 65_536;
        };
    };
    my $process;
    my $ok = eval {
        $process = start \@command, \$input, $collect->(\$stdout),
            $collect->(\$stderr), timeout($self->{timeout_seconds} // 15);
        $process->finish;
        die "Example failed: $stderr\n" if $process->result;
        die "Example emitted warnings: $stderr\n" if length $stderr;
        1;
    };
    if (!$ok) {
        my $error = $@ || "Example runner failed\n";
        eval { $process->kill_kill if $process };
        # Killing the docker client alone need not stop its container.
        my ($out, $err);
        eval { run [$self->{docker}, 'rm', '-f', $name], \undef,
            \$out, \$err, timeout(5) };
        die $error;
    }
    return decode('UTF-8', $stdout, FB_CROAK);
}

1;
