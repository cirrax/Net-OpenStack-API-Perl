package Net::OpenStack::Telemetry::Query;

use Moose;


use JSON qw(from_json to_json);
use Date::Simple qw(days_in_month);

has filter  => ( is => 'rw', isa=>'ArrayRef', ); #default => sub { [] }, );
has groupby => ( is => 'rw', isa=>'ArrayRef', );
has limit   => ( is => 'rw');
has period  => ( is => 'rw');



#########
# Handle Filter

sub add_filter {
 my ($self, $field, $op ,$value) = @_;
 push @{$self->{filter}}, ({field => $field , op=>$op, value=>$value});
} 

sub add_filter_day {
 my ($self, $year, $month, $day ) = @_;
 
 $self->add_filter('timestamp','ge', $year . '-' . $month . '-' . $day . 'T00:00:00');
 $self->add_filter('timestamp','le', $year . '-' . $month . '-' . $day . 'T23:59:59');
} 

sub add_filter_month {
 my ($self, $year, $month ) = @_;
 
 $self->add_filter('timestamp','ge', $year . '-' . $month . '-01T00:00:00');
 $self->add_filter('timestamp','le', $year . '-' . $month . '-' . days_in_month( $year, $month ) . 'T23:59:59');
} 

sub remove_filter {
  my ($self) = @_;
  undef $self->{filter};
}

sub remove_filter_field {
  my ($self, $field) = @_;
  for ( my $index = scalar @{$self->{filter}} ; $index >0 ; $index--) {
    if ($self->{filter}[$index-1]->{field} eq $field) {
      splice $self->{filter}, ($index-1), 1;
    }
  }
}

#################
# Handle limit

sub add_limit {
 my ($self, $limit) = @_;
 $self->{limit} = $limit;
}

sub remove_limit {
 my ($self) = @_;
 undef $self->{limit};
} 

#################
# Handle period
sub add_period {
 my ($self, $period) = @_;
 $self->{period} = $period;
}

sub remove_period {
 my ($self) = @_;
 undef $self->{period};
} 

#################
# Handle group by

sub add_groupby {
 my ($self, $field, $op ,$value) = @_;
 push @{$self->{groupby}}, $field;
} 

sub remove_groupby {
 my ($self) = @_;
 undef $self->{groupby};
} 

################
# Return query for API

sub all {
  my ($self) = @_;
  my @res;
  
  if (defined($self->{filter})) { push @res, q=>$self->{filter} }
  if (defined($self->{limit})) { push @res, limit=>$self->{limit} }
  if (defined($self->{period})) { push @res, period=>$self->{period} }
  if (defined($self->{groupby})) { push @res, groupby=>$self->{groupby} }
  return {@res};
}

sub q {
  my ($self) = @_;
  return { q=>$self->{filter}} ;
}

sub print {
  my ($self) = @_;

  for my $index ( keys $self->{filter}) {
    print($index . ".)\t" );
    print($self->{filter}[$index]->{field} ."\t" );
    print($self->{filter}[$index]->{op}    ."\t" );
    print($self->{filter}[$index]->{value} ."\n" );
  }
  print('Limit:' . $self->{limit} ."\n" );
}



# ABSTRACT: Administrate queries for Telemetry API

=head1 SYNOPSIS

    use Net::OpenStack::Telemetry::Query;

    my $query= Net::OpenStack::Telemetry::Query->new();


=head1 DESCRIPTION

=cut

1;
