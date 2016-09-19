use strict;
use warnings;

use Test::More;
use Mir::Plugin;
use Mir::Util::DocHandler;
use JSON;

BEGIN {
    use_ok('Mir::Plugin::IR::ComputeTermsFrequency');
}

ok(my $p = Mir::Plugin->create( driver => 'IR::ComputeTermsFrequency'), 'create');

# load a doc from a stored json file...
my $docs_as_json;
{
    local $/;
    open (my $fh, "<:encoding(UTF-8)","./data/docs.json");
    $docs_as_json = <$fh>;
    close $fh;
}

my $docs = from_json( $docs_as_json )
    or die "Error decoding file content:$@\n";

foreach my $doc ( @$docs ) {
    my $dh = Mir::Util::DocHandler->create( driver => 'txt' );
    $dh->open_doc($doc->{path});
    $doc->{text} = [];
    for (my $i=0;$i<$dh->pages();$i++) {
        my ( $text, $confidence ) = $dh->page_text( $i, '/tmp' );
        push @{ $doc->{text} }, $text;
    }
    ok( my $new_doc = $p->run({
            doc     => $doc,
            terms   => [ qw(
                artistic license
                package
                patent
                )],
            lang    => 'en'
        }), 'run' );
    ok(exists( $new_doc->{terms}), 'ok, terms found');
}

done_testing;
