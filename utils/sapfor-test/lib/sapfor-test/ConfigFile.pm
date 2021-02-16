package ConfigFile;
use strict;
use Exceptions;
use Exceptions::TextFileError;
use Exceptions::OpenFileError;
use ConfigFileScheme;

use vars qw($VERSION);
$VERSION = '0.6.0';

# TODO: allow change comment symbol to ;


=head1 NAME

ConfigFile - read and write configuration files aka '.ini'.

=head1 SYNOPSIS

  ## load configuration file ##
  my $decl = ConfigFileScheme->new( multiline => 1,... );
  my $cf   = ConfigFile->new($filename, $decl);
  # <=>
  my $cf = ConfigFile->new($filename, { multiline => 1,... });
  # <=>
  my $cf = ConfigFile->new($filename,   multiline => 1,...  );
  # or
  my $cf = ConfigFile->new($filename);

  # Ignoring unrecognized lines is useful when you want to read some scalar
  # variables, but there can be multiline variables and you are not interested
  # in these values.
  $cf->skip_unrecognized_lines(1);

  try{
    $cf->load; #< all checks are included
  }
  catch{
    print map "warning: $_\n", @{$@};
  } 'List';
  # <=>
  print "warning: $_\n" for $cf->load; #< It raises exception if can not open file.

  ## access variables ##
  my $str = $cf->get_var('group', 'var', 'default value');
  my @array = $cf->get_arr('group', 'var', @default_value);

  my $value;
  $value = $cf->get_var('group', 'var', 'default value');
  # <=>
  $value = $cf->is_set('group', 'var') ? $cf->get_var('group', 'var')
                                       : 'default value';

  ## save configuration file ##
  my $cf = ConfigFile->new($file_name);
  $cf->set_group('group');
  $cf->set_var('var_name', @values);      #< set the $group::var_name variable.
  $cf->set('group', 'var_name', @values); #< the same but not changing current group.
  $cf->set_var('var2', @values);          #< set the $group::var2 variable.
  $cf->unset('group', 'var_name');        #< remove the $group::var_name variable.
  $cf->save;

  --------
  $cf->check_required;         ##< according to declaration
  $cf->check_required($hash);  ##< according to $hash, defining required variables
  $cf->check_required('gr' => [@vars],...); ##< hash constructor

=cut

BEGIN {
  if (!exists &legacy) {
    my $v = $^V < 5.018;
    *legacy = sub () { $v }
  }
}
BEGIN{*load = legacy ? *m_load_old : *m_load}

# throws: -
sub new
{
  my $self = bless {}, shift;
  $self->init(@_);
  $self
}

sub init
{
  my $self  = shift;
  my $fname = shift;
  my $decl  = !@_                  ? ConfigFileScheme->new
            : !ref $_[0]           ? ConfigFileScheme->new(@_)
            :  ref $_[0] eq 'HASH' ? ConfigFileScheme->new(%{$_[0]})
                                   : $_[0];
  $self->{fname}     = $fname;
  $self->{content}   = {};
  $self->{cur_group} = '';
  $self->{decl}      = $decl;
  $self->{skip_unrecognized_lines} = 0;
}

# throws: Exceptions::OpenFileError, [Exceptions::TextFileError]
sub m_load_old
{
  my $self = shift;
  my $decl = $self->{decl};
  my @errors;

  open(my $f, '<', $self->{fname}) || throw OpenFileError => $self->{fname};

  my $gr = '';
  my $interpolate_str = sub {
    my $str = shift;
    $str =~ s/
      # normalize string
      \\(n) | \\(t) | \\(.)
      |
      # interpolate variables
      \$(\{(?:(\w*)::)?)?(\w++)(?(4)\})
    /$1 ? "\n" : $2 ? "\t" : $3 ? $3 : $self->get_var(defined $5 ? $5||'' : $gr, $6, '')/gex;
    $str
  };
  my $normalize_str = sub {
    my $str = shift;
    $str =~ s/\\([\\\$'" \t])/$1/g;
    $str
  };
  my $interpolate = 1;
  my $inside_string = 0;
  my $multiline = 0;
  my ($ln, $s, $var, $parr, $str_beg_ln, $do_concat, $is_first, $q);
  my $cont = '';
  for ($ln = 1; defined ($s = <$f>) || $cont; $ln++) {
    ## process line continuation ##
    $s = '' if !defined $s;
    chomp $s;
    if (substr($s, -3) =~ /\\/ && $s =~ s/((?:^|[^\\])(?:\\\\)*)\\$/$1/) {
      $cont .= $s;
      next;
    }
    elsif ($cont) {
      $s = $cont.$s;
      $cont = '';
    }
    ## process accumulated line ##
    if (!$inside_string) {
      ## determine expression type ##
      if ($s =~ /^\s*(#|$)/){
        # comment string
        next;
      }
      elsif ($s =~ /^\s*\[(\w+)\]\s*$/) {
        # group declaration
        $self->{content}{$gr}{$var} = $parr if defined $var;
        undef $var;
        $gr = $1;
        $multiline = 0;
        next;
      }
      elsif ($s =~ s/^\s*(\w+)\s*(\@?)=//) {
        # assignment statement
        $self->{content}{$gr}{$var} = $parr if defined $var;
        $var = $1;
        $multiline = $decl->is_multiline($gr, $var) || $2;
        if (!$decl->is_valid($gr, $var)) {
          push @errors, Exceptions::TextFileError->new($self->{fname}, $ln, "declaration of variable '${gr}::$var' is not permitted");
        }
        $parr = [];
      }
      elsif (!$multiline) {
        # unrecognized string
        $self->{skip_unrecognized_lines} ||
            push @errors, Exceptions::TextFileError->new($self->{fname}
                        , $ln, "unrecognized line '$s'");
        next;
      }
    }

    ## read value ##
    $is_first = 1; #< do not concatenate the first
    while (length $s > 0 || $inside_string) {
      if ($inside_string) {
        if ($s =~ s/^((?:[^\\$q]|\\.)*+)$q//) {
          # string finished
          $parr->[-1] .= $interpolate ? &$interpolate_str($1) : &$normalize_str($1);
          $inside_string = 0;
          $interpolate = 1;
        }
        else {
          # string unfinished
          $parr->[-1] .= ($interpolate ? &$interpolate_str($s) : &$normalize_str($s))."\n";
          last;
        }
      }

      ## outside string ##
      ## skip spaces and comments ##
      $s =~ s/^(\s*)(?:#.*)?//; #< skip spaces and comments
      last if length $s == 0;
      $do_concat = !($1) && !$is_first;

      ## take next word ##
      if ($s =~ s/^((?:[^\\'"# \t]|\\(?:.|$))++)//) {
        # word taken
        if ($do_concat) {
          $parr->[-1] .= &$interpolate_str($1);
        }
        elsif ($1 =~ /^\$(\{(?:(\w*)::)?)?(\w++)(?(1)\})(?=\s|#|$)/) {
          # array interpolation
          push @$parr, $self->get_arr(defined $2 ? $2||'' : $gr, $3);
        }
        else {
          push @$parr, &$interpolate_str($1);
        }
      }
      elsif ($s =~ s/^(['"])//) {
        # string encountered
        $q = $1;
        $interpolate = $q eq '"';
        $inside_string = 1;
        $str_beg_ln = $ln;
        $do_concat or push @$parr, '';
      }
      else {
        push @errors, Exceptions::TextFileError->new($self->{fname}
                        , $ln, "unexpected string '$s' encountered");
      }
      $is_first = 0;
    }
  }
  $self->{content}{$gr}{$var} = $parr if defined $var;

  if ($inside_string){
    push @errors, Exceptions::TextFileError->new($self->{fname}, $ln-1, "unclosed string (see from line $str_beg_ln)");
  }
  close $f;

  try{
    $self->check_required;
  }
  catch{
    push @errors, @{$@};
  } 'List';

  if (@errors){
    return @errors if wantarray;
    throw List => @errors;
  }
}

sub m_load
{
  my $self = shift;
  my $decl = $self->{decl};
  my @errors;

  open(my $f, '<', $self->{fname}) || throw OpenFileError => $self->{fname};

  my $inside_string = 0;
  my $multiline = 0;
  my $gr = '';
  my $do_concat = 0;
  my ($ln, $s, $var, $parr, $str_beg_ln, $is_first, $q);
  my $add_word = sub { $do_concat ? $parr->[-1] .= $_[0] : push @$parr, $_[0]; $do_concat = 1 };

  my $interpolate_str = sub {
    my $str = shift;
    $str =~ s/
      # normalize string
      \\(n) | \\(t) | \\(.)
      |
      # interpolate variables
      \$(\{(?:(\w*)::)?)?(\w++)(?(4)\})
    /$1 ? "\n" : $2 ? "\t" : $3 ? $3 : $self->get_var(defined $5 ? $5||'' : $gr, $6, '')/gex;
    $str
  };
  my $normalize_str = sub {
    my $str = shift;
    $str =~ s/\\([\\\$'" \t])/$1/g;
    $str
  };
  my $space = qr~(?:\s++|#.*|\r?\n)\r?\n?(?{ $do_concat = 0 })~s;
  my $normal_word = qr~((?:[^\\\'"# \t\n]|\\(?:.|$))++)(?{ &$add_word(&$interpolate_str($^N)) })~s;
  my $q_str_beg  = qr~'((?:[^\\']|\\(?:.|$))*+)(?{ &$add_word(&$normalize_str($^N)) })~s;
  my $qq_str_beg = qr~"((?:[^\\"]|\\(?:.|$))*+)(?{ &$add_word(&$interpolate_str($^N)) })~s;
  my $q_str_end  = qr~((?:[^\\']|\\(?:.|$))*+)'(?{ $parr->[-1].=&$normalize_str($^N); })~s;
  my $qq_str_end = qr~((?:[^\\"]|\\(?:.|$))*+)"(?{ $parr->[-1].=&$interpolate_str($^N)})~s;
  my $q_str = qr<$q_str_beg$q_str_end>;
  my $qq_str = qr<$qq_str_beg$qq_str_end>;
  my ($vg, $vn);
  my $as_vn = qr<(\w++)(?{$vn = $^N})>;
  my $as_vg = qr<(?:(\w*)::(?{$vg = $^N})|(?{$vg = $gr}))>;
  my $array_substitution = qr~(?(?{$do_concat})(?!))\$(?:\{$as_vg$as_vn\}|$as_vn)(?:$space|$)(?{
    push @$parr, $self->get_arr($vg, $vn);
  })~;
  my $value_part = qr<^(?:$array_substitution|$space|$normal_word|$q_str_beg(?:$(?{
    $q = '\'';
    $str_beg_ln = $ln;
    $inside_string = 1;
  })|$q_str_end)|$qq_str_beg(?:$(?{
    $q = '"';
    $str_beg_ln = $ln;
    $inside_string = 1;
  })|$qq_str_end))*+$>;
  my $var_decl_beg = qr~^\s*(\w+)\s*(\@?)=(?{
    $self->{content}{$gr}{$var}= $parr if defined $var;
    $var = $1;
    $parr = [];
    $multiline = $decl->is_multiline($gr, $var) || $2;
    if (!$decl->is_valid($gr, $var)) {
      push @errors, Exceptions::TextFileError->new($self->{fname}, $ln, "declaration of variable '${gr}::$var' is not permitted");
    }
    $do_concat = 0;
  })~;
  my $cont = '';
  for ($ln = 1; defined ($s = <$f>) || $cont; $ln++) {
    ## process line continuation ##
    $s = '' if !defined $s;
    if (substr($s, -3) =~ /\\/ && $s =~ s/((?:^|[^\\])(?:\\\\)*)\\\r?\n$/$1/) {
      $cont .= $s;
      next;
    }
    elsif ($cont) {
      $s = $cont.$s;
      $cont = '';
    }
    ## process accumulated line ##
    if (!$inside_string) {
      # skip comment and blank string
      next if $s =~ /^\s*(#|$)/;
      # process group declaration
      next if $s =~ /^\s*\[(\w+)\]\s*$(?{
        $self->{content}{$gr}{$var} = $parr if defined $var;
        undef $var;
        $gr = $1;
        $multiline = 0;
      })/;
      # process variable declaration
      if ($s =~ s/$var_decl_beg// || $multiline) {
        if ($s !~ /$value_part/) {
          chomp $s;
          push @errors, Exceptions::TextFileError->new($self->{fname}
                      , $ln, "unexpected string '$s' encountered");
        }
      }
      else {
        # unrecognized string
        chomp $s;
        $self->{skip_unrecognized_lines} ||
            push @errors, Exceptions::TextFileError->new($self->{fname}
                        , $ln, "unrecognized line '$s'");
        next;
      }
    }
    else {
      # read string
      if (!($q eq '\'' && $s =~ s/$q_str_end// || $q eq '"' && $s =~ s/$qq_str_end//)) {
        # string is not finished
        $parr->[-1] .= $q eq '"' ? &$interpolate_str($s) : &$normalize_str($s);
        next;
      }
      $inside_string = 0;
      if ($s !~ /$value_part/) {
        chomp $s;
        push @errors, Exceptions::TextFileError->new($self->{fname}
                    , $ln, "unexpected string '$s' encountered");
      }
    }
  }
  $self->{content}{$gr}{$var} = $parr if defined $var;

  if ($inside_string){
    push @errors, Exceptions::TextFileError->new($self->{fname}, $ln-1, "unclosed string (see from line $str_beg_ln)");
  }
  close $f;

  try{
    $self->check_required;
  }
  catch{
    push @errors, @{$@};
  } 'List';

  if (@errors){
    return @errors if wantarray;
    throw List => @errors;
  }
}

# throws: Exceptions::List
sub check_required
{
  my $self = shift;
  my $decl = @_ ? ConfigFileScheme->new(required => (ref $_[0] ? $_[0] : {@_}))
                : $self->{decl};
  $decl->check_required($self->{content});
}

# throws: string, Exceptions::OpenFileError
sub save
{
  my $self = shift;
  open(my $f, '>', $self->{fname}) || throw OpenFileError => $self->{fname};
  for my $gr_name (sort keys %{$self->{content}}){
    my $gr = $self->{content}{$gr_name};
    print $f "\n[$gr_name]\n" if $gr_name;
    for (sort keys %$gr){
      if ($self->{decl}->is_multiline($gr_name, $_)) {
        print $f "$_ @=", (map "\n  ".m_shield_str($_), @{$gr->{$_}}), "\n";
      }
      else {
        print $f "$_ =", (map ' '.m_shield_str($_), @{$gr->{$_}}), "\n";
      }
    }
  }
  close $f;
}

sub filename { $_[0]{fname} }
sub get_var   { exists $_[0]{content}{$_[1]}{$_[2]} ? "@{$_[0]{content}{$_[1]}{$_[2]}}" : $_[3] }
sub get_arr   { exists $_[0]{content}{$_[1]}{$_[2]} ? @{$_[0]{content}{$_[1]}{$_[2]}} : @_[3..$#_] }
sub is_set    { exists $_[0]{content}{$_[1]}{$_[2]} }
sub group_names { keys %{$_[0]{content}} }
sub var_names { exists $_[0]{content}{$_[1]} ? keys %{$_[0]{content}{$_[1]}} : () }

sub set_filename { $_[0]{fname} = $_[1] }
sub set_group { $_[0]{cur_group} = $#_ < 1 ? '' : $_[1] }
sub set_var   { $_[0]{content}{$_[0]{cur_group}}{$_[1]} = [@_[2..$#_]] }
sub set_var_if_not_exists
{
  $_[0]{content}{$_[0]{cur_group}}{$_[1]} = [@_[2..$#_]] if !exists $_[0]{content}{$_[0]{cur_group}}{$_[1]}
}
sub set
{
  my $gr = defined $_[1] ? $_[1] : $_[0]{cur_group};
  $_[0]{content}{$gr}{$_[2]} = [@_[3..$#_]]
}
sub unset
{
  my $gr = defined $_[1] ? $_[1] : $_[0]{cur_group};
  defined $_[2]
    ? delete $_[0]{content}{$gr}{$_[2]}
    : delete $_[0]{content}{$gr}
}
sub skip_unrecognized_lines
{
  my $self = shift;
  my $ret = $self->{skip_unrecognized_lines};
  $self->{skip_unrecognized_lines} = $_[0] ? 1 : 0 if @_;
  $ret
}
sub erase { $_[0]{content} = {}; $_[0]{cur_group} = ''; }

sub m_shield_str
{
  my $ret = shift;
  if ($ret =~ /\s|\n/) {
    $ret =~ s/([\\'])/\\$1/g;
    $ret = '\''.$ret.'\'';
  }
  elsif ($ret eq '') {
    $ret = "''";
  }
  else {
    $ret =~ s/([\\'"\$#])/\\$1/g;
  }
  $ret
}

1;

__END__

=head1 CONFIGURATION FILE

File consist of groups and variables definition lines.
One file line for one definition.
Also, there can be blank lines and comment lines.
Comments begins with # and ends with the line.
Two lines can be joined by placing a I<\> at the end of the first one.

=head2 Group

 [group_name]

I<group_name> is one word matching B<\w+> pattern.
Group definition splits the file on sections.
Each group has its own variables set.
Different groups can have variables with the same name, but it still different
variables.

=head2 Variable

 var_name = value
 # or
 var_name @= elem1 elem2
 elem3
 ...

I<var_name> is one word matching B<\w+> pattern.
Value part of the string begins just after the assignment symbol and ends with
the line.
Value is a space separated list of words.
There is special words such as string literal and variable substitution.
Sequence of words without any space between them is the one word.
Variable declaration parsed into a list of words, which can be accessed by the
L</get_arr> and L</get_var> methods.
By default, variable declaration ends with the line (except string literal,
which can have line feeding inside), but there is special case when parser
treats all next lines as the value part continuation until the next declaration
occurred.
This behaviour is enabled by telling the parser that variable is B<multiline>
or by using the variable declaration second form (C<var_name @= ...>).

=head3 Variables substitution

 $var or ${var} or ${group::var}

Variables substitution is performed after value part parsed into the list.
Once encountered such a construct it is replaced with the string value of the
corresponding variable existing at that moment.
In the first and second forms the group treated as the current group.
If the whole word is the one variable substitution, this word will be replaced
by the list value of the variable.

=head3 String literal "", ''

String literal begins with the qoute ' or " and ends with the corresponding
quote.
String literal is treated as one word.
All spaces in quoted string are preserved.
Symbol # inside the quoted string has no special meaning.
Like in Perl inside a '' string parser will not interpolate variables and
symbol \ will have special meaning only just before another \ or '.
In double qouted string "" variables interpolation is enabled and symbol \ will
shield any next symbol or have special meaning, like "\n".

=head1 METHODS

=over

=item new($filename, declaration)

  my $decl = ConfigFileScheme->new( multiline => 1,... );
  my $cf   = ConfigFile->new($filename, $decl);
  # the same as #
  my $cf = ConfigFile->new($filename, { multiline => 1,... });
  # the same as #
  my $cf = ConfigFile->new($filename,   multiline => 1,...  );
  # or #
  my $cf = ConfigFile->new($filename);

=item load

Read and parse the file. All occurred errors will be thrown as exceptions.
If used in list context, it returns parse errors as a list, but open file error
will be thrown.

=item check_required

=item check_required($hash)

=item check_required(%hash)

This method checks all required variables are set.
As the parameter it can recieve I<required> part of the scheme.
This method is included into L</load> method.

=item filename

Method returns associated filename.

=item group_names

Method returns an array of all group names.

=item var_names('group')

Method returns an array of all variable names from the specified group.

=item get_var('group', 'variable', 'default value')

Get group::variable value as a string.
If the variable is not set, method returns 'default value'.

=item get_arr('group', 'variable', @default_value)

Get group::variable value as an array.
If the variable is not set, method returns @default_value.

=item set_filename('filename')

Set the filename.

=item set_group('group')

Set current group to the specified name.

=item set_var('variable', @value)

Assign @value to the variable from the current group.

=item set('group', 'variable', @value)

Assign @value to the I<$group::variable>. It does not change the current group.
When the I<group> is C<undef>, set the variable from the current group.

=item unset('group', 'variable')

Remove the I<$group::variable>. It does not change the current group.
When the I<group> is C<undef>, remove the variable from the current group.
When the I<variable> is C<undef>, remove all variables from the group.

=item save

Write configuration into the file.

=item erase

Remove all variables and groups. Also it resets current group to default value.

=back

=head1 AUTHOR

Alexander Smirnov <zoocide@gmail.com>

=head1 LICENSE

This module is free software;
you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
