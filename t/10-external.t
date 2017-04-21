#!/usr/bin/perl -w
# -*- coding: utf-8; -*-

=head1 NAME

10-external.t - Testing Test2::Group without using it in the test suite
(which is arguably less fun, but also more robust).

=cut

use strict;
use warnings;

use Test::More 'no_plan';
   # tests => 36; # Sorry, no_plan not portable for Perl 5.6.1!
use Test::Cmd;


sub perl_cmd {
    return Test::Cmd->new
        (prog => join(' ', $^X,
                      (map { ("-I", $_) } @INC), '-'),
         workdir => '');
}


ok(my $perl = perl_cmd,"create perl command");

my $retval = $perl->run(stdin => <<'EOSCRIPT');
use Test::More tests=>2;
use Test2::Group qw(test_group);

ok 1, "this is true";

test_group "group", sub {
    ok 1;
    like   "blah blah blah", qr/bla/;
    unlike "blah blah blah", qr/bli/;
    foreach my $i (0..5) {
        cmp_ok $i**2, '==', $i*$i;
    }
};

EOSCRIPT

is $retval >> 8, 0, "passing test group without plan";
 
is scalar($perl->stdout()), <<EOOUT;
1..2
ok 1 - this is true
ok 2 - group
EOOUT
is scalar($perl->stderr()), "";

$retval = $perl->run(stdin => <<'EOSCRIPT');
use Test::More tests=>2;
use Test2::Group qw(test_group);

ok 1, "this is true";

test_group "group", sub {
    ok 1;
    like   "blah blah blah", qr/bla/;
    unlike "blah blah blah", qr/bli/;
    foreach my $i (0..5) {
        cmp_ok $i**2, '==', $i*$i;
    }
},9;

EOSCRIPT

is $retval >> 8, 0, "passing test group with plan";
 
is scalar($perl->stdout()), <<EOOUT;
1..2
ok 1 - this is true
ok 2 - group
EOOUT
is scalar($perl->stderr()), "";

is $perl->run(stdin => <<'EOSCRIPT') >> 8, 1, "failing test group";
use Test::More tests=>1;
use Test2::Group qw(test_group);

test_group "group 2", sub {
    is "bla", "ble";
    ok 0, "sub test blah";
    ok 0;
    like   "blah blah blah", qr/bli/;
};
EOSCRIPT

is scalar($perl->stdout()), <<EOOUT;
1..1
not ok 1 - group 2
EOOUT

like scalar($perl->stderr()), qr/got:.*bla/, "got bla";
like scalar($perl->stderr()), qr/expected:.*ble/, "expected ble";
like scalar($perl->stderr()), qr/failed.*sub test blah/i, "another subtest failed";
like scalar($perl->stderr()), qr/failed 1 test.* of 1/,
    "1 test total despite multiple failures";

ok $perl->run(stdin => <<'EOSCRIPT') >> 8, "empty test group fails";
use Test::More 'no_plan';
use Test2::Group qw(test_group);

test_group      "empty group", sub {
    1;
};
EOSCRIPT

is scalar($perl->stdout()), <<EOOUT, "empty test groups";
not ok 1 - empty group
1..1
EOOUT

diag("STDERR for empty test group");
diag($perl->stderr());

is $perl->run(stdin => <<'EOSCRIPT') >> 8, 0, "TODO tests inside a test group";
use Test::More tests => 1;
use Test2::Group qw(test_group);

test_group "this is a todo" => sub {
    TODO: {
        local $TODO = "UNIMPLEMENTED";
        fail;
    }
};

EOSCRIPT

like scalar($perl->stdout()), qr/not ok 1.*# TODO/, "test TODO flag";

is $perl->run(stdin => <<'EOSCRIPT') >> 8, 0, "TODO around a test_group";
use Test::More tests => 1;
use Test2::Group qw(test_group);

TODO: {    
    local $TODO = "UNIMPLEMENTED";
    test_group "this is also a todo" => sub {
        fail;
    }
};

EOSCRIPT

like scalar($perl->stdout()), qr/not ok 1.*# TODO/, "test todo flag";

ok $perl->run(stdin => <<'EOSCRIPT') >> 8 != 0, "do catch exceptions";
use Test::More tests => 1;
use Test2::Group qw(test_group);
#Test2::Group->dont_catch_exceptions();

test_group "group 1", sub {
    ok(1);
    die "coucou";
    ok(1);
},2;

EOSCRIPT
is scalar($perl->stdout()), <<EOOUT, "check stdout";
1..1
not ok 1 - group 1
EOOUT
like(scalar($perl->stderr()), qr/coucou/i,"check stderr");

diag($perl->stderr);

1;
