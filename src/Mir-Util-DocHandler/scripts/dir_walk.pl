use strict;
use warnings;
use utf8;
use Log::Log4perl       qw( :easy );
use Ishare::FileHandler ();
use Mir::Util::DocHandler  ();
use TryCatch;
binmode(STDOUT, ":utf8");

Log::Log4perl->easy_init( $DEBUG );

my ($path, $driver) = @ARGV or die "Usage: $0 <un percorso...> <un driver Mir::Util::DocHandler...>\n";

my $lut = {
    pm => 'txt',
    docx => 'doc',
    pdf => 'pdf'
};

sub print_dir {
    if ( not -e "$_[0]" ) {
        die "ERRORE: File $_[0] non raggiungibile\n";
    }
    print $_[0]."\n";
}

sub extract_text {
    print "----------------------- Extracting text from File ---------------------------------------\n";
    print "$_[0]\n";
    my @a = split( /\./, $_[0] );
    my $suffix = $a[-1];
    print "with suffix $suffix\n";
    print "-----------------------------------------------------------------------------------------\n";
    $suffix = (exists $lut->{$suffix}) ? $lut->{$suffix}:$suffix;
    my $doc;
    try {
        $doc = Mir::Util::DocHandler->create( driver => $suffix )
            or return "Error getting an obj for driver $driver";
    } catch ( $err ) {
        print "Error getting a Mir::Util::DocHandler object for driver $suffix\n";
        return;
    }
    $doc->open_doc( $_[0] );
    print "Tesseract version:";
    `tesseract -v`;
    print "\nPages: ".$doc->pages(). "\n";
    for ( my $i=1;$i<= $doc->pages();$i++) {
        my ($text, $conf) = $doc->page_text($i, "/tmp");
        print "\nPage: $i\n";
        print "TEXT:\n";
        print "$text\n";
        print "Confidence: $conf\n";
    }
}

my $pdf_count = 0;
# stampa solo file pdf...
sub print_pdf {
    if ( not -e $_[0] ) {
        die "ERRORE: File $_[0] non raggiungibile\n";
    }
    if ( $_[0] =~ /\.pdf$/i ) {
        print $_[0]."\n";
        $pdf_count++;
    }
}

my $o = Ishare::FileHandler->new( $path );
my $count = $o->dir_walk( $path, \&extract_text);
print "found $count files/dirs\n";
