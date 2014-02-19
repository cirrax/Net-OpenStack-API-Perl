package Net::OpenStack::Identity;
use Moose;

use Data::Dumper;

use JSON qw(from_json to_json);

extends qw(Net::OpenStack::Base);
has '+service_name' => (is => 'ro', default => 'keystone' );

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
    return Net::OpenStack::Identity->new(%env, %params);
}

########## Versions
sub get_version {
    my ($self) = @_;
    my $res = $self->_get($self->_url('v3', '' ));
    return from_json($res->content)->{version};
}

########## Service Catalog

sub get_services {
  my ($self,$service, $query) = @_;
  my $res;
  if ($service ne '') {
    $res = $self->_get($self->_url('v3', '/services/' . $service ));
    return from_json($res->content)->{service};
  } elsif (defined($query)) {
    $res = $self->_get($self->_url('v3', '/services' .  $query ));
    return from_json($res->content)->{services};
  } else {
    $res = $self->_get($self->_url('v3', '/services' ));
    return from_json($res->content)->{services};
  }
}

########## Endpoints
sub get_endpoints {
  my ($self, $query) = @_;
  my $res; 
  if (defined($query)){ 
    $res = $self->_get($self->_url('v3', '/endpoints' . $query ));
  } else {
    $res = $self->_get($self->_url('v3', '/endpoints' ));
  }
  return from_json($res->content)->{endpoints};
}


########## Projects
sub add_project {
    my ($self, $params) = @_;
    my $url= $self->_url('v3', '/projects');
    my $res = $self->_post( $url , { project => $params }  );
    return from_json($res->content)->{project};
}

sub delete_project {
    my ($self, $project_id) = @_;
    my $res = $self->_delete($self->_url('v3', '/projects/' . $project_id));
    return $res->{_content};
}

sub get_projects {
  my ($self,$service, $query) = @_;
  my $res;
  if ( $service ne '' ) {
    $res = $self->_get($self->_url('v3', '/projects/' . $service) );
    return from_json($res->content)->{project};
  } elsif (defined($query)){ 
    $res = $self->_get($self->_url('v3', '/projects' . $query) );
    return from_json($res->content)->{projects};
  } else {
    $res = $self->_get($self->_url('v3', '/projects' ) );
    return from_json($res->content)->{projects};
  }
}

########## Users

sub get_users {
  my ($self,$user, $query) = @_;
  my $res;
  if ( $user ne '' ) {
    $res = $self->_get($self->_url('v3', '/users/' . $user) );
    return from_json($res->content)->{user};
  } elsif (defined($query)){ 
    $res = $self->_get($self->_url('v3', '/users' . $query) );
    return from_json($res->content)->{users};
  } else {
    $res = $self->_get($self->_url('v3', '/users' ) );
    return from_json($res->content)->{users};
  }
}

sub get_user_groups {
    my ($self, $user) = @_;
    my $res = $self->_get($self->_url('v3', '/users/' . $user . '/groups' ));
    return from_json($res->content)->{groups};
}

sub get_user_projects {
    my ($self, $user) = @_;
    my $res = $self->_get($self->_url('v3', '/users/' . $user . '/projects' ));
    return from_json($res->content)->{projects};
}

sub get_user_roles {
    my ($self, $user) = @_;
    my $res = $self->_get($self->_url('v3', '/users/' . $user . '/roles' ));
    return from_json($res->content);
}

# ABSTRACT: Bindings for the OpenStack Identity API.

=head1 SYNOPSIS

    use Net::OpenStack::Identity;

    my $identity= Net::OpenStack::Identity->new_from_env();

    my $users = $identity->get_users()

=head1 DESCRIPTION

This class is an interface to the OpenStack Identity API v3.
See: L<Identity API|http://api.openstack.org/api-ref-identity.html>
in the OpenStack Documention.

=cut


1;
