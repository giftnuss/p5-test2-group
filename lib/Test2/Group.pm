package Test2::Group;
our $VERSION = '0.01';

use strict;
use warnings;

use Test2::API qw(context run_subtest);

our @EXPORT_OK = qw(test_group);
use parent 'Exporter';

use Data::Dumper;

sub test_group {
    my ($name,$code,$plan,@args) = @_;
    local $@ = undef;
    local $_;
    
    $plan = 'NO PLAN' unless defined $plan;
    
    my $ctx = context();
    
    my $hub = $ctx->stack->new_hub(
        class => 'Test2::Hub::Subtest',
        buffered => 1
    );
    
    my @events;
    $hub->set_nested( $ctx->hub->isa('Test2::Hub::Subtest') ? $ctx->hub->nested + 1 : 1 );
    $hub->listen(sub { push @events => $_[1] });
    $hub->format(undef);
    $hub->plan($plan);
    
    my ($ok, @err, $exception);
    # Do not use 'try' cause it localizes __DIE__
    my $retval = eval { $code->(@args) };
    $exception = $@ || $@ =~ /^0$/ ? $@ : undef;
    
    $ctx->stack->pop($hub);

    my $trace = $ctx->trace;

    my $bailed = $hub->bailed_out;
    
    if ($bailed) {
        $ok = 1;
    }
    else {
        my $code = $hub->exit_code;
        $ok = !$code && !$exception;
        push @err, "Grouped tests ended with exit code $code" if $code;
        push @err, "Died with exception: $exception" if defined($exception);
    }

    $hub->finalize($trace, 1)
        if $ok
        && !$hub->no_ending
        && !$hub->ended;

    my (@todo) = grep { $_->can('todo') and $_->todo } @events;

    my ($pass,$e);
    if(@todo == 0) {
        $pass = $ok && $hub->is_passing;
        $e = $ctx->build_event(
            'Ok',
            pass       => $pass,
            name       => $name
        );
    }
    else {
        $e = $ctx->build_event(
            'Ok',
            name       => $name,
            todo       => $todo[0]->todo
        );
        $pass = $e->pass && $hub->is_passing;
    }

    my $plan_ok = $hub->check_plan;

    $ctx->hub->send($e);

    unless($e->pass) {
        $ctx->failure_diag($e);
        foreach my $event (@events) {
            next if $event->can('pass') and $event->pass;
            $ctx->diag($event->summary);
        }
    }
    
    $ctx->diag($_) foreach @err;

    $ctx->diag("Bad subtest plan, expected " . $hub->plan . " but ran " . $hub->count)
        if defined($plan_ok) && !$plan_ok;

    $ctx->bail($bailed->reason) if $bailed;

    $ctx->release;
    
    return $pass;
}

1;

__END__

=head2 NAME

Test2::Group

=head2 SYNOPSIS

    use Test2::Group qw(test_group);
    
    test_group "group", sub {
        ok 1;
        like   "blah blah blah", qr/bla/;
        unlike "blah blah blah", qr/bli/;
        foreach my $i (0..5) {
            cmp_ok $i**2, '==', $i*$i;
        }
   },9;

=head1 DESCRIPTION

This module works similar to Test::Group, but leave a lot of features
unimplemented. Test::Group(s) function is similar to the subtest feature,
but without normally showing subtest results.

Droping the features results in a very small class. In my opinion
most of the fatures can be implemented with common Test::More
functionality.

I'm not sure if it worth to develop this forther. For now I go with
C<Test::More::subtest>.

=head2 Unimplemented features from Test::Group

=over 4

=item C<skip_next_tests>

=item C<begin_skipping_tests> and C<end_skipping_tests>

=item C<test_only>

=item declaration of todo test by test description

=item C<dont_catch_exceptions>

This is a feature worth to implement, but currently I don't know how.

=back


