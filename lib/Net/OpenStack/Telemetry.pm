package Net::OpenStack::Telemetry;
use Moose;

use JSON qw(from_json to_json);


extends qw(Net::OpenStack::Base);
has '+service_name' => (is => 'ro', default => 'ceilometer' );

sub new_from_env {
    my ($self, %params) = @_;
    my $msg = "%s env var is required. Did you forget to source novarc?\n";
    die sprintf($msg, 'OS_AUTH_URL')
        unless $ENV{OS_AUTH_URL};
    die sprintf($msg, 'OS_USERNAME')
        unless $ENV{OS_USERNAME};
    die sprintf($msg, 'OS_PASSWORD')
        unless $ENV{OS_PASSWORD};
    my %env = (
        auth_url     => $ENV{OS_AUTH_URL},
        user         => $ENV{OS_USERNAME},
        password     => $ENV{OS_PASSWORD},
        project_id   => $ENV{OS_TENANT_NAME},
        region       => $ENV{OS_AUTH_REGION},
        endpoint_type => $ENV{OS_ENDPOINT_TYPE},
        is_rax_auth  => $ENV{NOVA_RAX_AUTH},
    );
    return Net::OpenStack::Telemetry->new(%env, %params);
}

# alarms
sub get_alarms {
  my ($self, $alarm, $filter) = @_;
  my $res;
  if ($alarm ne '') {
    $res = $self->_get($self->_url('v2', join('/', '/alarms', $alarm)) , $filter );
  } else {
    $res = $self->_get($self->_url('v2', '/alarms'), $filter );
  }
  return from_json($res->content);
}

sub put_alarms {
  my ($self, $alarm, $data) = @_;
  my $res;
  if ($alarm ne '') {
    # TODO: this does not work !
    $res = $self->_post($self->_url('v2', join('/', '/alarms', $alarm)),  $data );
  } else {
    $res = $self->_post($self->_url('v2', '/alarms'), $data );
  }
  return from_json($res->content);
}

sub delete_alarms {
  my ($self, $alarm) = @_;
  my $res = $self->_delete($self->_url('v2', join('/', '/alarms', $alarm)) );
  return $res->content;
}

sub get_state {
  my ($self, $alarm) = @_;
  my  $res = $self->_get($self->_url('v2', join('/','/alarms', $alarm, 'state') ));
  return $res->content;
}

sub put_state {
  my ($self, $alarm, $state) = @_;
  return 'Not yet implemented';
}

sub get_history {
  my ($self, $alarm) = @_;
  my  $res = $self->_get($self->_url('v2', join('/','/history', $alarm, 'state') ));
  return from_json($res->content);
}


# Meters
sub get_meters {
  my ($self, $meter, $filter) = @_;
  my $res;
  if ($meter ne '') {
    $res = $self->_get($self->_url('v2', join('/', '/meters', $meter)) , $filter );
  } else {
    $res = $self->_get($self->_url('v2', '/meters'), $filter );
  }
  return from_json($res->content);
}

sub put_meters {
  my ($self, $meter, $samples) = @_;
  # TODO: needs check, not sure if this is working !
  my  $res = $self->_post($self->_url('v2', join('/', '/meters', $meter)), $samples );
  return from_json($res->content);
}

sub get_statistics {
  my ($self, $meter, $filter) = @_;
  my $res = $self->_get($self->_url('v2', join('/', '/meters', $meter, 'statistics')) , $filter );
  return from_json($res->content);
}

# ressources
sub get_resources {
  my ($self, $resource, $filter) = @_;
  my $res = $self->_get($self->_url('v2', join('/', '/resources', $resource)) , $filter );
  return from_json($res->content);
}
  

# ABSTRACT: Bindings for the OpenStack Telemetry API.

=head1 SYNOPSIS

    use Net::OpenStack::Telemetry;

    my $telemetry= Net::OpenStack::Telemetry->new_from_env();

    my $telemetry = $telemetry->get_resources()


=head1 DESCRIPTION

This class is an interface to the OpenStack Telemetry API v2 (Ceilometer).
See: L<Telemetry API|http://api.openstack.org/api-ref-telemetry.html>
in the OpenStack Documention.

=cut


1;
