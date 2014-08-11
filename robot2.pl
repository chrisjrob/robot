#!/usr/bin/env perl

use strict;
use warnings;
use IRC::Utils qw(parse_user lc_irc);
use POE;
use POE::Component::IRC::State;
use POE::Component::IRC::Plugin::AutoJoin;
use POE::Component::IRC::Plugin::BotCommand;
use Storable;

use constant {
    USER_DATE     => 0,
    USER_MSG      => 1,
    DATA_FILE     => 'seen',
    SAVE_INTERVAL => 20 * 60,    # save state every 20 mins
};

my $seen = {};
$seen = retrieve(DATA_FILE) if -s DATA_FILE;

POE::Session->create(
    package_states => [
        main => [
            qw(
              _start
              irc_botcmd_seen
              irc_ctcp_action
              irc_join
              irc_part
              irc_public
              irc_quit
              save
              )
        ]
    ],
);

$poe_kernel->run();

sub _start {
    my ( $kernel, $heap ) = @_[ KERNEL, HEAP ];
    my $irc = POE::Component::IRC::State->spawn(
        Nick   => 'robot2',
        Server => 'irc.freenode.net',
    );
    $heap->{irc} = $irc;

    $irc->plugin_add(
        'AutoJoin',
        POE::Component::IRC::Plugin::AutoJoin->new(
            Channels => [ '#trident' ]
        )
    );

    $irc->plugin_add(
        'BotCommand',
        POE::Component::IRC::Plugin::BotCommand->new(
            Commands => { seen => 'Usage: seen <nick>' }
        )
    );

    $irc->yield(
        register => qw(ctcp_action join part public quit botcmd_seen) );
    $irc->yield('connect');
    $kernel->delay_set( 'save', SAVE_INTERVAL );
    return;
}

sub save {
    my $kernel = $_[KERNEL];
    warn "storing\n";
    store( $seen, DATA_FILE ) or die "Can't save state";
    $kernel->delay_set( 'save', SAVE_INTERVAL );
}

sub irc_ctcp_action {
    my $nick = parse_user( $_[ARG0] );
    my $chan = $_[ARG1]->[0];
    my $text = $_[ARG2];

    add_nick( $nick, "on $chan doing: * $nick $text" );
}

sub irc_join {
    my $nick = parse_user( $_[ARG0] );
    my $chan = $_[ARG1];

    add_nick( $nick, "joining $chan" );
}

sub irc_part {
    my $nick = parse_user( $_[ARG0] );
    my $chan = $_[ARG1];
    my $text = $_[ARG2];

    my $msg = 'parting $chan';
    $msg .= " with message '$text'" if defined $text;

    add_nick( $nick, $msg );
}

sub irc_public {
    my $nick = parse_user( $_[ARG0] );
    my $chan = $_[ARG1]->[0];
    my $text = $_[ARG2];

    add_nick( $nick, "on $chan saying: $text" );
}

sub irc_quit {
    my $nick = parse_user( $_[ARG0] );
    my $text = $_[ARG1];

    my $msg = 'quitting';
    $msg .= " with message '$text'" if defined $text;

    add_nick( $nick, $msg );
}

sub add_nick {
    my ( $nick, $msg ) = @_;
    $seen->{ lc_irc($nick) } = [ time, $msg ];
}

sub irc_botcmd_seen {
    my ( $heap, $nick, $channel, $target ) = @_[ HEAP, ARG0 .. $#_ ];
    $nick = parse_user($nick);
    my $irc = $heap->{irc};

    if ( $seen->{ lc_irc($target) } ) {
        my $date = localtime $seen->{ lc_irc($target) }->[USER_DATE];
        my $msg  = $seen->{ lc_irc($target) }->[USER_MSG];
        $irc->yield(
            privmsg => $channel,
            "$nick: I last saw $target at $date $msg"
        );
    }
    else {
        $irc->yield( privmsg => $channel, "$nick: I haven't seen $target" );
    }
}
