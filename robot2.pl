#!/usr/bin/env perl

use strict;
use warnings;

use POE;
use POE::Component::IRC;
use POE::Component::IRC::Plugin::BotCommand;

my %DATA;
dbmopen(%DATA, 'database', 0644)
    or die "Cannot create database: $!";

# Print DB to stdout
printdb();

my @channels = ( '#trident' );

my $nick = 'robot_' . $$ % 1000;

my $irc = POE::Component::IRC->spawn(
    nick   => $nick,
    server => 'irc.freenode.net',
);

POE::Session->create(
    package_states => [
        main =>
            [ qw(
              _start
              irc_001
              irc_botcmd_slap
              irc_botcmd_add )
            ],
    ],
);

$poe_kernel->run();

dbmclose(%DATA) or die "Cannot close database: $!";

exit;

###############################################################
#                                                             #
# Sub-routines                                                #
#                                                             #
###############################################################

sub _start {
    $irc->plugin_add(
        'BotCommand',
        POE::Component::IRC::Plugin::BotCommand->new(
            Commands => {
                slap => 'Usage: slap <nick>',
                add => 'Usage: add <name> <regex-substitution',
            }
        )
    );
    $irc->yield( register => qw(001 botcmd_slap botcmd_add) );
    $irc->yield( connect  => {} );
}

# join some channels
sub irc_001 {
    $irc->yield( join => $_ ) for @channels;
    return;
}

# the good old slap
sub irc_botcmd_slap {
    my $nick = ( split /!/, $_[ARG0] )[0];
    my ( $where, $arg ) = @_[ ARG1, ARG2 ];
    $irc->yield( ctcp => $where, "ACTION slaps $arg" );
    return;
}

sub irc_botcmd_add {
    my $nick = ( split /!/, $_[ARG0] )[0];
    my ( $where, $input) = @_[ ARG1, ARG2 ];

    my ($name, $regex) = split(/\s+/, $input);

    if ( (! defined $name) or (! defined $regex) ) {
        $irc->yield(
            'privmsg' => $where,
            'Usage: add <name> <regex-substitution>'
        );
        return;
    }

    # Some error checking here and untaint

    $DATA{$name} = $regex;


    $irc->yield( ctcp => $where, "ACTION adds $name to database" );
    return;
}

sub printdb {
    foreach my $name (keys %DATA) {
        print "$name is ", $DATA{$name}, "\n";
    }
}

# # non-blocking dns lookup
# sub irc_botcmd_lookup {
#     my $nick = ( split /!/, $_[ARG0] )[0];
#     my ( $where, $arg ) = @_[ ARG1, ARG2 ];
#     my ( $type, $host ) = $arg =~ /^(?:(\w+) )?(\S+)/;
# 
#     my $res = $dns->resolve(
#         event   => 'dns_response',
#         host    => $host,
#         type    => $type,
#         context => {
#             where => $where,
#             nick  => $nick,
#         },
#     );
#     $poe_kernel->yield( dns_response => $res ) if $res;
#     return;
# }
# 
# sub dns_response {
#     my $res = $_[ARG0];
#     my @answers = map { $_->rdatastr } $res->{response}->answer()
#       if $res->{response};
# 
#     $irc->yield(
#         'notice',
#         $res->{context}->{where},
#         $res->{context}->{nick}
#           . (
#             @answers
#             ? ": @answers"
#             : ': no answers for "' . $res->{host} . '"'
#           )
#     );
# 
#     return;
# }
