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

# Create the component that will represent an IRC network.
my ($irc) = POE::Component::IRC->spawn();

# Create the bot session.  The new() call specifies the events the bot
# knows about and the functions that will handle those events.
POE::Session->create(
  inline_states => {
    _start     => \&bot_start,
    irc_001    => \&on_connect,
    irc_public => \&on_public,
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
  my $response;
  print " [$ts] <$nick:$channel> $msg\n";
  if ($msg =~ /^.*\bhates?\s+(.{3,}?)\b/) {
    $response = "ACTION considers $1 to be the work of the devil";

    # Send a response back to the server.
    #$irc->yield(privmsg => CHANNEL, $response);

    # Make an action
    $irc->yield(ctcp => CHANNEL, $response);
  }
}

sub get_response {
    my $msg = shift;

#    foreach my $abbrev (@abbreviations) {
#                $options =~ s/\b$abbrev\b/qq["$CONFIG{'Abbreviations'}{$abbrev}"]/eegi;
#                    }
#
}

# Run the bot until it is done.
$poe_kernel->run();
exit 0;
