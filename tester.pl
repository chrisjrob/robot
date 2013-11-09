#!/usr/bin/perl -w

my $responses = load_responses('responses.xml');

{
    print ":";
    my $msg= <STDIN>;
    chomp($msg);
    my $response = get_response($responses, $msg);
    print ": $response\n";
    redo;
}
exit;


sub load_responses {
    my $xmlfile = shift;
    use XML::Simple;

    $xml = new XML::Simple;
    $responses = $xml->XMLin($xmlfile, ForceArray => 1, KeyAttr => {} );

    return $responses;
}

sub get_response {
    my ($responses, $msg) = @_;

    # use Data::Dumper;
    # print Dumper($responses);
    
    foreach my $entry (@{$responses->{entry}}) {
        my $regex    = $entry->{regex}->[0];
        my $response = $entry->{response}->[0];
        if ( $msg =~ /$regex/ ) {
            my $capture1 = $1;
            my $capture2 = $2;
            my $capture3 = $3;
            $response =~ s/\$1/$capture1/g;
            $response =~ s/\$2/$capture2/g;
            $response =~ s/\$3/$capture3/g;
            return $response;
        }
    }

}

