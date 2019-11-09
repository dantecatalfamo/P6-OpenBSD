#!/usr/bin/env perl6

use OpenBSD;

sub MAIN(:w(:$with), :wo(:$without), *@command) {
    die "No command specified" if !@command;
    die "Please choose either --with or --without, but not both" if $with & $without;
    say "No restrictions specified" if !$with & !$without;
    my %with = $with ?? %( $_ => True for $with.split(',') ) !! {};
    my %without = $without ?? %( $_ => False for $without.split(',') ) !! {};
    Pledge::set-exec(|(%with || %without));
    run @command;
}
