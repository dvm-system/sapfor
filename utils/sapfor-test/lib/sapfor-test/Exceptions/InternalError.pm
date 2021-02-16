package Exceptions::InternalError;
use base qw(Exceptions::Exception);

sub init
{
  my $self = shift;
  $self->SUPER::init(@_);
  my ($p, $fname, $line) = caller(1);
  if ($p eq 'Exceptions'){
    ($p, $fname, $line) = caller(2);
  }
  $self->{msg} = "$fname:$line: internal error: ".$self->msg;
}

1;
