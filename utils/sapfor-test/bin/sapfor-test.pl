#!/usr/bin/env perl
use strict;
use FindBin;
use File::Spec::Functions qw(splitpath catpath splitdir catdir catfile rel2abs);
use Cwd;
use File::Basename qw(dirname);
use ConfigFile;

use constant dbg1 => 0;

my $config_file_name = '.sapfortest';
my $config_path = find_config_path() or die "not a SAPFOR test directory (or any of the parent directories)\n";
my $cf = ConfigFile->new($config_path, {required => {'' => [qw(pts plugin_path task_path)]}});
$cf->load;
my $root = dirname($config_path);
my $pts = rel2abs($cf->get_var('', 'pts'), $root);
my $plugins_path = rel2abs($cf->get_var('', 'plugin_path'), $root);
my $tasks_path = rel2abs($cf->get_var('', 'task_path'), $root);
my @pts_opts = $cf->get_arr('', 'options');

my @args = ($^X, $pts, "-I$plugins_path", "-T$tasks_path", @pts_opts, @ARGV);
dbg1 and print "command:\n", map "  #$_#\n", @args;
system({$^X} @args) == -1 and die "$!\n";
exit $?;

sub find_config_path
{
  my $path = catfile(cwd(), $config_file_name);
  dbg1 and print "DEBUG: check path '$path'\n";
  return $path if -e $path;
  my ($drive, $dirs) = splitpath($path);
  my @dirs = splitdir($dirs); # '/d/i/r/s/' => ('', 'd', 'i', 'r', 's', '');
  pop @dirs; # remove the last empty dir;
  pop @dirs; # remove the first parent already checked.
  while (@dirs) {
    $path = catpath($drive, catdir(@dirs), $config_file_name);
    dbg1 and print "DEBUG: check path '$path'\n";
    return $path if -e $path;
    pop @dirs;
  }
  undef
}
