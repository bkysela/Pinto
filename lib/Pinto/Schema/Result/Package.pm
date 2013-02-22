use utf8;
package Pinto::Schema::Result::Package;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Pinto::Schema::Result::Package

=cut

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

=head1 TABLE: C<package>

=cut

__PACKAGE__->table("package");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 name

  data_type: 'text'
  is_nullable: 0

=head2 version

  data_type: 'text'
  is_nullable: 0

=head2 file

  data_type: 'text'
  default_value: null
  is_nullable: 1

=head2 sha256

  data_type: 'text'
  default_value: null
  is_nullable: 1

=head2 distribution

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "name",
  { data_type => "text", is_nullable => 0 },
  "version",
  { data_type => "text", is_nullable => 0 },
  "file",
  { data_type => "text", default_value => \"null", is_nullable => 1 },
  "sha256",
  { data_type => "text", default_value => \"null", is_nullable => 1 },
  "distribution",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<name_distribution_unique>

=over 4

=item * L</name>

=item * L</distribution>

=back

=cut

__PACKAGE__->add_unique_constraint("name_distribution_unique", ["name", "distribution"]);

=head1 RELATIONS

=head2 distribution

Type: belongs_to

Related object: L<Pinto::Schema::Result::Distribution>

=cut

__PACKAGE__->belongs_to(
  "distribution",
  "Pinto::Schema::Result::Distribution",
  { id => "distribution" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "NO ACTION" },
);

=head2 registrations

Type: has_many

Related object: L<Pinto::Schema::Result::Registration>

=cut

__PACKAGE__->has_many(
  "registrations",
  "Pinto::Schema::Result::Registration",
  { "foreign.package" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head1 L<Moose> ROLES APPLIED

=over 4

=item * L<Pinto::Role::Schema::Result>

=back

=cut


with 'Pinto::Role::Schema::Result';


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-02-21 23:16:38
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:gGO966ZU3WAbznrH044TYA

#------------------------------------------------------------------------------

# ABSTRACT: Represents a Package provided by a Distribution

#------------------------------------------------------------------------------

use String::Format;

use Pinto::Util qw(itis);
use Pinto::Exception qw(throw);
use Pinto::PackageSpec;

use overload ( '""'     => 'to_string',
               '<=>'    => 'numeric_compare',
               'cmp'    => 'string_compare',
               fallback => undef );

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------


__PACKAGE__->inflate_column( 'version' => { inflate => sub { version->parse($_[0]) },
                                            deflate => sub { $_[0]->stringify() } }
);

#------------------------------------------------------------------------------
# Schema::Loader does not create many-to-many relationships for us.  So we
# must create them by hand here...

__PACKAGE__->many_to_many( kommits => 'registration', 'kommit' );

#------------------------------------------------------------------------------

sub sqlt_deploy_hook {
    my ($self, $sqlt_table) = @_;
 
    $sqlt_table->add_index(name => 'package_idx_name',   fields => ['name']);
    $sqlt_table->add_index(name => 'package_idx_file',   fields => ['file']);
    $sqlt_table->add_index(name => 'package_idx_sha256', fields => ['sha256']);

    return;
}

#------------------------------------------------------------------------------

sub FOREIGNBUILDARGS {
    my ($class, $args) = @_;

    $args ||= {};
    $args->{version} = 0 if not defined $args->{version};

    return $args;
}

#------------------------------------------------------------------------------

sub register {
    my ($self, %args) = @_;

    my $stack = $args{stack};
    my $pin   = $args{pin};

    # HACK: poke inside the object to get our own dist id.
    # This avoids having to requery the DB for the whole object.
    my $dist_id = $self->{_column_data}->{distribution};

    my $struct = { kommit       => $stack->head,
                   is_pinned    => $pin,
                   package_name => $self->name,
                   distribution => $dist_id };

    $self->create_related( registrations => $struct );

    return $self;
}

#------------------------------------------------------------------------------

sub registration {
    my ($self, %args) = @_;

    my $stack = $args{stack};
    my $where = {kommit => $stack->head->id};
    my $attrs = {key    => 'kommit_package_unique'};

    return $self->find_related('registrations', $where, $attrs);
}

#------------------------------------------------------------------------------

sub mtime {
    my ($self) = @_;

    return $self->distribution->mtime;
}

#------------------------------------------------------------------------------

sub path {
    my ($self) = @_;

    return $self->distribution->path;
}

#------------------------------------------------------------------------------

sub vname {
    my ($self) = @_;

    return $self->name() . '~' . $self->version();
}

#------------------------------------------------------------------------------

sub as_spec {
    my ($self) = @_;

    return Pinto::PackageSpec->new( name    => $self->name,
                                    version => $self->version );
}

#------------------------------------------------------------------------------

sub as_struct {
    my ($self) = @_;

    return ( name         => $self->name,
             version      => $self->version,
             distribution => $self->path,
             mtime        => $self->mtime, );
}

#------------------------------------------------------------------------------

sub to_string {
    my ($self, $format) = @_;

    # my ($pkg, $file, $line) = caller;
    # warn __PACKAGE__ . " stringified from $file at line $line";

    my %fspec = (
         'p' => sub { $self->name()                                   },
         'P' => sub { $self->vname()                                  },
         'v' => sub { $self->version->stringify()                     },
         'm' => sub { $self->distribution->is_devel()   ? 'd' : 'r'   },
         'h' => sub { $self->distribution->path()                     },
         'H' => sub { $self->distribution->native_path()              },
         'f' => sub { $self->distribution->archive                    },
         's' => sub { $self->distribution->is_local()   ? 'l' : 'f'   },
         'S' => sub { $self->distribution->source()                   },
         'a' => sub { $self->distribution->author()                   },
         'A' => sub { $self->distribution->author_canonical()         },
         'd' => sub { $self->distribution->name()                     },
         'D' => sub { $self->distribution->vname()                    },
         'V' => sub { $self->distribution->version()                  },
         'u' => sub { $self->distribution->url()                      },
    );

    # Some attributes are just undefined, usually because of
    # oddly named distributions and other old stuff on CPAN.
    no warnings 'uninitialized';  ## no critic qw(NoWarnings);

    $format ||= $self->default_format();
    return String::Format::stringf($format, %fspec);
}


#-------------------------------------------------------------------------------

sub default_format {
    my ($self) = @_;

    return '%A/%D/%P';  # AUTHOR/DIST_VNAME/PKG_VNAME
}

#-------------------------------------------------------------------------------

sub numeric_compare {
    my ($pkg_a, $pkg_b) = @_;

    my $class = __PACKAGE__;
    throw "Can only compare $class objets"
        unless itis($pkg_a, $class) && itis($pkg_b, $class);

    throw "Cannot compare packages with different names: $pkg_a <=> $pkg_b"
        if $pkg_a->name ne $pkg_b->name;

    return 0 if $pkg_a->id == $pkg_b->id;

    return    ($pkg_a->version <=> $pkg_b->version)
           || ($pkg_a->mtime   <=> $pkg_b->mtime)
           || throw "Unable to determine ordering $pkg_a <=> $pkg_b";
}

#-------------------------------------------------------------------------------

sub string_compare {
    my ($pkg_a, $pkg_b) = @_;


    return    ( $pkg_a->name    cmp $pkg_b->name    )
           || ( $pkg_a->version <=> $pkg_b->version );

}

#-------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#-------------------------------------------------------------------------------
1;

__END__

