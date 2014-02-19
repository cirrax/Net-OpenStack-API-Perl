package Net::OpenStack::Identity::Query;

use Moose;

use JSON qw(from_json to_json);

has type        => ( is => 'rw');
has page        => ( is => 'rw');
has per_page    => ( is => 'rw');
has interface   => ( is => 'rw');
has service_id  => ( is => 'rw');
has domain_id   => ( is => 'rw');
has name        => ( is => 'rw');
has enabled     => ( is => 'rw');
has email       => ( is => 'rw');

sub add {
  my ($self,$var, $value) = @_;
  $self->{$var}=$value;
}
sub remove {
  my ($self, $var) = @_;
  undef $self->{$var};
}

# Return query for API

sub all {
  my ($self) = @_;
  my $res='';

  foreach my $key (keys %{$self}) {
    $res = $res . '&' . $key . "="  . $self->{$key};
  }

  $res =~ s/^&/?/;
  return $res;
}



# ABSTRACT: Administrate queries for Identity API

=head1 SYNOPSIS

    use Net::OpenStack::Identity::Query;

    my $query= Net::OpenStack::Identity::Query->new();


=head1 DESCRIPTION

=cut

1;
