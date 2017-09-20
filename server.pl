#!/usr/bin/env perl

use WWW::Telegram::BotAPI;
use Telegram::Bot::Message;
use Data::Dumper;
use Tie::File;

#### Config section ####
my $token = $ENV{DOORKEYBOT_TOKEN} || '441592632:AAEACcNg6CXM_As4-zg4m68WrChis547iuo';
my $api = WWW::Telegram::BotAPI->new (
    token => $token
);
my $bot_name = $api->getMe->{result}{username};

my $filename = 'allowed_usernames.txt';
my $door_open_script = './root/fabkey/open.sh';
my $open_cmd = '/open';
my $group_chat_id = '-1001127744219';
########################

tie @array, 'Tie::File', $filename or die "Cant open $filename";
warn Dumper \@array;

while(1) {
  my @updates = @{$api->getUpdates->{result}};
  if (@updates) {
      for my $u (@updates) {
        warn Dumper $u;
        my $username = $u->{message}{from}{username};
        my $text = $u->{message}{text};
        my $chat_id = $u->{message}{chat}{id};

        if ( grep {$_ eq $username} @array ) {
          warn "User allowed to open";
          if ( ($text eq $open_cmd) || ($text eq $open_cmd.'@'.$bot_name ) ) {
            if ($chat_id eq $group_chat_id ) {
              `$door_open_script`;
              warn "Door opened!";
              $api->sendMessage ({
                        chat_id => $u->{message}{chat}{id},
                        text => 'Door opened. Welcome, @'.$username.'!',
                        reply_to_message_id => $u->{message}{message_id}
              });
            } else {
              $api->sendMessage ({
                        chat_id => $u->{message}{chat}{id},
                        text => 'For now it s allowed to use bot only in group chat',
                        reply_to_message_id => $u->{message}{message_id}
              });
            }
          }  else {
            warn "Wrong command";
            # $api->sendMessage ({
            #           chat_id => $u->{message}{chat}{id},
            #           text => 'Wrong command',
            #           reply_to_message_id => $u->{message}{message_id}
            # });
          }
        } else {
          $api->sendMessage ({
                    chat_id => $u->{message}{chat}{id},
                    text => 'You are not allowed to open the door. Contact administrator to get permissions',
                    reply_to_message_id => $u->{message}{message_id}
          });
        }
        $api->getUpdates({ offset => $u->{update_id} + 1.0 }); # clean buffer
      }
  }
};
