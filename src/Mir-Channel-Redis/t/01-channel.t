use strict;
use warnings;
use Test::More;
use Log::Log4perl qw(:easy);

use Mir::Channel;

Log::Log4perl::easy_init($DEBUG);

ok( my $subscriber = Mir::Channel->create(
        driver  => 'Redis',
        params  => {
            connect => { server => '127.0.0.1:6379' }, 
            db      => 1,
        }), 'new' );
is( ref $subscriber, 'Mir::Channel::Redis', 'Got right object class back');

sub callback {
    my ( $message, $topic, $subscribed_topic ) = @_;

    note( "Callback: message: $message" );
    is( $message, "Hello, World", "Got right message back" );
}

is( $subscriber->subscribe( 
        channels => ['channel1'], 
        callback => \&callback ), 0, "subscribe" );

ok( my $publisher = Mir::Channel->create(
        driver  => 'Redis',
        params  => {
            connect => { server => '127.0.0.1:6379' }, 
            db      => 1,
            key     => 'test',
            timeout => 10,
        }), 'new' );
is( ref $publisher, 'Mir::Channel::Redis', 'Got right object class back');
ok( $publisher->publish('channel1', 'Hello, World'), 'publish' );


done_testing();
