package Mir::Util::WebUtils::Mechanize;

use 5.006;
use strict;
use warnings;

=head1 NAME

Mir::Util::WebUtils::Mechanize - The great new Mir::Util::WebUtils!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Mir::Util::WebUtils;

    my $foo = Mir::Util::WebUtils->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS

=head2 function1

=cut

sub function1 {
}

=head2 function2

=cut

sub function2 {
}

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

use Moose;
with 'Mir::Util::R::WebUtils';

use Log::Log4perl               ();
use WWW::Mechanize              ();
use HTTP::Cookies               ();
use Time::HiRes                 qw(gettimeofday);
use HTML::TreeBuilder           ();
use Cache::FileCache            ();
use Archive::Extract            ();
use File::Basename              qw( dirname basename fileparse );
use File::Copy                  qw( move );
use Data::Dumper                qw(Dumper);
use PDF::Create                 ();

use base qw( Exporter );
use vars qw( $VERSION @ISA @EXPORT_OK %EXPORT_TAGS);
$VERSION = do { my @r = (q$Revision: 1 $ =~ /\d+/g); sprintf  "%02d", @r };

@EXPORT_OK = qw(
    LINK_NAME
    LINK_URL
);

%EXPORT_TAGS = (
    'LINK_OPT'    => [qw(
        LINK_NAME
        LINK_URL
    )],
);
use constant LINK_NAME              => 100;
use constant LINK_URL               => 101;


has 'MECH' => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        # Create and configure WWW::Mechanize object
        my $cookie_jar = HTTP::Cookies->new (
                                    file        => './cookies.dat',
                                    autosave    => 1,
        ) or die ("Error: unable to build a cookie jar...");
        WWW::Mechanize->new( 
                                autocheck   => 0 ,
                                cookie_jar  => $cookie_jar,
        ) or die ("Error: unable to build a WWW::Mechanize object...");
    }, 
);

sub BUILD {
    my $self = shift;
    $self->MECH->agent_alias( 'Windows IE 6' );

    # Set a default timeout of 30 seconds - can be changed 
    # via SetTimout method
    $self->MECH->timeout(30);

    # Create and set cache
    my $cache = new Cache::FileCache( { 'namespace' => $self->CACHE_NAME,
                                        'cache_root'=> $self->CACHE_DIR } );
    $self->CACHE($cache);
}


#=============================================================

=head1 SetTimeout

=head2 INPUT
    $timeout:       desired timeout (seconds)       

=head2 OUTPUT

=head2 DESCRIPTION

    Sets WWW::Mechanize object timeout to desired value

=cut

#=============================================================
sub SetTimeout
{
    my ($self, $timeout) = @_;

    my $mech = $self->MECH;
    return unless $mech;

    $mech->timeout($timeout);

    return 1;
}

#=============================================================

=head1 FollowLink

=head2 INPUT
    $pattern:  pattern matching desired link
    $field:    field to search for pattern (LINK_NAME or 
               LINK_URL)

=head2 OUTPUT

=head2 DESCRIPTION

    Follows specified link

=cut

#=============================================================
sub FollowLink
{
    my ($self, $pattern, $field) = @_;
    return unless $pattern;

    my $mech = $self->MECH;
    return unless $mech;

    my $go = 1;
    my $try_number = 1;

    my $link;
    if ($field == LINK_URL) {
        $link = $mech->find_link(url_regex => qr/(.*)$pattern(.*)/);
    } elsif ($field == LINK_NAME) {
        $link = $mech->find_link(text_regex => qr/(.*)$pattern(.*)/);
    }

    if (not defined $link) {
        $self->log->info("ERROR following link $pattern") if (defined $self->log);
        return undef;
    }

    # Try to load page for three times, then give up
    while ($go) {
        my $response;
        if ($field == LINK_URL) {
            $response = $mech->follow_link(url_regex => qr/(.*)$pattern(.*)/);
        } elsif ($field == LINK_NAME) {
            $response = $mech->follow_link(text_regex => qr/$pattern/);
        }
        if ( (not $mech->success()) || ($response->code !~ /2\d{2}/) ) {
            $self->log->info("ERROR following link $pattern - received code ".$response->code) if (defined $self->log);
            $try_number++;
            $go = 0 if $try_number > 3;
        } else {
            $go = 0;
        }
    }
    if ($try_number > 3) {
        $self->log->info ( "ERROR getting URL $link - exceeded max number of tries ") if (defined $self->log);
        return undef;
    }

    # Store current page in object
    $self->{ CURRENT_PAGE } = $mech->content();
    # Select root node
    my $root_node = HTML::TreeBuilder->new; 
    $root_node->parse($self->{ CURRENT_PAGE });
    $self->{ ROOT_NODE } = $root_node;

    return $link->url_abs();
}

#=============================================================

=head1 SelectFormByName

=head2 INPUT
    $name:  the form's name

=head2 OUTPUT
    $form:  HTML::Form object

=head2 DESCRIPTION

    Gets desired form

=cut

#=============================================================
sub SelectFormByName
{
    my ($self, $name) = @_;

    my $mech = $self->MECH;
    return unless $mech;

    my @forms = $mech->forms();
    if (scalar @forms == 0) {
        $self->log->info("ERROR finding form \'$name\'") if (defined $self->log);
        return undef;
    }

    return $forms[0];
}

#=============================================================

=head1 SelectForm

=head2 INPUT
    $name:  the form's name (not mandatory)

=head2 OUTPUT
    $form:  HTML::Form object

=head2 DESCRIPTION

    Gets desired form

=cut

#=============================================================
sub SelectForm
{
    my ($self, $name) = @_;

    my $mech = $self->MECH;
    return unless $mech;

    if (not defined $name) {
        my @forms = $mech->forms();
        if (scalar @forms == 0) {
            $self->log->info("ERROR finding form \'$name\'") if (defined $self->log);
            return undef;
        }
        return $forms[0];
    } else {
        return $mech->form_name($name);
    }
}

#=============================================================

=head1 SelectFormbyFields

=head2 INPUT
    $fields: Ref to an array of field names that the form 
             must contain

=head2 OUTPUT
    $form:  HTML::Form object

=head2 DESCRIPTION

    Gets desired form

=cut

#=============================================================
sub SelectFormByFields
{
    my ($self, $fields) = @_;

    my $mech = $self->MECH;
    return unless $mech;

    if (not defined $fields) {
        $self->log->error("ERROR Form fields not defined") if (defined $self->log);
        return undef;
    } else {
        my @forms = $mech->form_with_fields(@$fields);
        if (scalar @forms == 1) {
            return $forms[0];
        } else {
            return \@forms;
        }
    } 
}

#=============================================================

=head1 SelectFormByNumber

=head2 INPUT
    $number:  the form's number

=head2 OUTPUT
    $form:  HTML::Form object

=head2 DESCRIPTION

    Gets number-th form

=cut

#=============================================================
sub SelectFormByNumber
{
    my ($self, $number) = @_;

    my $mech = $self->MECH;
    return unless $mech;

    my $form;
    eval { $form = $mech->form_number($number); };
    if ($@) {
        $self->log->info("ERROR retrieving form number $number - $@") if (defined $self->log);
        return undef;
    }

    return $form;
}

#=============================================================

=head1 FillForm

=head2 INPUT
    $form:   the form
    $field:  the fields's name
    $value:  new field's value

=head2 OUTPUT

=head2 DESCRIPTION

    Fills desired field with given value

=cut

#=============================================================
sub FillForm
{
    my ($self, $form, $field, $value) = @_;
    
    my $mech = $self->MECH;
    return 0 unless $mech;

    $form->value($field, $value);

    return 1;
}

#=============================================================

=head1 SubmitForm

=head2 INPUT
    $form:   the form

=head2 OUTPUT

=head2 DESCRIPTION

    Submits form

=cut

#=============================================================
sub SubmitForm
{
    my ($self, $form, $button) = @_;
    
    my $mech = $self->MECH;
    return 0 unless $mech;

    my $go = 1;
    my $try_number = 1;

    # Try to submit form for three times, then give up
    my $request;
    my $response;
    my $input_button;

    if (not defined $button) {
#        $input_button = $form->find_input(undef, $button);
#    } else {
        $request = $form->make_request();
    }
    while ($go) {
        if (defined $button) {
            $response = $mech->click_button(value => $button);
        } else {
            $response = $mech->request($request);
        }
        if ( (not $mech->success) || ($response->code !~ /^2\d{2}/) ) {
            $self->log->info("ERROR submitting form \'$form\'") if (defined $self->log);
            $try_number++;
            $go = 0 if $try_number > 3;
        } else {
            $go = 0;
        }
    }
    if ($try_number > 3) {
        $self->log->info ( "ERROR submitting form - exceeded max number of tries ") if (defined $self->log);
        return 0;
    }

    # Store current page in object
    $self->{ CURRENT_PAGE } = $mech->content();
    # Select root node
    my $root_node = HTML::TreeBuilder->new; 
    $root_node->parse($self->{ CURRENT_PAGE });
    $self->{ ROOT_NODE } = $root_node;

    return 1;
}

#=============================================================

=head1 SubmitPage

=head2 INPUT

=head2 OUTPUT

=head2 DESCRIPTION

    Submits page

=cut

#=============================================================
sub SubmitPage
{
    my $self = shift;

    my $mech = $self->MECH;
    return unless $mech;

    my $go = 1;
    my $try_number = 1;

    # Try to submit page for three times, then give up
    while ($go) {
        my $response = $mech->submit();
        if ( (not $mech->success) || ($response->code !~ /^2\d{2}/) ) {
            $self->log->info("ERROR submitting page") if (defined $self->log);
            $try_number++;  
            $go = 0 if $try_number > 3;
            $mech->back();
        } else {
            $go = 0;
        }
    }
    if ($try_number > 3) {
        $self->log->info ( "ERROR submitting form - exceeded max number of tries ") if (defined $self->log);
        return 0;
    }

    # Store current page in object
    $self->{ CURRENT_PAGE } = $mech->content();
    # Select root node
    my $root_node = HTML::TreeBuilder->new; 
    $root_node->parse($self->{ CURRENT_PAGE });
    $self->{ ROOT_NODE } = $root_node;

    return 1;
}

#=============================================================

=head1 SubmitRequest

=head2 INPUT
    $req:                       HTTP::Req object

=head2 OUTPUT

=head2 DESCRIPTION

    Submits provided request

=cut

#=============================================================
sub SubmitRequest
{
    my ($self, $req) = @_;

    my $mech = $self->MECH;
    return unless $mech;

    my $go = 1;
    my $try_number = 1;

    # Try to submit page for three times, then give up
    while ($go) {
        my $response = $mech->request($req);
        if ( (not $mech->success) || ($response->code !~ /^2\d{2}/) ) {
            $self->log->info("ERROR submitting request") if (defined $self->log);
            $try_number++;  
            $go = 0 if $try_number > 3;
        } else {
            $go = 0;
        }
    }
    if ($try_number > 3) {
        $self->log->info ( "ERROR submitting form - exceeded max number of tries ") if (defined $self->log);
        return 0;
    }

    # Store current page in object
    $self->{ CURRENT_PAGE } = $mech->content();
    # Select root node
    my $root_node = HTML::TreeBuilder->new; 
    $root_node->parse($self->{ CURRENT_PAGE });
    $self->{ ROOT_NODE } = $root_node;

    return 1;
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

    my $mech = $self->MECH;
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

    my $file_name = $self->GenerateUUID();
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
        my $doc_handler = Softeco::Media::DocHandler->new();
        $type = $doc_handler->CheckFileType("$file_path");
    }
    move ("$file_path", "$file_path.$type");

    $file_entry->{'path'} = $file_path.".$type";
    $file_entry->{'url'} = $link;
    
    # After download, go back to previous page 
    $mech->back();

    return ($file_entry, $code);
}

1; # End of Mir::Util::WebUtils::Mechanize
