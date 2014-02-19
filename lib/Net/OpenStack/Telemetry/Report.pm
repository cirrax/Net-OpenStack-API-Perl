package Net::OpenStack::Report;

use Moose;

use JSON qw(from_json to_json);
use Date::Simple qw(days_in_month);
use Data::Dumper ;

use Net::OpenStack::Telemetry::Query;
use Net::OpenStack::Telemetry;

has project          => ( is => 'ro', required => 1,);
has start            => ( is => 'ro', required => 1,);
has end              => ( is => 'ro', required => 1,);

has print_events     => ( is => 'rw', required => 1, default => 1, );
has print_statistics => ( is => 'rw', required => 1, default => 1, );
has print_total_stat => ( is => 'rw', required => 1, default => 1, );
has print_unknown    => ( is => 'rw', required => 1, default => 1, );

has sub_resources    => ( is => 'rw', isa=>'HashRef');

# Image ressources (from glance)
has images            => ( is => 'rw', isa=>'ArrayRef', default => sub { [] }, );
has images_metadata   => ( is => 'ro', required => 1, default => sub { ['name','disk_format'] } );
has images_events     => ( is => 'ro', required => 1,  
             default  => sub { ['image.create','image.prepare','image.upload','image.activate','image.send', 'image.update', 'image.delete' ] } );
has images_statistics => ( is => 'ro', required => 1,  
             default  => sub { ['image.size'] } );
has images_others     => ( is => 'ro', required => 1,  
             default  => sub { ['image'] } );

# Volume ressources (from cinder)
has volumes            => ( is => 'rw', isa=>'ArrayRef', default => sub { [] }, );
has volumes_metadata   => ( is => 'ro', required => 1, default => sub { ['display_name','status'] } );
has volumes_events     => ( is => 'ro', required => 1,  
              default  => sub { [ ] } );
has volumes_statistics => ( is => 'ro', required => 1,  
              default  => sub { ['volume.size', 'volume'] } );
has volumes_others     => ( is => 'ro', required => 1,  
              default  => sub { [] } );

# Instance ressources (from nova)
has instances            => ( is => 'rw', isa=>'ArrayRef', default => sub { [] }, );
has instances_metadata   => ( is => 'ro', required => 1, default => sub { ['instance_type','display_name','hostname','name']});
has instances_events     => ( is => 'ro', required => 1,  
              default    => sub { [ ] } );
has instances_statistics => ( is => 'ro', required => 1,  
              default    => sub { ['disk.read.bytes', 'disk.write.bytes', 'disk.read.requests', 'disk.write.requests',
                                   'network.incoming.bytes', 'network.incoming.packets', 'network.outgoing.bytes', 'network.outgoing.packets',
                                   'disk.ephemeral.size', 'memory', 'disk.root.size', 'cpu', 'cpu_util' ] } );
has instances_others     => ( is => 'ro', required => 1,  
              default    => sub { ['instance:m1.tiny', 'instance:m1.small', 'instance', 'vcpus' ] } );

# Router ressources (from neutron)
has routers            => ( is => 'rw', isa=>'ArrayRef', default => sub { [] }, );
has routers_metadata   => ( is => 'ro', required => 1, default => sub { ['name']});
has routers_events     => ( is => 'ro', required => 1,  
             default   => sub { ['router.create','router.update','router.delete'] } );
has routers_statistics => ( is => 'ro', required => 1,  
             default   => sub { [ ] } );
has routers_others     => ( is => 'ro', required => 1,  
             default   => sub { ['router'] } );

# Subnet ressources (from neutron) Remark: This includes also network. 
has subnets          => ( is => 'rw', isa=>'ArrayRef', default => sub { [] }, );
has subnets_metadata   => ( is => 'ro', required => 1, default => sub { ['name', 'cidr', 'network_id']});
has subnets_events    => ( is => 'ro', required => 1,  
             default => sub { ['subnet.create', 'subnet.update', 'network.create' ] } );
has subnets_statistics => ( is => 'ro', required => 1,  
             default   => sub { [ ] } );
has subnets_others     => ( is => 'ro', required => 1,  
              default    => sub { ['subnet', 'network'] } );

# Port ressources (from neutron)
has ports          => ( is => 'rw', isa=>'ArrayRef', default => sub { [] }, );
has ports_metadata   => ( is => 'ro', required => 1, default => sub { ['mac_address', 'name']});
has ports_events    => ( is => 'ro', required => 1,  
             default => sub { ['port.create' ] } );
has ports_statistics => ( is => 'ro', required => 1,  
             default   => sub { [ ] } );
has ports_others     => ( is => 'ro', required => 1,  
              default    => sub { ['port'] } );

# Port ipfloat (from neutron)
has ipfloat          => ( is => 'rw', isa=>'ArrayRef', default => sub { [] }, );
has ipfloat_metadata   => ( is => 'ro', required => 1, default => sub { ['floating_ip_address', 'name']});
has ipfloat_events    => ( is => 'ro', required => 1,  
             default => sub { ['ip.floating.create', 'ip.floating.update' ] } );
has ipfloat_statistics => ( is => 'ro', required => 1,  
              default    => sub { [] } );
has ipfloat_others     => ( is => 'ro', required => 1,  
             default   => sub { ['ip.floating' ] } );

has unknown          => ( is => 'rw', isa=>'ArrayRef', default => sub { [] }, );


sub create {
  my ($self) = @_;
  
  my $filter = Net::OpenStack::Telemetry::Query->new();
  $filter->add_filter('project_id', 'eq' , $self->{project});
  $filter->add_filter('timestamp' , 'ge' , $self->{start});
  $filter->add_filter('timestamp' , 'le' , $self->{end});

  my $telemetry = Net::OpenStack::Telemetry->new_from_env();

  for my $res ( @{$telemetry->get_resources('', $filter->q)} ) {
    my $type='unknown';
    for my $links (@{$res->{links}}) {
      if ($links->{rel} eq 'image') {
         push @{$self->{images}}, ({ressource_id => $res->{resource_id} , metadata => $res->{metadata} });
         $type='image';
         last;
      }
      if ($links->{rel} eq 'volume') {
         push @{$self->{volumes}}, ({ressource_id => $res->{resource_id} , metadata => $res->{metadata} });
         $type='volume';
         last;
      }
      if ($links->{rel} eq 'instance') {
         push @{$self->{instances}}, ({ressource_id => $res->{resource_id} , metadata => $res->{metadata} });
         $type='instance';
         last;
      }
      if ($links->{rel} eq 'router' ){
         push @{$self->{routers}}, ({ressource_id => $res->{resource_id} , metadata => $res->{metadata} });
         $type='router';
         last;
      }
      # For now we take 'network' in subnets 
      if (($links->{rel} eq 'subnet' )|| ($links->{rel} eq 'network' )){
         push @{$self->{subnets}}, ({ressource_id => $res->{resource_id} , metadata => $res->{metadata} });
         $type='subnet';
         last;
      }
      if ($links->{rel} eq 'port' ){
         push @{$self->{ports}}, ({ressource_id => $res->{resource_id} , metadata => $res->{metadata} });
         $type='port';
         last;
      }
      if ($links->{rel} eq 'ip.floating' ){
         push @{$self->{ipfloat}}, ({ressource_id => $res->{resource_id} , metadata => $res->{metadata} });
         $type='ipfloat';
         last;
      }
      # Special case: this is sort of a subressource (one interface) of an instance
      if ($res->{resource_id} =~ /^instance-/  ){
         push @{$self->{instances}}, ({ressource_id => $res->{resource_id}, metadata => $res->{metadata}, main_res => $res->{metadata}->{instance_id} });
         push @{$self->{sub_resources}->{$res->{metadata}->{instance_id}}}, $res->{resource_id};
         $type='instance';
         last;
      }
    }
    if ($type eq 'unknown') {
         push @{$self->{unknown}}, ({ressource_id => $res->{resource_id} , metadata => $res->{metadata} , links => $res->{links} });
    }
  }
}


sub print_subnets {
  my ($self) = @_;
  print("\nSubnetworks:\n-------\n");
  $self->_print_ressources('subnets');
}

sub print_routers {
  my ($self) = @_;
  print("\nRouters:\n-------\n");
  $self->_print_ressources('routers');
}

sub print_instances {
  my ($self) = @_;
  print("\nInstances:\n----------\n");
  $self->_print_ressources('instances');
}
sub print_volumes {
  my ($self) = @_;
  print("\nVolumes: \n-------\n");
  $self->_print_ressources('volumes');
}

sub print_images {
  my ($self) = @_;
  print("\nImages: \n-------\n");
  $self->_print_ressources('images');
}
sub print_ports {
  my ($self) = @_;
  print("\nPorts: \n-------\n");
  $self->_print_ressources('ports');
}
sub print_ipfloat {
  my ($self) = @_;
  print("\nFloating IPs: \n-------\n");
  $self->_print_ressources('ipfloat');
}

sub _print_ressources {
  my ($self, $type) = @_;

  for my $res ( @{$self->{$type} } ) {
    if (! defined($res->{main_res})) {
      my $metadata='';
      for my $meta (values $self->{$type.'_metadata'}) {
        if ( defined($res->{metadata}->{$meta}) ) {
          $metadata .= ' '. $res->{metadata}->{$meta}
        }
      }
      printf("%-65s      (ressource_id: %-20s)\n", 
               $metadata,
               $res->{ressource_id} );

      my $filter = Net::OpenStack::Telemetry::Query->new();
      $filter->add_filter('project_id', 'eq' , $self->{project});
      $filter->add_filter('timestamp' , 'ge' , $self->{start});
      $filter->add_filter('timestamp' , 'le' , $self->{end});
      $filter->add_filter('resource_id' , 'eq' , $res->{ressource_id});
 
      if ($self->{print_events})     { _print_events('', $self->{$type.'_events'}, $filter->q ) }
      if ($self->{print_statistics}) { _print_statistics('', $self->{$type.'_statistics'}, $filter->q ) }
      if ($self->{print_unknown})    { $self->_print_unknown_meters('', $type, $res->{ressource_id} ) }

      # let's look for subresources
      if (defined($self->{sub_resources}->{$res->{ressource_id}})) {
        foreach (values $self->{sub_resources}->{$res->{ressource_id}}) {
          $filter->remove_filter_field('resource_id');
          $filter->add_filter('resource_id' , 'eq' , $_ );
          if ($self->{print_events})     { _print_events('sub', $self->{$type.'_events'}, $filter->q ) }
          if ($self->{print_statistics}) { _print_statistics('sub', $self->{$type.'_statistics'}, $filter->q ) }
          if ($self->{print_unknown})    { $self->_print_unknown_meters('sub', $type, $_ ) }
        }
      }
    }
  }
  if ($self->{print_total_stat} ) {
    print ("\n Total Statistic:\n");
    my $filter = Net::OpenStack::Telemetry::Query->new();
    $filter->add_filter('project_id', 'eq' , $self->{project});
    $filter->add_filter('timestamp' , 'ge' , $self->{start});
    $filter->add_filter('timestamp' , 'le' , $self->{end});
    _print_statistics('tot', $self->{$type.'_statistics'}, $filter->q ); 
  }
}

sub print_unknown_ressources {
  my ($self) = @_;

  print("\n Unknown: \n -------\n");
  for my $res ( @{$self->{unknown} } ) {
    print Dumper($res);
  }
}

sub _print_unknown_meters {
  my ($self, $remark, $type, $ressource_id) = @_;
  my $telemetry = Net::OpenStack::Telemetry->new_from_env();

  printf("  Unknown meters: %s\n",$remark);

  foreach (values $telemetry->get_resources($ressource_id)->{links} ) {
     if (!( ($_->{rel} eq 'self') ||  
          ($_->{rel} ~~ $self->{$type.'_events'}) ||
          ($_->{rel} ~~ $self->{$type.'_statistics'}) ||
          ($_->{rel} ~~ $self->{$type.'_others'}) 
           )) {
          printf("%s, ", $_->{rel});
     }
  }
  print "\n";
}

sub _print_statistics {
  my ($remark, $meter_names, $filter ) = @_;
  my $telemetry = Net::OpenStack::Telemetry->new_from_env();

  foreach my $meter_name (values $meter_names) {
     foreach (values $telemetry->get_statistics($meter_name, $filter) ) {
        printf("     %-40s   avg: %12.1f min: %12.1f max: %12.1f sum: %15.1f (%s) \n",
                  $meter_name . ' (' . $_->{unit} .')' ,  
                  $_->{avg},  
                  $_->{min}, 
                  $_->{max}, 
                  $_->{sum}, $remark ); 
     }
  }
}

sub _print_events {
  my ($remark, $meter_names, $filter ) = @_;
  my $telemetry = Net::OpenStack::Telemetry->new_from_env();

  foreach my $meter_name (values $meter_names) {
     foreach (values $telemetry->get_meters($meter_name, $filter) ) {
        printf("     %-10s:   %-12s                         (message_id: %-20s) (%s) \n",
                  $_->{timestamp}, 
                  $_->{resource_metadata}->{event_type}, 
                  $_->{message_id}, $remark );
     }
  }
}



# ABSTRACT: Report Class for Telemetry data

=head1 SYNOPSIS

    use Net::OpenStack::Telemetry::Report;

    my $report= Net::OpenStack::Report->new( project=> '51ce6d48c52b4f789a7e003a8df4f168',
                                         start  => '2014-02-18T09:30:00' ,
                                         end    => '2014-02-18T23:59:59',
                                         print_events     => 1,
                                         print_statistics => 1,
                                         print_unknown    => 1,
                                         print_total_stat => 1,
                                    );

    $report->create();

    $report->print_images();
    $report->print_volumes();
    $report->print_instances();
    $report->print_routers();
    $report->print_subnets();
    $report->print_ports();
    $report->print_ipfloat();

    $report->print_unknown_ressources();



=head1 DESCRIPTION

 

=cut


1;
