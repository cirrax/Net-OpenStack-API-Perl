package Net::OpenStack::Base;

use Moose;

use HTTP::Request;
use JSON qw(from_json to_json);
use LWP;
use Data::Dumper;

has auth_url      => (is => 'rw', required => 1);
has user          => (is => 'ro', required => 1);
has password      => (is => 'ro', required => 1);
has project_id    => (is => 'ro');
has region        => (is => 'ro');
has is_rax_auth   => (is => 'ro');
has service_name  => (is => 'ro');
has endpoint_type => (is => 'ro');
has verify_ssl    => (is => 'ro', default => sub {! $ENV{OSCOMPUTE_INSECURE}});

has base_url      => (is      => 'ro',
                      lazy    => 1,
                      default => sub { shift->_auth_info->{base_url} },
);
has token         => (is      => 'ro',
                      lazy    => 1,
                      default => sub { shift->_auth_info->{token} },
);
has _auth_info => (is => 'ro', lazy => 1, builder => '_build_auth_info');

has _agent => (
    is => 'ro',
    lazy => 1,
    default => sub {
        my $self = shift;
        my $agent = LWP::UserAgent->new(
            ssl_opts => { verify_hostname => $self->verify_ssl });
        return $agent;
    },
);

sub BUILD {
    my ($self) = @_;
    # Make sure trailing slashes are removed from auth_url
    my $auth_url = $self->auth_url;
    $auth_url =~ s|/+$||;
    $self->auth_url($auth_url);
}

sub _build_auth_info {
    my ($self) = @_;
    my $auth_info = $self->get_auth_info();
    $self->_agent->default_header(x_auth_token => $auth_info->{token});
    return $auth_info;
}

sub get_auth_info {
    my ($self) = @_;
    my $auth_url = $self->auth_url;
    my ($version) = $auth_url =~ /(v\d+\.\d+)$/;
    die "Could not determine version from url [$auth_url]" unless $version;
    return $self->auth_keystone();
}

sub auth_keystone {
    my ($self) = @_;
    return $self->_parse_catalog({
        auth =>  {
            tenantName => $self->project_id,
            passwordCredentials => {
                username => $self->user,
                password => $self->password,
            }
        }
    });
}


sub _parse_catalog {
    my ($self, $auth_data) = @_;
    my $res = $self->_agent->post($self->auth_url . "/tokens",
        content_type => 'application/json', content => to_json($auth_data));
    die $res->status_line . "\n" . $res->content unless $res->is_success;
    my $data = from_json($res->content);
    my $token = $data->{access}{token}{id};

    my @catalog = @{ $data->{access}{serviceCatalog} };
    # We do not look for compute services in Net::OpenStack::Networking
    #@catalog = grep { $_->{type} eq 'compute' } @catalog;
    #die "No compute catalog found" unless @catalog;
    if ($self->service_name) {
        @catalog = grep { $_->{name} eq $self->service_name } @catalog;
        die "No catalog found named " . $self->service_name unless @catalog;
    }
    my $catalog = $catalog[0];
    my $base_url = $catalog->{endpoints}[0]{$self->endpoint_type};
    if ($self->region) {
        for my $endpoint (@{ $catalog->{endpoints} }) {
            my $region = $endpoint->{region} or next;
            if ($region eq $self->region) {
                $base_url = $endpoint->{$self->endpoint_type};
                last;
            }
        }
    }
    # remove version from endpoint url (TODO: this regex is not yet perfect !)
    $base_url =~ s|/[^:]*$||;
    return { base_url => $base_url, token => $token };
}


sub _url {
    my ($self, $api_version, $path ) = @_;
    my $url = $self->base_url . '/'. $api_version . $path;
    return $url;
}

sub _get {
    my ($self, $url, $json) = @_;
    if (defined($json)) {
      return $self->_agent->get($url, content_type => 'application/json', content => to_json($json));
    } else {
      return $self->_agent->get($url);
    }
}

sub _post {
    my ($self, $url, $data) = @_;
    return $self->_agent->post(
        $url,
        content_type => 'application/json',
        content      => to_json($data),
    );
}

sub _delete {
    my ($self, $url) = @_;
    my $req = HTTP::Request->new(DELETE => $url);
    return $self->_agent->request($req);
}

sub _check_res {
    my ($res) = @_;
    die $res->status_line . "\n" . $res->content
        if ! $res->is_success and $res->code != 404;
    return 1;
}

around qw( _get _post _delete ) => sub {
    my $orig = shift;
    my $self = shift;
    my $res = $self->$orig(@_);
    _check_res($res);
    return $res;
};


# ABSTRACT: Base class for Openstack API.

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

1;
