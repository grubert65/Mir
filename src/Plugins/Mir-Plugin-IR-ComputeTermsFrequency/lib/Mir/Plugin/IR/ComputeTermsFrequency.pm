package Mir::Plugin::IR::ComputeTermsFrequency;

=head1 NAME

Mir::Plugin::IR::ComputeTermsFrequency - A plugin to compute terms frequency in a document text

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Mir::Plugin;

    my $foo = Mir::Plugin->create(driver => 'IR::ComputeTermsFrequency');

    # the returned doc should contain the terms attribute with the 
    # list of terms matching the document text.
    my $new_doc = $foo->run( {
        terms       => [ ... ],
        doc         => $doc,
        lang        => 'it',
        exact_match => 0,
    });

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 AUTHOR

Marco Masetti, C<< <marco.masetti at softeco.it> >>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Mir::Plugin::IR::ComputeTermsFrequency


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Mir-Plugin-IR-ComputeTermsFrequency>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Mir-Plugin-IR-ComputeTermsFrequency>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Mir-Plugin-IR-ComputeTermsFrequency>

=item * Search CPAN

L<http://search.cpan.org/dist/Mir-Plugin-IR-ComputeTermsFrequency/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2016 Marco Masetti.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

use Moose;
with 'Mir::R::Plugin';

use Lingua::Stem::Snowball;
use Log::Log4perl;

has 'log' => (
    is  => 'rw',
    isa => 'Log::Log4perl::Logger',
    default => sub { Log::Log4perl::get_logger( __PACKAGE__ ); }
);

#=============================================================

=head2 run

=head3 INPUT

An HashRef with the following keys:

    terms:  the list of terms to count the frequency
    doc:    the document profile with the text to analyze
    lang:   the language to use for the stemming
    exact_match:  a boolean flag to tell the plugin to consider
            exact match for the count (otherwise it applies 
            a case-insensitive and stemmed match.

=head3 OUTPUT

An HashRef with the new document profile. The new document profile
should contain this new attribute:

    terms => [{
        term  => t1,            # the original term found
        count => x,             # how many times...
        pages => [ 1, 2, 3,..]  # in which pages...
    }],


=head3 DESCRIPTION

This plugin just compute the frequency of a list of terms passed in input.
workflow:
    - for each query term:
        - for each document page text:
            - my $r = compute term frequency
            - terms->[t1]->{count} = scalar @$r
            - push @{ terms->[t1]->{pages} }, page_count

=cut

#=============================================================
sub run {
    my ( $self, $params ) = @_;

    my $lang = $params->{lang} // 'en';

    $params->{doc}->{terms} = [];
    foreach my $term ( @{ $params->{terms} } ) {
        my $page_num=1;
        my @pages = ();
        my $count = 0;
        foreach my $text ( @{ $params->{doc}->{text} } ) {
            my $r = $self->compute_term_frequency(
                $text, $term, $lang, $params->{exact_match}
            );
            if ( scalar @$r ) {
                push @pages, $page_num;
                $count += scalar @$r;
            }
            $page_num++;
        }
        push @{ $params->{doc}->{terms} }, {
            term    => $term,
            count   => $count,
            pages   => \@pages
        } if ( $count );
    }
    return $params->{doc};
}

#=============================================================

=head2 compute_term_frequency

=head3 INPUT

    $text   : the text to analyze
    $query  : the query string
    $lang   : the language for the stemming
    $exact_match : a flag to compute exact matching or stemming

=head3 OUTPUT

An ArrayRef.

=head3 DESCRIPTION

Returns a ref to a list of hashes like:
    {
        text => "Foo Bar"
    }

Representing all the substrings found in original text that
match the query terms.

=cut

#=============================================================
sub compute_term_frequency {
    my ( $self, $text, $query, $lang, $exact_match ) = @_;

    $text =~ tr/\./ /;
    $text =~ tr/,/ /;
    $text =~ tr/:/ /;
    $text =~ tr/;/ /;
    $text =~ tr/_/ /;
    my $text_terms_found = [];
    my @text_tokens_orig = split(' ', $text);
    my @text_tokens      = split(' ', lc $text);
    my @query_tokens     = split(' ', lc $query);

    unless ( $exact_match ) {
        my $stemmer = Lingua::Stem::Snowball->new( lang => $lang );
        $stemmer->stem_in_place( \@text_tokens );
        $stemmer->stem_in_place( \@query_tokens );
    }

    my $ret = [];

    if (scalar( @text_tokens ) >= scalar( @query_tokens ) ) {
        for ( my $i=0;$i<= (scalar @text_tokens - scalar @query_tokens);$i++) {
            my @text_string = ();
            for( my $j = 0; $j<scalar( @query_tokens );$j++) {
                if ( $text_tokens[$i+$j] eq $query_tokens[$j] ) {
                    $self->log->debug("Token \"$text_tokens_orig[$i+$j]\" found");
                    push @text_string, $text_tokens_orig[$i+$j];
                }
            }
            if ( scalar @text_string == scalar @query_tokens ) {
                push @$ret, {
                    text => join (' ', @text_string),
                }
            }
        }
    }
    return $ret;
}

1; # End of Mir::Plugin::IR::ComputeTermsFrequency
