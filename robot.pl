#!/usr/bin/perl;
#
# Simple IRC Bot
#
# http://search.cpan.org/dist/POE-Component-IRC/lib/POE/Component/IRC.pm

use warnings;
use strict;
use POE;
use POE::Component::IRC;
sub CHANNEL () { "#yourchannel" }
my $RESPONSES = load_responses('responses.xml');
use vars qw($RESPONSES);

# Create the component that will represent an IRC network.
my ($irc) = POE::Component::IRC->spawn();

# Create the bot session.  The new() call specifies the events the bot
# knows about and the functions that will handle those events.
POE::Session->create(
  inline_states     => {
    _start          => \&bot_start,
    irc_001         => \&on_connect,
    irc_public      => \&on_public,
    irc_ctcp_action => \&on_action,
  },
);

# The bot session has started.  Register this bot with the "magnet"
# IRC component.  Select a nickname.  Connect to a server.
sub bot_start {
  $irc->yield(register => "all");
  my $nick = 'robot_' . $$ % 1000;
  $irc->yield(
    connect => {
      Nick     => $nick,
      Username => 'robot_',
      Ircname  => 'robot_',
      Server   => 'irc.freenode.net',
      Port     => '6667',
    }
  );
}

# The bot has successfully connected to a server.  Join a channel.
sub on_connect {
  $irc->yield(join => CHANNEL);
}

# The bot has received a public message.  Parse it for commands, and
# respond to interesting things.
sub on_public {
  my ($kernel, $who, $where, $msg) = @_[KERNEL, ARG0, ARG1, ARG2];
  my $nick    = (split /!/, $who)[0];
  my $channel = $where->[0];
  my $ts      = scalar localtime;
  print " [$ts] <$nick:$channel> $msg\n";
  my $response = get_response($msg);
  if ($response) {
    $irc->yield(ctcp => CHANNEL, "ACTION $response");
  }
}

# The bot has received action message.  Parse it for commands, and
# respond to interesting things.
sub on_action {
  my ($kernel, $who, $where, $msg) = @_[KERNEL, ARG0, ARG1, ARG2];
  my $nick    = (split /!/, $who)[0];
  my $channel = $where->[0];
  my $ts      = scalar localtime;
  print " [$ts] <$nick:$channel> $msg\n";
  my $response = get_response($msg);
  if ($response) {
    $irc->yield(ctcp => CHANNEL, "ACTION $response");
  }
}

sub load_responses {
    my $xmlfile = shift;
    use XML::Simple;

    my $xml = new XML::Simple;
    my $responses = $xml->XMLin($xmlfile, ForceArray => 1, KeyAttr => {} );

    return $responses;
}

sub get_response {
    my ($msg) = @_;

    foreach my $entry (@{$RESPONSES->{entry}}) {
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

# Run the bot until it is done.
$poe_kernel->run();
exit 0;
