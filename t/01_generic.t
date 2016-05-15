#!/usr/bin/perl

use strict;
use warnings;
use FindBin qw($Bin);
use File::Slurp;
use Test::More;
use constant TEMPFILE => "/tmp/config_hostsfile_test.txt";
use Config::HostsFile;


my $base_hosts = "127.0.0.1       localhost
127.0.1.1       builder.builder builder
127.0.1.1       nonstandard.extra
";

my @tests = (
  {
    "hosts" => $base_hosts,
    "operations" => sub {
    },
    "expected"=> $base_hosts,
    "description" => "No operations, simply rerendering the file",
  },

  {
    "hosts" => $base_hosts,
    "operations" => sub {
        my $h = shift;
        $h->remove_host("non.existent.host")
    },
    "expected"=> $base_hosts,
    "description" => "Trying to remove something which is not in there",
  },

  {
    "hosts" => $base_hosts,
    "operations" => sub {
        my $h = shift;
        $h->remove_host("localhost")
    },
    "expected"=> "127.0.1.1       builder.builder builder
127.0.1.1       nonstandard.extra
",
    "description" => "Trying to remove some host",
  },

  {
    "hosts" => $base_hosts,
    "operations" => sub {
        my $h = shift;
        $h->remove_ip("123.123.123.123")
    },
    "expected"=> $base_hosts,
    "description" => "Trying to remove entries based on invalid IP address",
  },


  {
    "hosts" => $base_hosts,
    "operations" => sub {
        my $h = shift;
        $h->remove_ip("127.0.1.1")
    },
    "expected"=> "127.0.0.1       localhost",
    "description" => "Trying to remove entries based on IP address",
  },


  {
    "hosts" => $base_hosts,
    "operations" => sub {
        my $h = shift;
        $h->update_host("builder", "123.123.123.123")
    },
    "expected"=> "127.0.0.1       localhost
123.123.123.123       builder.builder builder
127.0.1.1       nonstandard.extra
",
    "description" => "Updating an entry which had another aliases #1",
  },


  {
    "hosts" => $base_hosts,
    "operations" => sub {
        my $h = shift;
        $h->update_host("builder.builder", "123.123.123.123")
    },
    "expected"=> "127.0.0.1       localhost
123.123.123.123       builder.builder builder
127.0.1.1       nonstandard.extra
",
    "description" => "Updating an entry which had another aliases #2",
  },


  {
    "hosts" => $base_hosts,
    "operations" => sub {
        my $h = shift;
        $h->update_host("nonstandard.extra", "123.123.123.123")
    },
    "expected"=> "127.0.0.1       localhost
127.0.1.1       builder.builder builder
123.123.123.123       nonstandard.extra
",
    "description" => "Updating non-standard extra entry",
  },

  {
    "hosts" => $base_hosts,
    "operations" => sub {
        my $h = shift;
        $h->update_host("new.host", "123.123.123.123")
    },
    "expected"=> "127.0.0.1       localhost
127.0.1.1       builder.builder builder
127.0.1.1       nonstandard.extra
123.123.123.123 new.host
",
    "description" => "Adding a new entry",
  },


);

plan tests => scalar @tests;


for my $test (@tests) {
  write_file(TEMPFILE, $test->{'hosts'});

  my $h = new Config::HostsFile(TEMPFILE);
  $test->{'operations'}($h);
  $h->flush();

  my $c = read_file(TEMPFILE);
  $c = trim($c);
  my $e = trim($test->{'expected'});
  unlink(TEMPFILE);

  if(!ok($c eq $e, $test->{'description'})) {
     print STDERR "Expected:\n$e\n\nGot:\n$c\n";
  }
}




sub trim {
  my $x = shift;
  $x =~ s#\s{2,}# #g;
  $x =~ s#\s*$##;
  $x =~ s#^\s*##;
  return $x;
}
