package Mir::Fetch;
use Moose;
with 'Mir::R::Acq::Fetch::Spider';

sub get_docs {
    my $self = shift;

    return 1;
}

1;
