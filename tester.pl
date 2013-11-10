#!/usr/bin/perl -w

use strict;
my $RESPONSES = load_responses('responses.xml');
my $NICK = "robot_987";
use vars qw($NICK $RESPONSES);

{
    print ":";
    my $msg= <STDIN>;
    chomp($msg);
    my $response = get_response($msg);
    print ": $response\n";
    redo;
}

exit;

sub load_responses {
    my $xmlfile = shift;
    use XML::Simple;

    my $xml = new XML::Simple;
    my $responses = $xml->XMLin($xmlfile, ForceArray => 1, KeyAttr => {} );

    return $responses;
}

sub get_response {
    my $msg = shift;

    use Data::Dumper;
    print Dumper($RESPONSES);
    
    foreach my $entry (@{$RESPONSES->{entry}}) {
        my $regex    = $entry->{regex}->[0];

        # For some reason this isn't expanding automatically
        $regex =~ s/\$NICK/$NICK/gi;

        my $response = $entry->{response}->[0];
        if ( $msg =~ /$regex/ ) {
            my $capture1 = $1;
            my $capture2 = $2;
            my $capture3 = $3;
            $response    =~ s/\$1/$capture1/g;
            $response    =~ s/\$2/$capture2/g;
            $response    =~ s/\$3/$capture3/g;
            my $type     = $entry->{type}->[0];
            return "$type $response";
        }
    }

}

