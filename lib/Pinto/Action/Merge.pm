# ABSTRACT: Merge packages from one stack into another

package Pinto::Action::Merge;

use Moose;
use MooseX::Types::Moose qw(Bool Str);

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends 'Pinto::Action';

#------------------------------------------------------------------------------

with qw( Pinto::Role::Interface::Action::Merge );

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    my $from_stack = $self->repos->get_stack(name => $self->from_stack);
    my $to_stack   = $self->repos->get_stack(name => $self->to_stack);

    $self->notice("Merging stack $from_stack into stack $to_stack");

    my $did_merge = $from_stack->merge( to     => $to_stack,
                                        dryrun => $self->dryrun );

    $self->result->changed unless $self->dryrun;

    return $self->result;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#------------------------------------------------------------------------------

1;

__END__