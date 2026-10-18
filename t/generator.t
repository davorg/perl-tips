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

subtest 'bare prose pipes are repaired before execution, review or saving' => sub {
    my $root = fixture;
    my $wrong = draft();
    $wrong->{introduction} = 'Using logical-or, ||, would replace zero.';
    my $fixed = draft();
    $fixed->{introduction} = 'Using logical-or, `||`, would replace zero.';
    my @queue = (response($wrong), response($fixed), response(approved()));
    my @calls;
    my $runs = 0;
    my $post = generator($root, \@queue, \@calls, sub { ++$runs; "1\n2\n" })->generate($date);
    like($post->slurp_utf8, qr/Using logical-or, `\|\|`, would replace zero\./,
        'correct inline code saved verbatim');
    like($calls[1]{messages}[-1]{content}, qr/introduction.*pipe.*backtick/,
        'formatting feedback sent to writer');
    is($runs, 1, 'malformed prose rejected before running its example');
    is(scalar @calls, 3, 'only repaired draft reaches independent review');
    my $reviewed = $json->decode($calls[2]{messages}[-1]{content});
    is($reviewed->{draft}{introduction}, $fixed->{introduction}, 'review sees repaired formatting');
};

subtest 'inline code protects Perl syntax without changing example or stdout' => sub {
    my $root = fixture;
    my $draft = draft();
    $draft->{introduction} = q{Use `||`, `|`, `|=`, `//`, `$_`, `@_`, `$"`, `%counts`, `$next_id`, `->@*`, `__SUB__`, `unicode_strings` and `\w` literally.};
    $draft->{explanation} = q{Two backticks can quote a backtick: `` q`a|b` ``.};
    $draft->{code} = "use v5.36;\nsub count { state \$n = 0; say ++\$n, '|' }\ncount(); count();\n";
    $draft->{expected_stdout} = "1|\n2|\n";
    my @queue = (response($draft), response(approved()));
    my @calls;
    my $post = generator($root, \@queue, \@calls, sub { "1|\n2|\n" })->generate($date);
    my $text = $post->slurp_utf8;
    like($text, qr/\Q$draft->{introduction}\E/, 'single-backtick spans preserved');
    like($text, qr/\Q$draft->{explanation}\E/, 'matching double-backtick spans preserved');
    like($text, qr/```perl\n\Q$draft->{code}\E\n```/, 'pipes in executable example preserved');
    like($text, qr/```text\n\Q$draft->{expected_stdout}\E\n```/, 'pipes in expected output preserved');
};

subtest 'bare variables are repaired before execution, review or saving' => sub {
    my $root = fixture;
    my $wrong = draft();
    $wrong->{explanation} = q{It does not read $_ and works when $_ is undefined.};
    my $fixed = draft();
    $fixed->{explanation} = q{It does not read `$_` and works when `$_` is undefined.};
    my @queue = (response($wrong), response($fixed), response(approved()));
    my @calls;
    my $runs = 0;
    my $post = generator($root, \@queue, \@calls, sub { ++$runs; "1\n2\n" })->generate($date);
    like($post->slurp_utf8, qr/\Q$fixed->{explanation}\E/, 'corrected variables preserved');
    like($calls[1]{messages}[-1]{content}, qr/explanation.*Perl variables.*backtick/,
        'formatting feedback sent to writer');
    is($runs, 1, 'malformed prose never executes');
    is(scalar @calls, 3, 'only repaired draft reaches review');
};

subtest 'ordinary punctuation is allowed in prose' => sub {
    my $root = fixture;
    my $draft = draft();
    $draft->{introduction} = 'A 50% discount, a 2-by-3 grid, and reader@example.com are ordinary text.';
    my @queue = (response($draft), response(approved()));
    my @calls;
    ok(generator($root, \@queue, \@calls)->generate($date)->exists,
        'percentages and email addresses are not mistaken for Perl variables');
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
    ['bare logical-or in introduction', 'introduction', 'Use || for false values.', qr/introduction.*pipe.*backtick/],
    ['bare bitwise-or in explanation', 'explanation', 'The | operator combines bits.', qr/explanation.*pipe.*backtick/],
    ['bare pipe assignment', 'explanation', 'Use |= to update the mask.', qr/pipe.*backtick/],
    ['bare pipe after inline code', 'explanation', 'Compare `//` with ||.', qr/pipe.*backtick/],
    ['unclosed inline code', 'introduction', 'Compare `|| with defaults.', qr/balanced.*inline code/],
    ['mismatched inline delimiters', 'explanation', 'Compare ``||` with defaults.', qr/balanced.*inline code/],
    ['escaped code delimiters', 'explanation', q{Compare \`||\` with defaults.}, qr/balanced.*inline code/],
    ['multiline inline code', 'explanation', "Compare `||\n` with defaults.", qr/balanced.*inline code/],
    ['bare topic variable twice', 'explanation', q{It reads $_ when $_ is set.}, qr/Perl variables.*backtick/],
    ['bare argument array', 'explanation', q{Do not unpack @_ manually.}, qr/Perl variables.*backtick/],
    ['bare named scalar', 'explanation', q{Increment $next_id on each call.}, qr/Perl variables.*backtick/],
    ['bare punctuation variable', 'explanation', q{Set $" locally.}, qr/Perl variables.*backtick/],
    ['bare capture variable', 'explanation', q{Read $1 after a match.}, qr/Perl variables.*backtick/],
    ['bare hash variable', 'explanation', q{Update %counts locally.}, qr/Perl variables.*backtick/],
    ['bare braced variable', 'explanation', q{Read @{^CAPTURE} after matching.}, qr/Perl variables.*backtick/],
    ['bare dereference', 'explanation', q{The ->@* syntax reads the array.}, qr/markup-sensitive syntax.*backtick/],
    ['bare underscored identifier', 'explanation', q{Enable unicode_strings for this.}, qr/markup-sensitive syntax.*backtick/],
    ['bare special keyword', 'explanation', q{Call __SUB__ recursively.}, qr/markup-sensitive syntax.*backtick/],
    ['bare regex escape', 'explanation', q{The \w pattern matches word characters.}, qr/markup-sensitive syntax.*backtick/],
    ['bare asterisk', 'explanation', q{Multiply using * in the expression.}, qr/markup-sensitive syntax.*backtick/],
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

subtest 'newer topics select matching prompts, interpreter and release notes' => sub {
    my $root = fixture;
    my $topics = decode_json($root->child('data/topics.json')->slurp_raw);
    my @covered = map { $_->{id} } @$topics[0..6];
    $root->child('data/covered-features.json')->spew_raw(encode_json(\@covered));
    my $draft = draft();
    $draft->{title} = 'Handle failures without losing the surrounding workflow';
    $draft->{code} = "use v5.44;\ntry { die qq{broken\\n} } catch (\$e) { print \$e }\n";
    $draft->{expected_stdout} = "broken\n";
    my @queue = (response($draft), response(approved()));
    my (@calls, @events);
    my $gen = PerlTips::Generator->new(root => $root,
        prepare_runner => sub ($runtime) { push @events, "prepare $runtime" },
        run_example => sub ($code, $runtime) {
            push @events, "execute $runtime";
            is($code, $draft->{code}, 'selected example sent verbatim');
            return "broken\n";
        },
        request => sub ($body) {
            push @events, $body->{response_format}{json_schema}{name};
            push @calls, $body;
            return shift @queue;
        });
    my $post = $gen->generate($date);
    is_deeply(\@events, ['prepare 5.44', 'perl_tip', 'execute 5.44', 'perl_tip_review'],
        'selected runner prepared before API request and reused for execution');
    like($calls[0]{messages}[1]{content}, qr/Target Perl 5\.44\./, 'writer gets selected version');
    like($calls[0]{messages}[1]{content}, qr/`use v5\.44;` on its own line/, 'writer gets matching baseline');
    like($calls[1]{messages}[0]{content}, qr/Target stable Perl 5\.44\./, 'reviewer gets selected version');
    unlike($calls[0]{messages}[1]{content} . $calls[1]{messages}[0]{content}, qr/__PERL_VERSION__/,
        'no unresolved prompt placeholders');
    my $text = $post->slurp_utf8;
    like($text, qr/^perl_version: "5\.44"$/m, 'tested version recorded');
    like($text, qr/Example tested with Perl 5\.44\./, 'tested version shown to reader');
    like($text, qr{https://perldoc\.perl\.org/5\.44\.0/perl5400delta}, 'stabilisation perldelta linked');
    is_deeply(decode_json($root->child('data/covered-features.json')->slurp_raw),
        [@covered, 'try-catch'], 'existing history preserved and new canonical topic appended');
};

subtest 'missing selected runner fails before an API request or content write' => sub {
    my $root = fixture;
    my $calls = 0;
    my $gen = PerlTips::Generator->new(root => $root,
        request => sub { ++$calls }, run_example => sub {},
        prepare_runner => sub { die "Selected Docker image unavailable\n" });
    fails(sub { $gen->generate($date) }, qr/image unavailable/, 'runner preflight fails closed');
    is($calls, 0, 'no API spend before runner readiness');
    unchanged($root);
};

for my $case (
    ['experimental entry', 'status', 'experimental', qr/must be stable/],
    ['unknown runtime', 'perl_version', '5.46', qr/Unsupported topic test version/],
    ['unversioned runtime', 'perl_version', 'latest', qr/Unsupported topic test version/],
    ['future introduction', 'introduced', '5.50', qr/must fit its test version/],
    ['future stability', 'stable_since', '5.44', qr/must fit its test version/],
    ['stability before introduction', 'stable_since', '5.8', qr/must fit its test version/],
    ['invalid version', 'introduced', '5.x', qr/Invalid topic title or version/],
    ['wrong reference runtime', 'reference_url', 'https://perldoc.perl.org/5.44.0/feature', qr/documentation for its test version/],
    ['untrusted reference', 'reference_url', 'https://example.com/feature', qr/documentation for its test version/],
    ['wrong perldelta runtime', 'release_notes_url', 'https://perldoc.perl.org/5.44.0/perl5100delta', qr/reviewed perldelta/],
    ['missing perldelta', 'release_notes_url', '', qr/lacks release_notes_url/],
) {
    subtest "invalid catalogue metadata: $case->[0]" => sub {
        my $root = fixture;
        my $topics = decode_json($root->child('data/topics.json')->slurp_raw);
        $topics->[0]{$case->[1]} = $case->[2];
        $root->child('data/topics.json')->spew_raw(encode_json($topics));
        my (@calls, @queue);
        fails(sub { generator($root, \@queue, \@calls)->generate($date) }, $case->[3], 'catalogue rejected');
        is(scalar @calls, 0, 'no API calls for invalid catalogue');
        unchanged($root);
    };
}

subtest 'older baseline cannot be used for a newer selected topic' => sub {
    my $root = fixture;
    my $gen = PerlTips::Generator->new(root => $root, request => sub {},
        run_example => sub { die 'Must not execute with the wrong baseline' });
    my $topics = decode_json($root->child('data/topics.json')->slurp_raw);
    my ($topic) = grep { $_->{id} eq 'try-catch' } @$topics;
    fails(sub { $gen->_check_draft(draft(), $topic) }, qr/start with use v5\.44/,
        'mismatched baseline rejected before execution');
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
