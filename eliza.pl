#!/usr/bin/perl -w
use strict;
$|++;
use Net::IRC;
use Chatbot::Eliza;
my $IRC_debug = 0;
my $TRACE     = 1;
( my $irc = Net::IRC->new )->debug($IRC_debug);
my $conn = $irc->newconn(
    Nick   => 'eliza000',
    Server => 'irc.freenode.net',
);

for (
    [
        motd => sub {
            print "motd:" . ( $_[1]->args )[1], "\n" if $TRACE;
          }
    ],
    [
        endofmotd => sub {
            my $conn = shift;
            print "we are IN!\n" if $TRACE;
            $conn->join("#tvrrug");
          }
    ],
    [
        nicknameinuse => sub {
            my $conn = shift;
            my $nick = $conn->nick;
            $nick =~ /^[a-zA-Z]+[0-9]*$/ or die "can't
                    fix collided nick";
            $nick++;
            print "nickcollision,fixingto$nick\n" if $TRACE;
            $conn->nick($nick);
          }
    ],
    [
        msg => sub {
            my ( $conn, $event ) = @_;
            my ($msg) = $event->args;
            heard( $conn, $event, $event->nick, $msg );
          }
    ],
    [
        public => sub {
            my ( $conn, $event ) = @_;
            my ($msg) = $event->args;
            heard( $conn, $event, $event->to, $msg );
          }
    ],
  )
{
    $conn->add_global_handler(@$_);
}
$irc->start;

BEGIN {
    my %docs;
    my %talking_to;

    sub heard {
        my ( $conn, $event, $from, $said ) = @_;
        print "heard $from say $said\n" if $TRACE;
        if ( $said =~ /go away/ ) {
            $conn->quit(
                "o/~ and all the science, I don't
                            understand… it's just my job
                            five days a week o/~"
            );
            return;
        }
        my $userhost = $event->userhost;
        my $doc = $docs{$userhost} ||= do {
            my $bot = Chatbot::Eliza->new();
            $bot->{memory} = [];    # bug workaround
            $bot;
        };
        my @response = $doc->transform($said);
        my $nick     = $event->nick;
        if ( ( $talking_to{$from} || "" ) ne $nick ) {
            $talking_to{$from} = $nick;
            $response[0] = "$nick, $response[0]";
        }
        for (@response) {
            say( $conn, $from, $_ );
        }
    }
}

sub say {
    my ( $conn, $to, $what ) = @_;
    print "telling $to $what\n" if $TRACE;
    if ( $to =~ /^\#/ ) {    #a channel
        $conn->privmsg( $to, $what );
    } else {                 #a person
        $conn->notice( $to, $what );
    }
}
