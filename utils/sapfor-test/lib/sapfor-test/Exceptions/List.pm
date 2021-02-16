package Exceptions::List;
use strict;
use base qw(Exceptions::Exception);

sub new
{
  my $self = bless [], shift;
  $self->init(@_);
  $self
}

sub init
{
  my $self = shift;
  @$self = @_;
}

sub msg
{
  join "\n", map { (ref $_ && $_->isa('Exceptions::Exception')) ? $_->msg : $_ } @{$_[0]}
}

1;

