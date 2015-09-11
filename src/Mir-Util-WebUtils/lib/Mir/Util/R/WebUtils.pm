package Mir::Util::R::WebUtils;

use 5.006;
use strict;
use warnings;

=head1 NAME

Mir::Util::R::WebUtils - base role to handle web pages.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

This is the base role for handling and navigating web pages.
It provides all methods needed to navigate the DOM, plus some general 
utilities to read/write a cache, to check file types and to perform 
useful operations (check dates, handle items in an array, etc).
Note that this role does not retrieve page content from web, it 
must be set using SetPageContent method. 

    package My::Web::Class;
    use Moose;
    with 'Mir::Util::R::WebUtils';
    ...

=head1 EXPORT

Nothing to export

=head1 AUTHOR

Andrea Poggi, C<< <andrea.poggi at softeco.it> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-mir-util-webutils at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Mir-Util-WebUtils>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Mir::Util::WebUtils


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Mir-Util-WebUtils>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Mir-Util-WebUtils>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Mir-Util-WebUtils>

=item * Search CPAN

L<http://search.cpan.org/dist/Mir-Util-WebUtils/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2015 Andrea Poggi.

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

use Moose::Role;

use Log::Log4perl                           ();
use Time::HiRes                             qw(gettimeofday);
use HTML::TreeBuilder                       ();
use HTML::Parser                            ();
use Cache::FileCache                        ();
use Archive::Extract                        ();
use File::Basename                          qw( dirname basename fileparse );
use Data::Dumper                            qw(Dumper);
use PDF::Create                             ();
use File::Type                              ();
use File::Path                              qw( rmtree );
use HTML::Entities                          qw( decode_entities );
use Mir::Util::DocHandler::pdf              ();

use namespace::autoclean;

has 'TEMP_DIR' => ( 
    is => 'rw', 
    isa => 'Str',
    default => '/tmp'
);

has 'CACHE_DIR' => ( 
    is => 'rw', 
    isa => 'Str',
);

has 'CACHE_NAME' => ( 
    is => 'rw', 
    isa => 'Str',
);

has 'CACHE' => (
    is      => 'rw',
    isa     => 'Cache::FileCache',
);

has 'log' => (
    is      => 'ro',
    lazy    => 1,
    default => sub { Log::Log4perl->get_logger( __PACKAGE__ ); },
);

has 'params' => (
    is      => 'rw',
    isa     => 'HashRef',
    lazy    => 1,
    default => sub { return {} },
);

sub BUILD {
    my $self = shift;
    my $cache = new Cache::FileCache( { 'namespace' => $self->CACHE_NAME,
                                        'cache_root'=> $self->CACHE_DIR } );
    $self->CACHE($cache);
}

#=============================================================

=head1 GenerateUUID

=head2 INPUT

=head2 OUTPUT

=head2 DESCRIPTION

    Genereates a unique identifier based on current time

=cut

#=============================================================
sub GenerateUUID
{
    my ($seconds, $microseconds) = gettimeofday;
    return "$seconds".'_'."$microseconds";
}

#=============================================================

=head2 getSQLDate

=head3 INPUT

    $day:           day of pubblication (numeric)
    $month:         month of pubblication (literal)
    $year:          year of pubblication (numeric)

=head3 OUTPUT

    $pub_date:      date of pubblication (yyyy-mm-dd HH:mm:ss)

=head3 DESCRIPTION

    Converts date of pubblication into MySQL format

=cut

#=============================================================
sub getSQLDate
{
    my ($self, $day, $month, $year) = @_;

    my @months = ('gennaio', 'febbraio', 'marzo', 'aprile', 'maggio', 'giugno',
                  'luglio', 'agosto', 'settembre', 'ottobre', 'novembre', 'dicembre');
    my $month_number = 1;

    my $found = 0;
    foreach (@months) {
        if ($month =~ /$_/i) {
            $found = 1;
            last;
        }
        $month_number++;
    }

    return undef if not $found;

    $day = sprintf("%02d", $day);
    $month_number = sprintf("%02d", $month_number);
    $year = sprintf("%04d", $year);
    return "$year-$month_number-$day 00:00:00";
}

#=============================================================

=head1 GetItemIndex

=head2 INPUT
    $array:             input array
    $item:              input item

=head2 OUTPUT

=head2 DESCRIPTION

    Return index of item in array

=cut

#=============================================================
sub GetItemIndex
{
    my ($self, $array, $item) = @_;

    my $index = 0;
    my $found = 0;
    foreach (@$array) {
        if ($item eq $_) {
            $found = 1;
            last;
        }
        $index++;
    }

    return undef unless $found;
    return $index;
}

#=============================================================

=head1 SetPageContent

=head2 INPUT
    $page_html:       page source

=head2 OUTPUT

=head2 DESCRIPTION

    Stores provided page content in object

=cut

#=============================================================
sub SetPageContent
{
    my ($self, $page_html) = @_;

    $self->{ CURRENT_PAGE } = $page_html;

    # Select root node
    my $root_node = HTML::TreeBuilder->new; 
    $root_node->parse($self->{ CURRENT_PAGE });
    $self->{ ROOT_NODE } = $root_node;

    return 1;
}

#=============================================================

=head1 GetNodeContent

=head2 INPUT
    $pattern :   text pattern to be searched

=head2 OUTPUT
    $text:       node content

=head2 DESCRIPTION

    Gets desired content from specified node

=cut

#=============================================================
sub GetNodeContent
{
    my ($self, $pattern) = @_;
    my $text = [];

    # Get currently selected node
    my $start_node = $self->{ CURRENT_NODE };
    if (not defined $start_node) {
        $self->log->info("ERROR No node is currently selected") if (defined $self->log);
        return undef;
    }

    # Look for content
    foreach my $single_node (@$start_node) {
        $single_node->traverse(
            [
                sub {
                    my $node = $_[0];
                    if ($node =~ /$pattern/gi) {
                        push @$text, $1;
                    }
    
                    return HTML::Element::OK; 
                },
                undef
            ],
        );
    }
    
    return $text;
}

#=============================================================

=head1 GetLinks

=head2 INPUT
    $link_type:       link type
    $pattern:         link search pattern
    $from_root:       start from root node if 1, from selected
                      node otherwise

=head2 OUTPUT
    $links:           reference to an array of links

=head2 DESCRIPTION

    Gets links from specified node and its children

=cut

#=============================================================
sub GetLinks
{
    my ($self, $link_type, $pattern, $from_root) = @_;

    my $links = [];
    $pattern = '.*' if (not defined $pattern);

    my $start_node = undef;
    if (defined $from_root && $from_root == 1) {
        $start_node = [$self->{ ROOT_NODE }];
        if (not defined $start_node) {
            $self->log->info("ERROR No node is currently selected") if (defined $self->log);
            return undef;
        }
    } else {
        $start_node = $self->{ CURRENT_NODE };
        if (not defined $start_node) {
            $self->log->info("ERROR No node is currently selected") if (defined $self->log);
            return undef;
        }
    }

    # Look for links
    foreach my $node (@$start_node) {
        for (@{ $node->extract_links($link_type) }) {
            my ($link, $element, $attr, $tag) = @$_;
            push @$links, $link if ($link =~ /$pattern/g);
        }
    }
    
    return $links;
}

#=============================================================

=head1 SelectRightSibling

=head2 INPUT

    $node:          (not mandatory) Start node. If not defined,
                    currently provided node will be used

=head2 OUTPUT

=head2 DESCRIPTION

    Selects the right sibling of provided node or currently 
    selected node

=cut

#=============================================================
sub SelectRightSibling
{
    my $self = shift;
    my $node = shift;

    my $start_node;
    if (not defined $node) {
        my $nodes = $self->{ CURRENT_NODE };
        if (scalar @$nodes != 1) {
            $self->log->info("ERROR Invalid node selected") if (defined $self->log);
            return undef;
        }
        $start_node = $nodes->[0];
    } else {
        $start_node = $node;
    }

    my $right_node = $start_node->right();
    if (not defined $right_node) {
        $self->log->info("ERROR No rightmost node found") if (defined $self->log);
        return undef;
    }

    if (defined $right_node && ref $right_node eq 'HTML::Element') {
        $self->{ CURRENT_NODE } = [$right_node];
        return $right_node;
    } else {
        $self->log->error("ERROR No rightmost node found") if (defined $self->log);
        return undef;
    }
}

#=============================================================

=head1 SelectLeftSibling

=head2 INPUT

    $node:          (not mandatory) Start node. If not defined,
                    currently provided node will be used

=head2 OUTPUT

=head2 DESCRIPTION

    Selects the left sibling of provided node or currently 
    selected node

=cut

#=============================================================
sub SelectLeftSibling
{
    my $self = shift;
    my $node = shift;

    my $start_node;
    if (not defined $node) {
        my $nodes = $self->{ CURRENT_NODE };
        if (scalar @$nodes != 1) {
            $self->log->info("ERROR Invalid node selected") if (defined $self->log);
            return undef;
        }
        $start_node = $nodes->[0];
    } else {
        $start_node = $node;
    }

    my $left_node = $start_node->left();
    if (not defined $left_node) {
        $self->log->info("ERROR No leftmost node found") if (defined $self->log);
        return undef;
    }

    if (defined $left_node && ref $left_node eq 'HTML::Element') {
        $self->{ CURRENT_NODE } = [$left_node];
        return $left_node;
    } else {
        $self->log->error("ERROR No leftmost node found") if (defined $self->log);
        return undef;
    }
}

#=============================================================

=head1 GetCurrentNode

=head2 INPUT

=head2 OUTPUT
    $node :              currently selected node 

=head2 DESCRIPTION

    Returns currently selected node

=cut

#=============================================================
sub GetCurrentNode
{
    my $self = shift;

    return $self->{ CURRENT_NODE };
}

#=============================================================

=head1 SetCurrentNode

=head2 INPUT
    $node :              input node 

=head2 OUTPUT

=head2 DESCRIPTION

    Set passed node as current node

=cut

#=============================================================
sub SetCurrentNode
{
    my ($self, $node) = @_;

    return 0 if (not defined $node);

    $self->{ CURRENT_NODE } = [$node];

    return 1;
}

#=============================================================

=head1 SelectNode

=head2 INPUT
    $tag :              node tag
    $id:                node id
    $pattern:           pattern (regex) used to find matching nodes
    $from_selected:     if set to 1, start looking from selected 
                        node (error if not present); otherwise from
                        root node
    $use_regex:         if set to 1, use regex provided by "id"
                        field

=head2 OUTPUT
    $selected_nodes:    ref to an array of selected nodes

=head2 DESCRIPTION

    Selects desired node

=cut

#=============================================================
sub SelectNode
{
    my ($self, $tag, $id, $pattern, $from_selected, $use_regex) = @_;

    $use_regex = 0 if not defined $use_regex;

    # Create document tree
    my $start_node = undef;
    if (defined $from_selected && $from_selected == 1) {
        if (not defined $self->{ CURRENT_NODE }) {
            $self->log->error("ERROR No node is currently selected") if (defined $self->log);
            return undef;
        }
        if (scalar @{$self->{ CURRENT_NODE }} > 1) {
            $self->log->error("ERROR More than one node is currently selected") if (defined $self->log);
            return undef;
        }
        $start_node = $self->{ CURRENT_NODE }->[0];

    } else {
        $start_node = $self->{ ROOT_NODE };
        if (not defined $start_node) {
            my $page_html = $self->{ CURRENT_PAGE };
            if (not defined $page_html) {
                $self->log->error("ERROR No page is currently stored") if (defined $self->log);
                return undef;
            }
            $start_node = HTML::TreeBuilder->new; 
            $start_node->parse($page_html);
            if (not defined $start_node) {
                $self->log->error("ERROR Unable to build page tree") if (defined $self->log);
                return undef;
            }
        }
    }

    # Look for node
    my $selected_node = undef;
    my @selected_nodes;
    if (defined $tag && defined $id) {
        if ($use_regex) {
            @selected_nodes = $start_node->look_down($tag, qr/$id/);
        } else {
            @selected_nodes = $start_node->look_down($tag, $id);
        }
    } elsif (defined $tag) {
        @selected_nodes = $start_node->find_by_tag_name($tag);
    }
    if (scalar @selected_nodes == 0) {
        if (defined $id) {
            $self->log->info("ERROR Unable to find node \'$tag\' - \'$id\'") if (defined $self->log);
        } else {
            $self->log->info("ERROR Unable to find node \'$tag\'") if (defined $self->log);
        }
        return undef;
    }

    if (defined $pattern) {
        my $index = 0;
        foreach my $single_node (@selected_nodes) {
            $single_node->traverse(
                [
                    sub {
                        my $node;
                        if (ref $_[0] eq 'HTML::Element') {
                            $node = $_[0]->as_HTML();
                        } else {
                            $node = $_[0];
                        }
                        if ($node =~ /$pattern/g) {
                            $selected_node = $single_node unless defined $selected_node;
                        }
                        return HTML::Element::OK; 
                    },
                    undef
                ],
            );
            $index++;
        }
        return undef if (not defined $selected_node);
    }

    if (defined $selected_node) {
        $self->{ CURRENT_NODE } = [$selected_node];
        return $selected_node;
    } else {
        $self->{ CURRENT_NODE } = \@selected_nodes;
        return \@selected_nodes;
    }
}

#=============================================================

=head1 SelectDescendant

=head2 INPUT
    $number:            (not mandatory) Number of descendant
                        to be selected. If undef, first 
                        descendant will be selected

=head2 OUTPUT
    $selected_node:     selected node (undef if no descendant
                        is present)

=head2 DESCRIPTION

    Selects desired descendant node

=cut

#=============================================================
sub SelectDescendant
{
    my ($self, $number) = @_;

    my $start_node = $self->{ CURRENT_NODE };
    if (not defined $start_node) {
        $self->log->error("ERROR No node is currently selected") if (defined $self->log);
        return undef;
    }
    if (scalar @$start_node != 1) {
        $self->log->error("ERROR Invalid node is currently selected") if (defined $self->log);
        return undef;
    }

    my @descendants = $start_node->[0]->descendants();
    return undef if (scalar @descendants == 0);

    if (defined $number) {
        $self->{ CURRENT_NODE } = [$descendants[$number]];
        return $descendants[$number];
    } else {
        $self->{ CURRENT_NODE } = [$descendants[0]];
        return $descendants[0];
    }
}

#=============================================================

=head1 SelectParent

=head2 INPUT

=head2 OUTPUT
    $selected_node:     selected node

=head2 DESCRIPTION

    Selects desired parent node

=cut

#=============================================================
sub SelectParent
{
    my ($self) = @_;

    my $start_node = $self->{ CURRENT_NODE };
    if (not defined $start_node) {
        $self->log->error("ERROR No node is currently selected") if (defined $self->log);
        return undef;
    }
    if (scalar @$start_node != 1) {
        $self->log->error("ERROR Invalid node is currently selected") if (defined $self->log);
        return undef;
    }

    my $parent = $start_node->[0]->parent();
    return undef if (not defined $parent);

    $self->{ CURRENT_NODE } = [$parent];
    return $parent;
}

#=============================================================

=head1 Decompress

=head2 INPUT
    $file_path :        path to archive

=head2 OUTPUT
    $files:             reference of an array of file paths

=head2 DESCRIPTION

    Decompresses selected archive

=cut

#=============================================================
sub Decompress
{
    my ($self, $archive, $dest_folder) = @_;

    return 0 if ( ( ! $archive ) || ( ! stat $archive ) );

    # Extract files
    if (not defined $dest_folder) {
        $dest_folder = ".";
        if ($archive =~ /(.+)\..+/) {
            $dest_folder = $1;
        }
    }
    my $zip = Archive::Extract->new( archive => $archive );
    $zip->extract( to => $dest_folder );
    
    # Check for extracted files and return them
#    opendir(OUT_DIR, $dest_folder);
#    my @extracted_files = grep { /.+\..+/ && -f "$dest_folder/$_" } readdir(OUT_DIR);
#    closedir OUT_DIR;

    my $extracted_files = $zip->files;
    return $extracted_files;
}

#=============================================================

=head1 GetAttributeFromPage

=head2 INPUT
    $file:              file
    $desc_pattern :     description search pattern (array of 
                        regex)
    $attribute:         attribute
    $node:              node attribute
    $tag:               node value

=head2 OUTPUT

=head2 DESCRIPTION

    Uses specified patterns to retrieve information about 
    given document

=cut

#=============================================================
sub GetAttributeFromPage
{
    my ($self, $file, $desc_pattern, $attribute) = @_;

    my $attribute_found = 0;
    my $description = $self->GetNodeContent($desc_pattern->[0]);
    if ($description->[0] =~ /$desc_pattern->[1]/) {
        $file->{$attribute} = $2;
        $attribute_found = 1;
    }

    if (not $attribute_found) {
        $self->log->info("WARNING Unable to find attribute \'$attribute\' using pattern \'$desc_pattern\'") if (defined $self->log);
        return 0;
    }

    return $attribute_found;
}

#=============================================================

=head1 AddAttribute

=head2 INPUT
    $file:              file hash
    $attribute:         attribute name
    $value:             attribute value

=head2 OUTPUT

=head2 DESCRIPTION

    Adds attribute to document

=cut

#=============================================================
sub AddAttribute
{
    my ($self, $file, $attribute, $value) = @_;

    $file->{$attribute} = $value;

    return 1;
}

#=============================================================

=head1 GetFormData

=head2 INPUT
    $form:          the form
    $field:         desired input field
    $type:          1 for scalar input, undef for array

=head2 OUTPUT

=head2 DESCRIPTION

    Returns a reference to an array containing all input
    choices for specified field

=cut

#=============================================================
sub GetFormData
{
    my ($self, $form, $field, $type) = @_;

    my $input = $form->find_input($field);
    if (not defined $input) {
        $self->log->info("ERROR Unable to find field \'$field\'") if (defined $self->log);
        return undef;
    }

    if ($type) {
        my $value = $input->value();
        
        return $value;
    } else {
        my @values = $input->value_names;
    
        # Remove first empty value, if necessary
        if (scalar @values > 0 && $values[0] eq '') {
            shift @values;
        }
    
        return \@values;
    }
}

#=============================================================

=head1 GetFormValues

=head2 INPUT
    $form:          the form
    $field:         desired input field

=head2 OUTPUT

=head2 DESCRIPTION

    Returns a reference to an array containing all input
    values for specified field

=cut

#=============================================================
sub GetFormValues
{
    my ($self, $form, $field) = @_;

    my $input = $form->find_input($field);
    if (not defined $input) {
        $self->log->info("ERROR Unable to find field \'$field\'") if (defined $self->log);
        return undef;
    }

    my @values = $input->possible_values;

    return \@values;
}

#=============================================================

=head1 ReadCache

=head2 INPUT
    $param:         param

=head2 OUTPUT
    $value:         value read from cache

=head2 DESCRIPTION

    Returns the value of the param previously stored in cache

=cut

#=============================================================
sub ReadCache
{
    my ($self, $param) = @_;

    my $cache = $self->{ CACHE };
    if (not defined $cache) {
        $self->log->info("ERROR No cache object defined") if (defined $self->log); 
        return undef;
    }

    my $value = $cache->get($param);

    return $value;
}

#=============================================================

=head1 WriteCache

=head2 INPUT
    $param:         param
    $value:         value of param

=head2 OUTPUT

=head2 DESCRIPTION

    Writes the value of the param to cache

=cut

#=============================================================
sub WriteCache
{
    my ($self, $param, $value) = @_;

    my $cache = $self->{ CACHE };
    if (not defined $cache) {
        $self->log->info("ERROR No cache object defined") if (defined $self->log); 
        return undef;
    }

    $cache->set($param, $value);

    return 1;
}

#=============================================================

=head1 DeleteFromCache

=head2 INPUT
    $param:         param

=head2 OUTPUT

=head2 DESCRIPTION

    Deletes the param from cache

=cut

#=============================================================
sub DeleteFromCache
{
    my ($self, $param) = @_;

    my $cache = $self->{ CACHE };
    if (not defined $cache) {
        $self->log->info("ERROR No cache object defined") if (defined $self->log); 
        return undef;
    }

    $cache->remove($param);

    return 1;
}

#=============================================================

=head1 CreatePDF

=head2 INPUT
    $title:         document title
    $fields:        document fields
    $path:          document path

=head2 OUTPUT
    $ret:           1 if successful, 0 otherwise

=head2 DESCRIPTION

    Creates a PDF document out of provided data

=cut

#=============================================================
sub CreatePDF
{
    my ($self, $title, $fields, $path) = @_;

    my $ret = 1;
    my $y_header = 800;
    my $y_body = 650;

    my $pdf = new PDF::Create('filename'        => $path,
                              'Version'         => 1.2,
                              'PageMode'        => 'UseOutLines',
                              'Author'          => 'Softeco Sismat S.p.A.',
                              'CreationDate'    => [ localtime ]
                              );

    return 0 unless defined $pdf;

    my $root = $pdf->new_page('MediaBox' => $pdf->get_page_size('A4'));
    my $page = $root->new_page();
    my $f1 = $pdf->font('Subtype'  => 'Type1',
                        'Encoding' => 'WinAnsiEncoding',
                        'BaseFont' => 'Helvetica');

    # Print title
    my $header = $title;
    $page->stringc($f1, 20, 306, $y_header, $header);

    # Print body
    foreach my $field (@$fields) {
        my $body = '';
        if ($field ne '') {
            my @words = split(/ /, $field);
            while (scalar @words > 0) {
                $body = '';
                while ( (length($body) < 70) && (scalar @words > 0) ) {
                    $body .= " ".shift(@words);
                }
                $page->string($f1, 12, 20, $y_body, $body);
                $y_body -= 25;
            }
        } else {
            $page->string($f1, 12, 20, $y_body, $body);
            $y_body -= 25;
        }
    }

    $pdf->close;

    return 1;
}

#=============================================================

=head1 CheckFileType

=head2 INPUT
    $file:          full path to file

=head2 OUTPUT
    $ret:           file type if successful, undef otherwise

=head2 DESCRIPTION

    Checks for file type

=cut

#=============================================================
sub CheckFileType
{
    my ($self, $file) = @_;

    if (not stat $file) {
        $self->log->error("Cannot open file $file");
        return undef;
    }

    my $type;

    # Check for Excel and Word documents
    my $infos;
    my $info_file = $self->TEMP_DIR."/".GenerateUUID();
    my $cmd = "antiword $file 2> $info_file 1> /dev/null";
    my $ret = system($cmd);

    if (($ret != 0) && ($ret != 256)) {
        $self->log->error("Error while retrieving file type - Is Antiword
                        installed?");
        return undef;
    }

    if (stat ($info_file))
    {
        open FILE_INFO, "< $info_file";
        read (FILE_INFO, $infos, (stat(FILE_INFO))[7]);
        close FILE_INFO;
        unlink $info_file;
        if ($infos =~ /excel/gi) {
            $type = 'xls';
        } elsif ($infos =~ /rich text format/gi) {
            $type = 'rtf';
        } elsif (($ret == 0) && ($infos eq '')) {
            $type = 'doc';
        }
    }

    if (($ret != 0) && (not defined $type)) {
        # If not successful, use catdoc
        $cmd = "catdoc -v \"$file\" > $info_file";
        $ret = system($cmd);
        if (stat ($info_file))
        {
            open FILE_INFO, "< $info_file";
            read (FILE_INFO, $infos, (stat(FILE_INFO))[7]);
            close FILE_INFO;
            unlink $info_file;
            if ($infos =~ /This is document \(DOC\) file/gi) {
                $type = 'doc';
            }
        }
    }


    # Check for PDF (use DocHandler::pdf)
    if (not defined $type) {
        my $doc = Mir::Util::DocHandler::pdf->new();
        if (defined $doc) {
            $type = 'pdf' if ($doc->open_doc($file));        
        }
    
        # If no type was found, use File::Type
        if (not defined $type) {
            my $ft = File::Type->new();
            $type = $ft->mime_type($file);
        
            $type =~ s/.+\///;
            if ($type =~ /word/) {
                $type = "doc";
            }
        }
    }

    return $type;
}

1; # End of Mir::Util::WebUtils
