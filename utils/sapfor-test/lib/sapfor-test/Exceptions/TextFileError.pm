package Exceptions::TextFileError;
use strict;
use base qw(Exceptions::TextError);

sub init
{
  my ($self, $fname) = (shift, shift);
  $self->SUPER::init(@_);
  $self->{filename} = $fname;
}

sub filename { $_[0]{filename} }
sub msg      { $_[0]{filename}.':'.$_[0]->SUPER::msg }

1;

