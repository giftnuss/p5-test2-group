#!/usr/bin/perl -w
# -*- coding: utf-8; -*-

=head1 NAME

10-external.t - Testing Test2::Group without using it in the test suite
(which is arguably less fun, but also more robust).

=cut

use strict;
use warnings;

use Test::More 'tests' => 2;

ok(1,'I\'m running');

TODO: {
    local $TODO = "Checkout how a TODO loks like."; 
    fail;
};
