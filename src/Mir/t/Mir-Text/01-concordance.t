use strict;
use warnings;
use Test::More;
use Data::Printer;
use Log::Log4perl qw(:easy);

Log::Log4perl->easy_init( $DEBUG );

use_ok( 'Mir::Text' );

my $term = 'the';
my $radius = 20;
my $text;
{
    undef $/;
    die ".mmm... the test text file seems missing or not readable\n"
        unless ( -f "./data/ir/the-tell-tale-heart.txt" );
    open my $fh, "<./data/ir/the-tell-tale-heart.txt" or die "error opening the text file\n";
    $text = <$fh>;
    close $fh;
}

ok( my $o = Mir::Text->new(), 'new' );
ok( $o->text( $text ), 'text' );
ok( $o->term( $term ), 'term' );
ok( my $concordance = $o->concordance( $radius ), 'concordance' );
note "Concordance for term $term:";
p $concordance;

done_testing;
