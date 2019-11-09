#!/usr/bin/env perl6

use OpenBSD;

sub MAIN(:w(:$with), :e(:$without), *@command) {
    if !@command || (!$with && !$without) {
        say $*USAGE;
        exit;
    }
    if $with & $without {
        say "Please choose either --with or --without, but not both";
        exit;
    }
    my %with = $with ?? %( $_ => True for $with.split(',') ) !! {};
    my %without = $without ?? %( $_ => False for $without.split(',') ) !! {};
    Pledge::set-exec(|(%with || %without));
    run @command;
}
