package Exceptions::OpenFileError;
use strict;
use base qw(Exceptions::Exception);

sub init
{
  my ($self, $filename, $reason) = @_;
  my $msg = "can not open file '$filename'";
  $reason = $! unless defined $reason;
  $msg .= ": $reason" if defined $reason;
  $self->SUPER::init($msg);
  $self->{filename} = $filename;
  $self->{reason}   = $reason;
}

sub filename { $_[0]{filename} }
sub reason   { $_[0]{reason} }

1;

