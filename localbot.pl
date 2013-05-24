#!/usr/bin/perl;
#
# localbot
#
# Simple script to test local bot

use strict;
use Data::Dumper;

my $maps        = load_maps();
my $count       = @$maps;
my $bot         = 'robot_';
my $nick        = 'visitor';
my $lastsay     = 0;

my ($type, $response);

print "Ctrl+C to quit\n";
{
    print "$nick: ";
    my $input = <STDIN>;
    ($maps, $type, $response) = get_response($input);
    if ($type eq 'ACTION') {
        $lastsay = time;
        print " * $bot $response\n";
    } elsif ($type eq 'SAY') {
        $lastsay = time;
        print "$bot : $response\n";
    } elsif ( (time - $lastsay) > 60 ) {
        ($maps, $type, $response) = get_response();
    }

    redo;
}

sub get_response {
    my $input = shift;
    chomp($input);
    
    for (my $i=0;$i<$count;$i++) {
        if ( ! defined $input ) {
            # Make a random selection
            # but only of sayings that would be appropriate for random selection

        } elsif ( (defined $$maps[$i]{LASTUSED}) and ((time - $$maps[$i]{LASTUSED}) < 30 ) ) {
            next;

        } elsif ($input =~ s/^$$maps[$i]{REGEX}/qq["$$maps[$i]{RESPONSE}"]/eegi) {

            print Dumper($maps);
            $$maps[$i]{LASTUSED} = time;
            print "LASTUSED = $$maps[$i]{LASTUSED}\n";

            return ($maps, $$maps[$i]{TYPE}, $input);

        }
    }
    return $maps;
}

sub load_maps {

    ## God I hate ruby
    #.*\bhates?\s+(.{3,}?)\b
    #ACTION
    #considers $1 to be the work of the devil

    my @maps;
    open(my $fh_responses, '<', 'responses') or die "Cannot open responses: $!";
    while( defined( my $comment  = <$fh_responses>) ) {
        if ($comment =~ /^\s*\n/) { last; }
        my $regex    = <$fh_responses>;
        my $type     = <$fh_responses>;
        my $response = <$fh_responses>;
        <$fh_responses>; # waste blank line
        chomp($comment, $regex, $type, $response);
        my $map = {
            COMMENT  => $comment,
            REGEX    => qr/$regex/,
            TYPE     => $type,
            RESPONSE => $response,
        };
        push(@maps, $map);
    }
    close($fh_responses) or die "Cannot close responses: $!";

    return \@maps;

}
