use strict;
use warnings;
use feature 'state';
use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init($DEBUG);

use Test::More;

BEGIN { 
    use_ok('Mir::FileHandler');
}

    # get a new FileHandler obj for the passed root directory
ok( my $o = Mir::FileHandler->new( path => './lib' ), 'new');

    # get plain files list inside the root directory
ok( my $list = $o->plainfiles(), 'plainfiles' ); # or pass a path in input

    # get plain files list from folder and sub-folders
    # gli passo la cartella radice, una lista di suffissi ed eventualmente un
    # handler per il processamento delle risorse
    # se non gli passo l'handler allora usa quello di default
ok( $list = $o->plainfiles_recursive(), 'plainfiles_recursive' );

state $found={};
my $code = sub { 
    if ( $found->{ $_[0] } ) {
        diag "File $_[0] already present, skipping!\n";;
        return 0;
    } else { 
        diag "File $_[0] NEW !\n";;
        $found->{ $_[0] } = 1;
        return 1;
    }
};

    # walk a directory and exec code for each file...
$o->count(0);
ok( $o->dir_walk( 
    top  => './lib', 
    code => $code 
), 'dir_walk');
is( scalar keys %$found, $o->count(), 'Got right number of files under ./lib which by the way are '.$o->count());

$found = {};

    # walk a directory and exec code for each file...
    # stops after max success code execution
    # the sub pointed by $code has to return 1 in
    # case of success
is( $o->count(0), 0, 'reset valid files counter' );
ok( $o->dir_walk_max( 
    top  => './lib', 
    code => $code, 
    max  => 10 
), 'dir_walk for max 10 files...' );
is( $o->count(), 10, 'Got right number of valid files' );

    # walk a directory and exec code for each file...
    # stops after max success code execution
    # the sub pointed by $code has to return 1 in
    # case of success
    # after a new iteration it eventually restarts from
    # a cached dir onward (does not restart from the root dir)
    # returns the last folder visited
ok( $o->clear_cache(), 'clear_cache' );
is( $o->count(0), 0, 'reset valid files counter');
$found={};
ok( $o->dir_walk_max( 
    top         => './lib',
    code        => $code,
    max         => 6,
    cached_dir  => 1,
), 'dir_walk for max 6 files, should restart from cached folder');
is( $o->count(), 6, 'Got right number of valid files' );
is( $o->count(0), 0, 'reset valid files counter');
# this shoudl start from cache...
ok( $o->dir_walk_max( 
    top         => './lib',
    code        => $code,
    max         => 50,
    cached_dir  => 1,
), 'dir_walk for max 20 files, should delete cache dir' );

done_testing();
