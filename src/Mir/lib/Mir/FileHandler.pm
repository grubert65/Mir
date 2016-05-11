# ABSTRACT: A module to handle files and folders...

package Mir::FileHandler;

use 5.010;
use Moose;
no warnings 'experimental::smartmatch';
use feature 'state';
use DirHandle;
use File::Find;
use File::Basename qw( dirname );
use Log::Log4perl;
use Redis;
use Digest::MD5 'md5_base64';

=head1 NAME

Mir::FileHandler - An Mir module to handle files and folders...

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';
our @rec_files = ();
our $files_as_hash = {};
our @types = ();
our $log = Log::Log4perl->get_logger( __PACKAGE__ );

=head1 SYNOPSIS

    use Mir::FileHandler;

    # the oo way...
    # get a new FileHandler obj for the passed root directory
    my $o = Mir::FileHandler->new( 
        path => $path, # root folder to start with 
    );


    # get plain files list inside the root directory
    my $list = $o->plainfiles(); # or pass a path in input

    # get plain files list from folder and sub-folders
    my $list = $o->plainfiles_recursive( $path, $suffix, \&found );

    # Traverses a directory tree and exec code for each file
    $o->count(0);      # reset counter
    $o->dir_walk(
        path => $path,
        code => $code,
    );

    # Traverses a directory tree and exec code for each file
    # Stops after max success code execution
    # the sub pointed by $code has to return 1 in
    # case of success
    # if cached_dir is set, at each iteration starts from 
    # what stored in cache, if something has been stored,
    # otherwise starts from path
    $o->count(0);      # reset counter
    $o->clear_cache(); # to clear current dir stored in cache
    $o->dir_walk_max(
        path => $path,
        code => $code, # not mandatory, code to exec for each file found
        max  => $max,  # not mandatory, max files successfully processed
        cached_dir => 1# not mandatory, if set 
    );

=head1 EXPORT

=over 

=item plainfiles

=item plainfiles_recursive

=back

=head1 SUBROUTINES/METHODS

=cut

#=============================================================

has 'path' => ( 
    is => 'rw', 
    isa => 'Str', 
    required => 1 
);

has 'cache_key' => (
    is  => 'rw',
    isa => 'Str',
);

has 'cache' => (
    is  => 'ro',
    isa => 'Redis',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $o = Redis->new();
        $o->select(11);
        return $o;
    }
);

has 'count' => (
    is  => 'rw',
    isa => 'Int',
    default => sub { 0 },
);

sub BUILD {
    my $self = shift;
    $self->cache_key( md5_base64( $self->path ) );
}

#=============================================================

=head2 plainfiles

=head3 INPUT

    $path: path to look for (not mandatory, eventually takes the
            one passed at construction time)

=head3 OUTPUT

An ArrayRef

=head3 DESCRIPTION

Returns the list of folder plain files.

=cut

#=============================================================
sub plainfiles {
    my $self = shift;

    return undef unless ( -e $self->path );
    return [ _pf( $self->path ) ];
}

#=============================================================

=head2 _pf

=head3 INPUT

    $path: the path to look for docs

=head3 OUTPUT

A sorted list of docs.

=head3 DESCRIPTION

Private function. Returns the sorted list of regular
files in current folder.

=cut

#=============================================================
sub _pf {
    my $dir = shift or return undef;
    my $dh = DirHandle->new($dir) or die "can't opendir $dir: $!";
    return sort
           grep { -f       }
           map { "$dir/$_" }
           grep { !/^\./   }
           $dh->read();
}

#=============================================================

=head2 _get_path_from_cache

=head3 INPUT

None

=head3 OUTPUT

The cache path or undef

=head3 DESCRIPTION

Tries to retrieve a current path cached for the root one or 
returns undef

=cut

#=============================================================
sub _get_path_from_cache {
    my $self = shift;
    return $self->cache->get( $self->cache_key );
}

sub _set_path_in_cache {
    my ( $self, $path ) = @_;
    $log->debug("SETTING $path IN CACHE...");
    return $self->cache->set( $self->cache_key, $path );
}

sub clear_cache {
    my $self = shift;
    $self->cache->del( $self->cache_key );
    return 1;
}

#=============================================================

=head2 dir_walk - traverses recursively a folder

=head3 INPUT

An hash with keys:
    top :   the folder to start with
    code:   a coderef to apply to

=head3 OUTPUT

-1 if root file or folder are not existent, else
the number of valid files.

=head3 DESCRIPTION

Traverse a directory, triggering a sub for each file found.
The sub should return 1 if file is good, 0 otherwise.
It is meant to recursively process a folder in one shot.
This is the minimal logic to traverse a tree, for added,
features look at dir_walk_max.

=cut

#=============================================================
sub dir_walk {
    my ( $self, %params ) = @_;
    my $top  = $params{top};
    my $code = $params{code};
    
    $log->error("File or folder $top not existent") && return -1
        unless ( -e $top );

    my $DIR;
    unless (opendir $DIR, $top) {
        $log->error( "Couldn’t open directory $top: $!" );
        return;
    }
    my $file;
    while ($file = readdir $DIR) {
        my $item = "$top/$file";
        if ( -f $item ) {
            $self->{count} += $code->($item);
        } elsif (-d $item ) {
            next if $file eq '.' || $file eq '..';
            $self->dir_walk( 
                top  => $item, 
                code => $code 
            );
        }
    }
    closedir $DIR;
    return 1;
}

#=============================================================

=head2 dir_walk_max - traverses recursively a folder, stops after
                      max valid files found

=head3 INPUT

An hash with keys:
    code:   a coderef to apply to
    max:    max number of items to evaluate
    dir_cached: if current folder needs to be cached and used as starting
            folder at next iteration;

=head3 OUTPUT

-1 if root file or folder are not existent, else
the number of valid files.

=head3 DESCRIPTION

Traverse a directory, triggering a sub for each file found.
The sub should return 1 if file is good, 0 otherwise.
The method stops when all files are consumed or max number
of good files is reached.
If the dir_cached param is set, it fetches the current folder from
cache, otherwise starts from the configured path

=cut

#=============================================================
sub dir_walk_max {
    my ( $self, %params ) = @_;

    my $top        = $params{top};
    my $code       = $params{code};
    my $max        = $params{max};
    my $cached_dir = $params{cached_dir};
    state $first   = 1;
    state $level   = 0;
    state $cache_set=1;

    $level++;
    # we start getting folder from cache if cached_dir param
    # is set...
    if ( $first && $cached_dir ) {
        undef $first;
        my $cached_dir = $self->_get_path_from_cache();
        $top = ( $cached_dir ) ? $cached_dir : $top;
    }
    
    $log->error("File or folder $top not existent") && return -1
        unless ( -e $top );

    my $DIR;
    unless (opendir $DIR, $top) {
        $log->error( "Couldn’t open directory $top: $!" );
        return;
    }
    my $file;
    while ($file = readdir $DIR) {
        my $item = "$top/$file";
        if ( -f $item ) {
            if ( $max && ( $self->{count} >= $max )) {
                $self->_set_path_in_cache( dirname ($top) ) if ( $cached_dir && $cache_set);
                $cache_set = 0;
                last;
            }
            $self->{count} += $code->($item);
        } elsif (-d $item ) {
            next if $file eq '.' || $file eq '..';
            $self->dir_walk_max( 
                top         => $item, 
                code        => $code, 
                max         => $max,
                cached_dir  => $cached_dir
            );
        }
    }
    closedir $DIR;
    $level--;
    if ( ( $level == 0 ) && ( $max && ( $self->{count} < $max ) ) ) {
        # going to exit as no more files are there
        # we clear cache so to force restart from 
        # scratch...
        $log->debug("Clearing cache..");
        $self->clear_cache();
    }
    return 1;
}

#=============================================================

=head2 plainfiles_recursive

=head3 INPUT

    $path:      a path to start from.
    $avoid:     arrayref con lista risorse da evitare
    $suffix:    arrayref con lista suffissi da processare
    $found:     ref sub callback per ogni risorsa

=head3 OUTPUT

    An arrayref.

=head3 DESCRIPTION

    Returns recursively the list of all files from passed folder.

=cut

#=============================================================
sub plainfiles_recursive {
    my ( $self, $path, $found ) = @_;

    my $dir = ( $self && ref $self ) ? $path || $self->{path} : $path;
    return undef unless $dir;

    $found = \&_found unless $found;

    @rec_files = ();
    find ( $found, ( $dir ) );
    return \@rec_files;
}

sub _found {
    return if ( -d );
    if ( -f  && !/^\./ && !/\~$/ ) {
        push @rec_files, $File::Find::name;
    }
}

sub _collect_as_hash {
    return if ( -d && /\.svn/ );
    if ( -f && !/^\./ && !/\~$/ ) {
        if ( m|(\w+)\.(\w+)$| ) {
            push @{ $files_as_hash->{ $2 } }, $File::Find::name;
        }
    }
}

sub _collect_of_type {
    return if ( -d && /\.\w+/ );
    if ( -f && !/^\./ && !/\~$/ ) {
        if ( m|(\w+)\.(\w+)$| ) {
            if ( $2 ~~ @types ) {
            push @rec_files, $File::Find::name;
            }
        }
    }
}

#=============================================================

=head2 plainfiles_recursive_as_hash

=head3 INPUT

    $path : root path (not mandatory if already passed at 
            construction time)

=head3 OUTPUT

An HashRef.

=head3 DESCRIPTION

Recursively collects files in an hash indexed by file suffix.

=cut

#=============================================================
sub plainfiles_recursive_as_hash {
    my ( $self, $path ) = @_;

    my $dir = ( $self && ref $self ) ? $path || $self->{path} : $path;
    return undef unless $dir;

    $files_as_hash = {};
    $self->plainfiles_recursive( $dir, \&_collect_as_hash );

#    foreach my $file ( @$rec_files ) {
#        if ( $file =~ m|(\w+)\.(\w+)$| ) {
#            push @{ $files_as_hash->{ $2 } }, $file;
#        }
#    }

    return $files_as_hash;
}

#=============================================================

=head2 plainfiles_recursive_of_type

=head3 INPUT

    @types: list of valid file suffixes

=head3 OUTPUT

    An ArrayRef or undef in case of errors.

=head3 DESCRIPTION

    Recursively collects all files with valid suffixes

=cut

#=============================================================
sub plainfiles_recursive_of_type {
    my ( $self, @ptypes ) = @_;

    return undef unless $self->{path};

    @types = @ptypes;
    @rec_files = ();
    $self->plainfiles_recursive( $self->{path}, \&_collect_of_type );
    return \@rec_files;
}

#=============================================================

=head2 process_dir

=head3 INPUT

    $dir    : dir to start with
    $suffix : arrayref of valid file suffixes
    $depth  : depth in processing subdirs

=head3 OUTPUT

    An arrayref

=head3 DESCRIPTION

    Workflow:
    get a single dir as input and the level of recursions
    get the list of valid dir files and process them
    get the list of dir direct subdirs
    depth-- 
    if depth > 0
        call process_dir foreach subdir

=cut

#=============================================================
sub process_dir ($$) {

}

=head1 AUTHOR

Marco Masetti, C<< <marco.masetti at softeco.it> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-ishare-filehandler at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Mir-FileHandler>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Mir::FileHandler

=head1 LICENSE AND COPYRIGHT

Copyright 2013 Marco Masetti.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

no Moose;
__PACKAGE__->meta->make_immutable;
