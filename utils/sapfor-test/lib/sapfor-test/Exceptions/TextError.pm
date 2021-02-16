package Exceptions::TextError;
use base qw(Exceptions::Exception);

sub init
{
  my ($self, $line, $msg) = @_;
  $self->SUPER::init($msg);
  $self->{line} = $line;
}

sub line { $_[0]{line} }
sub msg  { $_[0]{line}.': '.$_[0]->SUPER::msg }
sub info { $_[0]->SUPER::msg }

1;

