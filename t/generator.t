use v5.36;
use utf8;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Fcntl qw(:flock);
use JSON::PP qw(encode_json decode_json);
use Mojo::Transaction::HTTP;
use OpenAPI::Client::OpenAI;
use Path::Tiny;
use PerlTips::Generator;

my $date = '2026-10-18';
my $json = JSON::PP->new;

sub fixture {
    my $root = Path::Tiny->tempdir;
    $root->child('_posts')->mkpath;
    $root->child('data')->mkpath;
    path("$FindBin::Bin/../data/topics.json")->copy($root->child('data/topics.json'));
    $root->child('data/covered-features.json')->spew_raw('[]');
    return $root;
}

sub draft {
    return {
        title => 'Keep a private counter between subroutine calls',
        introduction => 'Keep a private count across calls.',
        code => "use v5.36;\nsub count { state \$n = 0; say ++\$n }\ncount(); count();\n",
        expected_stdout => "1\n2\n",
        explanation => 'The state variable retains its value between calls.',
    };
}

sub approved { return {approved => JSON::PP::true, issues => []} }

sub response ($value, %args) {
    my $tx = Mojo::Transaction::HTTP->new;
    $tx->res->code($args{status} // 200);
    $tx->res->headers->content_type('application/json');
    $tx->res->body(encode_json({choices => [{finish_reason => $args{finish} // 'stop', message => {
        content => exists($args{content}) ? $args{content} : $json->encode($value),
        refusal => $args{refusal},
    }}]}));
    return $tx;
}

sub generator ($root, $queue, $calls, $runner = sub { "1\n2\n" }) {
    return PerlTips::Generator->new(root => $root, run_example => $runner,
        request => sub ($body) {
            # Neither output may change before the final approval.
            die 'Premature post write' if $root->child('_posts')->children;
            push @$calls, decode_json(encode_json($body));
            die 'Unexpected API call' unless @$queue;
            return shift @$queue;
        });
}

sub fails ($code, $pattern, $description) {
    my $ok = eval { $code->(); 1 };
    ok(!$ok, $description);
    like($@, $pattern, 'useful rejection reason');
}

sub unchanged ($root, $before = '[]') {
    is(scalar($root->child('_posts')->children), 0, 'no post written');
    is($root->child('data/covered-features.json')->slurp_raw, $before, 'covered list unchanged');
}

subtest 'valid generation, exact rendered example and trusted link' => sub {
    my $root = fixture;
    my (@calls, @queue) = ();
    @queue = (response(draft()), response(approved()));
    my $post = generator($root, \@queue, \@calls)->generate($date);
    ok($post->is_file, 'post created after approval');
    my $text = $post->slurp_utf8;
    like($text, qr/^title: "Keep a private counter between subroutine calls"$/m, 'generated reader-facing title');
    like($text, qr/^feature: "state"$/m, 'feature id kept separately');
    unlike($text, qr/^seo_title:/m, 'search and social titles inherit the reader-facing title');
    is($post->basename, "$date-state.md", 'headline does not change the URL slug');
    like($text, qr/^description: "Learn about state in Perl\. Persistent lexical variables; initialization runs once\."$/m,
        'description comes from reviewed topic facts');
    like($text, qr/```perl\n\Q@{[draft()->{code}]}\E\n```/, 'validated code rendered verbatim');
    like($text, qr/```text\n1\n2\n/, 'validated output shown');
    like($text, qr{https://perldoc\.perl\.org/5\.36\.0/feature}, 'trusted reference');
    is_deeply(decode_json($root->child('data/covered-features.json')->slurp_raw), ['state'], 'canonical id recorded');
    is(scalar @calls, 2, 'writer plus independent review');
    ok($calls[0]{response_format}{json_schema}{strict}, 'strict structured output requested');
    is($calls[1]{response_format}{json_schema}{name}, 'perl_tip_review', 'separate review schema');
};

subtest 'incorrect output is repaired using feedback, before writing' => sub {
    my $root = fixture;
    my $wrong = draft(); $wrong->{expected_stdout} = "wrong\n";
    my @queue = (response($wrong), response(draft()), response(approved()));
    my @calls;
    my $post = generator($root, \@queue, \@calls)->generate($date);
    ok($post->exists, 'repaired draft saved');
    like($calls[1]{messages}[-1]{content}, qr/stdout does not match/, 'concrete feedback sent to writer');
    is(scalar @calls, 3, 'bad output bypasses reviewer');
};

subtest 'incorrect prose must pass a fresh technical review after repair' => sub {
    my $root = fixture;
    my @queue = (response(draft()), response({approved => JSON::PP::false,
        issues => ['The explanation claims named parameters.']}),
        response(draft()), response(approved()));
    my @calls;
    ok(generator($root, \@queue, \@calls)->generate($date)->exists, 'approved repair saved');
    like($calls[2]{messages}[-1]{content}, qr/named parameters/, 'review feedback sent to writer');
    is(scalar @calls, 4, 'each candidate reviewed independently');
};

subtest 'three broken examples exhaust retries without changing content' => sub {
    my $root = fixture;
    my @queue = map { response(draft()) } 1..3;
    my @calls;
    fails(sub { generator($root, \@queue, \@calls, sub { die "syntax error\n" })->generate($date) },
        qr/No valid article after 3 attempts.*syntax error/s, 'broken code rejected');
    is(scalar @calls, 3, 'retry bound enforced');
    unchanged($root);
};

subtest 'review never approves a draft with outstanding issues' => sub {
    my $root = fixture;
    my @queue = map { (response(draft()), response({approved => JSON::PP::true, issues => ['Still wrong']})) } 1..3;
    my @calls;
    fails(sub { generator($root, \@queue, \@calls)->generate($date) }, qr/Technical review rejected/, 'inconsistent approval rejected');
    unchanged($root);
};

my $missing_title = draft();
delete $missing_title->{title};
for my $case (
    ['HTTP error', {status => 429}, qr/request failed/],
    ['truncation', {finish => 'length'}, qr/truncated/],
    ['filter interruption', {finish => 'content_filter'}, qr/interrupted/],
    ['refusal', {refusal => 'Cannot comply'}, qr/refused/],
    ['empty content', {content => ''}, qr/empty content/],
    ['invalid JSON', {content => 'not json'}, qr/invalid JSON/],
    ['missing required field', {content => '{}'}, qr/does not match/],
    ['missing reader-facing title', {content => $json->encode($missing_title)}, qr/does not match/],
    ['unexpected field', {content => $json->encode({%{draft()}, seo_title => 'cor'})}, qr/does not match/],
) {
    subtest $case->[0] => sub {
        my $root = fixture;
        my @queue = (response(draft(), %{$case->[1]}));
        my @calls;
        fails(sub { generator($root, \@queue, \@calls)->generate($date) }, $case->[2], 'bad API response rejected');
        unchanged($root);
    };
}

subtest 'Unicode survives JSON handling and rendering' => sub {
    my $root = fixture;
    my $draft = draft();
    $draft->{explanation} = 'A counter for café visits.';
    $draft->{expected_stdout} = "café\n";
    my @queue = (response($draft), response(approved()));
    my @calls;
    my $post = generator($root, \@queue, \@calls, sub { "café\n" })->generate($date);
    like($post->slurp_utf8, qr/café/, 'UTF-8 text preserved');
};

subtest 'title punctuation survives front matter without changing identity' => sub {
    my $root = fixture;
    my $draft = draft();
    $draft->{title} = q{Count calls with a "private" counter: Perl's state};
    my @queue = (response($draft), response(approved()));
    my @calls;
    my $post = generator($root, \@queue, \@calls)->generate($date);
    my ($encoded_title) = $post->slurp_utf8 =~ /^title: (.+)$/m;
    is($json->decode($encoded_title), $draft->{title}, 'quotes, colon and apostrophe preserved');
    is($post->basename, "$date-state.md", 'URL uses canonical feature id');
    is_deeply(decode_json($root->child('data/covered-features.json')->slurp_raw),
        ['state'], 'covered list stores feature id, not the headline');
};

for my $case (
    ['bare feature label', 'title', 'state', qr/not just the feature label/],
    ['old SEO label', 'title', 'State in Perl', qr/not just the feature label/],
    ['short title', 'title', 'Count calls', qr/at least four words/],
    ['long title', 'title', 'Count calls with ' . ('a' x 100), qr/at most 100 characters/],
    ['multiline title', 'title', "Count calls\nwithout a global counter", qr/plain text on one line/],
    ['HTML title', 'title', 'Keep a <b>private counter</b> between calls', qr/plain text on one line/],
    ['Markdown title', 'title', 'Keep a **private counter** between calls', qr/plain text on one line/],
    ['missing baseline', 'code', "say 'x';\n", qr/start with use/],
    ['disabled warnings', 'code', "use v5.36;\nno warnings;\n", qr/keep strict and warnings/],
    ['extra code fence', 'explanation', "```perl\nuse feature 'cor';\n```", qr/fences/],
    ['invented URL', 'explanation', 'See https://perldoc.perl.org/features/cor', qr/URLs/],
) {
    subtest $case->[0] => sub {
        my $root = fixture;
        my $draft = draft(); $draft->{$case->[1]} = $case->[2];
        my @queue = map { response($draft) } 1..3;
        my @calls;
        fails(sub { generator($root, \@queue, \@calls, sub { die 'Runner should not be called' })->generate($date) },
            $case->[3], 'draft rejected before executing it');
        unchanged($root);
    };
}

subtest 'titles are reviewed and repaired before the article is saved' => sub {
    my $root = fixture;
    my $generic = draft();
    $generic->{title} = 'Discover the state feature in Perl';
    my @queue = (response($generic), response({approved => JSON::PP::false,
        issues => ['The title should explain the benefit of counting calls.']}),
        response(draft()), response(approved()));
    my @calls;
    my $post = generator($root, \@queue, \@calls)->generate($date);
    like($post->slurp_utf8, qr/^title: "Keep a private counter between subroutine calls"$/m,
        'repaired title saved');
    like($calls[2]{messages}[-1]{content}, qr/title should explain the benefit/, 'title feedback sent to writer');
    my $reviewed = $json->decode($calls[3]{messages}[-1]{content});
    is($reviewed->{draft}{title}, draft()->{title}, 'final headline included in fresh review');
    is($reviewed->{topic}{id}, 'state', 'topic identity stays fixed across headline repair');
};

subtest 'catalogue prevents aliases or invented topics bypassing exclusions' => sub {
    my $root = fixture;
    my $gen = PerlTips::Generator->new(root => $root, request => sub {}, run_example => sub {});
    my $topics = decode_json($root->child('data/topics.json')->slurp_raw);
    my @excluded = map { $_->{id} eq 'signatures' ? 'sub signatures' : $_->{id} } @$topics;
    push @excluded, 'say_underscore', 'cor';
    fails(sub { $gen->_topic(\@excluded) }, qr/No uncovered topics/, 'known aliases excluded and no new topics invented');
    is($gen->_topic([])->{id}, 'state', 'selection follows catalogue order');
    $topics->[1]{aliases} = ['state'];
    $root->child('data/topics.json')->spew_raw(encode_json($topics));
    fails(sub { $gen->_topic([]) }, qr/Ambiguous/, 'ambiguous aliases fail closed');
};

for my $bad ('not json', '{}', '[null]', '[[]]', '[""]') {
    subtest "invalid covered state: $bad" => sub {
        my $root = fixture;
        $root->child('data/covered-features.json')->spew_raw($bad);
        my (@queue, @calls);
        fails(sub { generator($root, \@queue, \@calls)->generate($date) },
            qr/JSON|array of nonempty strings/, 'bad state rejected before API call');
        is(scalar @calls, 0, 'no API call');
        unchanged($root, $bad);
    };
}

subtest 'invalid dates and existing posts cannot be overwritten' => sub {
    my $root = fixture;
    my (@queue, @calls);
    my $gen = generator($root, \@queue, \@calls);
    fails(sub { $gen->generate('../x') }, qr/Date must/, 'unsafe date rejected');
    fails(sub { $gen->generate('2026-02-30') }, qr/Invalid calendar/, 'impossible date rejected');
    $root->child("_posts/$date-existing.md")->spew_utf8('keep me');
    fails(sub { $gen->generate($date) }, qr/already exists/, 'duplicate day rejected');
    is($root->child("_posts/$date-existing.md")->slurp_utf8, 'keep me', 'old post untouched');
    is(scalar @calls, 0, 'no API calls');
};

subtest 'concurrent local runs cannot both generate' => sub {
    my $root = fixture;
    open my $lock, '>>', $root->child('data/.generate.lock') or die $!;
    flock($lock, LOCK_EX | LOCK_NB) or die $!;
    my (@queue, @calls);
    fails(sub { generator($root, \@queue, \@calls)->generate($date) }, qr/Another generator/, 'lock held');
    unchanged($root);
};

subtest 'feature-list write failures roll back the approved post' => sub {
    my $root = fixture;
    my @queue = (response(draft()), response(approved()));
    my @calls;
    my $original = \&Path::Tiny::spew_raw;
    {
        no warnings 'redefine';
        local *Path::Tiny::spew_raw = sub ($file, @args) {
            die "Simulated disk error\n" if "$file" eq "$root/data/covered-features.json";
            return $original->($file, @args);
        };
        fails(sub { generator($root, \@queue, \@calls)->generate($date) },
            qr/Simulated disk error/, 'save failure reported');
    }
    unchanged($root);
};

subtest 'installed OpenAPI client accepts both request schemas without network' => sub {
    my $root = fixture;
    my @queue = (response(draft()), response(approved()));
    my @calls;
    generator($root, \@queue, \@calls)->generate($date);
    local $ENV{OPENAI_API_KEY} = 'test-key-never-sent';
    my $started = 0;
    {
        no warnings 'redefine';
        local *Mojo::UserAgent::start = sub ($ua, $tx) {
            $started++;
            $tx->res->code(200);
            return $tx;
        };
        my $client = OpenAPI::Client::OpenAI->new;
        for my $body (@calls) {
            my $tx = $client->createChatCompletion({body => $body});
            ok(!$tx->error, 'request accepted by installed API specification')
                or diag explain $tx->error;
            is_deeply($tx->req->json->{response_format}, $body->{response_format},
                'structured response format preserved');
        }
    }
    is($started, 2, 'both requests reached the stub transport');
};

done_testing;
