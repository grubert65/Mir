package Mir::R::Acq::Fetch::Spider;
use Moose::Role;
use namespace::autoclean;
use HTTP::Cookies;
use WWW::Mechanize;
use HTML::TreeBuilder 5 -weak;  # ensure weak references in use
use Data::GUID;
use File::Copy                  qw( move );

has 'cookie_jar'    => (
    is  => 'ro',
    isa => 'HTTP::Cookies',
    default => sub {
        return HTTP::Cookies->new (
            file        => './cookies.dat',
            autosave    => 1 );
    }
);

has 'mech' => (
    is  => 'ro',
    isa => 'WWW::Mechanize',
    default => sub { 
        my $self = shift;
        my $o = WWW::Mechanize->new(
            autocheck   => 0 ,
            cookie_jar  => $self->cookie_jar,
        ); 
        $o->agent_alias( 'Windows IE 6' );
        my $proxy_string = $ENV{HTTP_PROXY};
        if (defined $proxy_string) {
            $o->proxy(['http', 'https', 'ftp'], "http://".$proxy_string);
        }
        return $o;
    },
);

has 'tb' => (
    is  => 'ro',
    isa => 'HTML::TreeBuilder',
    default => sub { return HTML::TreeBuilder->new() },
);

has 'TEMP_DIR' => ( 
    is => 'rw', 
    isa => 'Str',
    default => '/tmp'
);

with 'Mir::R::Acq::Fetch';

#=============================================================

=head2 get_page

=head3 INPUT

    $url    : the page url

=head3 OUTPUT

=head3 DESCRIPTION

Get page url and compute the TreeBuilder obj.

=cut

#=============================================================
sub get_page {
    my ( $self, $url ) = @_;

    return undef unless $url;

    $self->log->debug("Page URL: $url");

    my $res = $self->mech->get( $url );
    return undef unless ( $res->is_success );

    $self->tb->parse_content( $self->mech->content );

    return $res;
}

#=============================================================

=head1 DownloadLink

=head2 INPUT
    $link :             link to be downloaded
    $type:              (not mandatory) file extension. If
                        not given, system will try to determine
                        it from its link
    $encoding:          file encoding (not mandatory)

=head2 OUTPUT
    $files:             reference of an array of hashes,
                        contanining file path and description
    $code:              HTTP code received

=head2 DESCRIPTION

    Downloads provided link

=cut

#=============================================================
sub DownloadLink
{
    my ($self, $link, $type, $encoding) = @_;

    my $mech = $self->mech;
    return unless $mech;

    my $basedir = $self->TEMP_DIR;
    my $file_entry = {};

    my $go = 1;
    my $try_number = 1;
    my $code = 200;

    # If type starts with '.', get rid of it
    $type =~ s/^\.// if defined $type;

    # Try to download file for three times, then give up
    while ($go) {
        my $response = $mech->get($link);
        $code = $response->code;
        if ( (not $mech->success()) || ($code !~ /2\d{2}/) )
        {
            $self->log->error("ERROR downloading link $link - received code ".$code) if (defined $self->log);
            $try_number++;  
            $go = 0 if $try_number > 3;
        } else {
            $go = 0;
        }
    }
    if ($try_number > 3) {
        $self->log->info ( "ERROR downloading link $link - exceeded max number of tries ") if (defined $self->log);
        return (undef, $code);
    }

    if ((not defined $type) && ($link =~ /.+\.(.+$)/)) {
        $type = $1 if length($1) <= 4;
    }

    my $guid = Data::GUID->new();
    my $file_name = $guid->as_string;
    my $file_path = $basedir."/".$file_name;
    open DOCUMENT, "> $file_path";
    if (defined $encoding) {
        binmode DOCUMENT, ":encoding($encoding)";
    }
    print DOCUMENT $mech->content();
    close DOCUMENT;

    # Check for correct file extension
    if ((not defined $type) || (length($type) > 4)) {
        my $old_type = $type if defined $type;
        $type = $self->CheckFileType("$file_path");
    }
    move ("$file_path", "$file_path.$type");

    $file_entry->{'path'} = $file_path.".$type";
    $file_entry->{'url'} = $link;
    
    # After download, go back to previous page 
    $mech->back();

    return ($file_entry, $code);
}

#=============================================================

=head1 GotoPage

=head2 INPUT
    $url:       target url

=head2 OUTPUT
    $ret:       0 (error) or 1 (success)

=head2 DESCRIPTION

    Gets URL. In case of a timeout, it tries 3 times before
    returning an error

=cut

#=============================================================
sub GotoPage
{
    my ($self, $url) = @_;
    return unless $url;

    my $mech = $self->mech;
    return unless $mech;

    my $go = 1;
    my $try_number = 1;

    $self->log->info("Getting url $url...") if (defined $self->log);

    # Try to load page for three times, then give up
    while ($go) {
        my $response = $mech->get( $url );
        if ( (not $mech->success()) || ($response->code !~ /2\d{2}/) ) {
            $self->log->info ( "ERROR getting URL $url, received code ".$response->code.
                        " - try number $try_number") if (defined $self->log);
            $try_number++;
            $go = 0 if $try_number > 3;
        } else {
            $go = 0;
        }
    }
    if ($try_number > 3) {
        $self->log->info ( "ERROR getting URL $url - exceeded max number of tries ") if (defined $self->log);
        return 0;
    }

    # Store current page in object
    delete $self->{ CURRENT_PAGE };
    $self->{ CURRENT_PAGE } = $mech->content();
    # Select root node
    my $root_node = HTML::TreeBuilder->new; 
    $root_node->parse($self->{ CURRENT_PAGE });
    $self->{ ROOT_NODE } = $root_node;

    return 1
}

#=============================================================

=head1 GetPageContent

=head2 INPUT

=head2 OUTPUT
    $page_html:       page source

=head2 DESCRIPTION

    Returns HTML source of currently loaded page.

=cut

#=============================================================
sub GetPageContent
{
    my ($self) = @_;

    my $mech = $self->mech;
    return 0 unless $mech;

    return $self->{ CURRENT_PAGE };
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

    Selects desired node, according to provided parameters.
    Note that if id is provided, tag must be defined too,
    otherwise id will be ignored.
    If provided, pattern parameter will further refine search
    according to passed string.
    Here follow possible combination of search parameters:
    - tag
    - tag, pattern
    - tag, id
    - tag, id, use_regex
    - tag, id, pattern
    - tag, id, pattern, use_regex

    Note that from_selected parameter can be added to all
    above combinations, thus starting search from currently
    selected node instead of root node.

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
                        if ($node =~ /$pattern/gi) {
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
sub SetCurrentNode
{
    my ($self, $node) = @_;

    return 0 if (not defined $node);

    $self->{ CURRENT_NODE } = [$node];

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
    my $guid = Data::GUID->new();
    my $info_file = $self->TEMP_DIR."/".$guid->as_string;
    my $cmd = "antiword $file 2> $info_file 1> /dev/null";
    my $ret = system($cmd);

    if (stat ($info_file))
    {
        open FILE_INFO, "< $info_file";
        read (FILE_INFO, $infos, (stat(FILE_INFO))[7]);
        close FILE_INFO;
        unlink $info_file;
        if ($infos =~ /excel/gi) {
            return 'xls';
        } elsif ($infos =~ /rich text format/gi) {
            return 'rtf';
        } elsif (($ret == 0) && ($infos eq '')) {
            return 'doc';
        }
    }

    if (($ret != 0) && (not defined $type)) {
        # If not successful, use catdoc
        $cmd = "catdoc -v \"$file\" > $info_file";
        $ret = system($cmd);
    }

    if (stat ($info_file))
    {
        open FILE_INFO, "< $info_file";
        read (FILE_INFO, $infos, (stat(FILE_INFO))[7]);
        close FILE_INFO;
        unlink $info_file;
        if ($infos =~ /This is document \(DOC\) file/gi) {
            return 'doc';
        }
    }

    # If no type was found, use File::Type
    if (not defined $type) {
        my $ft = File::Type->new();
        $type = $ft->mime_type($file);
    
        $type =~ s/.+\///;
        if ($type =~ /word/) {
            return "doc";
        }
        return $type;
    }

    return undef;
}

1;
