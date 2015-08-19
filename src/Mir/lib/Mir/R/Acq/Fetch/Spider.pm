package Mir::R::Acq::Fetch::Spider;
use Moose::Role;
use namespace::autoclean;
use HTTP::Cookies;
use WWW::Mechanize;
use HTML::TreeBuilder 5 -weak;  # ensure weak references in use

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

1;
