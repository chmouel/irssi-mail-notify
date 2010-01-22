##
## Put me in ~/.irssi/scripts, and then execute the following in irssi:
##
##       /load perl
##       /script load mail-notify
##
## Inspired from script http://irssi-libnotify.googlecode.com/svn/trunk/notify.pl

use strict;
use Irssi;
use vars qw($VERSION %IRSSI);
use DBI;

$VERSION = "0.01";
%IRSSI = (
    authors     => 'Chmouel Boudjnah',
    contact     => 'chmouel@chmouel.com',
    name        => 'mail-notify',
    description => 'Use MAIL to alert user to hilighted messages',
    license     => 'GNU General Public License'
);

Irssi::settings_add_str('mail-notify', 'mail-notify.py', '/usr/local/bin/mail-notify.py');

sub mentionned {
    my ($dest, $text, $stripped) = @_;
    my $server = $dest->{server};
    my $sender = $stripped;
    my $channel = $dest->{'target'};
    my $mynick = $dest->{'window'}{'active_server'}{'nick'};
    return if (!$server || !($dest->{level} & MSGLEVEL_HILIGHT));
    $sender =~ s/^\<\s*([^\>]+)\s*\>.+/$1/;
    $stripped =~ s/\<.[^\>]+\>.${mynick}:\s*//;
    $channel =~ s/^#//;
    insert_sqlite($sender, $channel, $stripped);
}

sub own {
    my ($dest, $text, $channel) = @_;
    $channel =~ s/^#//;
    insert_sqlite('me', $channel, $text);
}

sub insert_sqlite {
    my ($nick, $channel, $message) = @_;
    my $dbh = DBI->connect("dbi:SQLite:dbname=/tmp/mail-notify.db", "", "", #TODO: setting
                           { RaiseError => 1, AutoCommit => 0 }
                          );
    eval {
        $dbh->do("CREATE TABLE IF NOT EXISTS data (id INTEGER PRIMARY KEY, date DATETIME, nick TEXT, channel TEXT, message TEXT)");
        $dbh->do("INSERT INTO data (date, nick, channel, message) VALUES (DATETIME('now'), '$nick', '$channel', '$message')");
        $dbh->commit(  );
    };
    if ($@) {
        eval { $dbh->rollback(  ) };
        die "Couldn't roll back transaction" if $@;
    }
}

sub debug {
    use Data::Dumper;

    my ($message) = @_;
    local *F;
    open(F, ">>/tmp/mail-notify-debug.txt");
    print F Dumper($message) . "\n";
    close F;
}

Irssi::signal_add('message own_public', 'own');
Irssi::signal_add('message own_private', 'own');
Irssi::signal_add('print text', 'mentionned');
#Irssi::signal_add('message private', 'notify');
#Irssi::signal_add('dcc request', 'notify');
