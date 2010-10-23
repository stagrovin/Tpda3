package Tpda3::Config::Utils;

use strict;
use warnings;

use File::Basename;
use File::Find::Rule;
use File::Path 2.07 qw( make_path );
use File::Copy;
use YAML::Tiny;
use Config::General;

#use Log::Log4perl qw(get_logger);

=head1 NAME

Tpda3::Config::Utils - Utility functions for config paths and files

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    use Tpda3::Config::Utils;

    my $cu = Tpda3::Config::Utils->new();


=head1 METHODS

=head2 load_conf

Load a generic config file in Config::General format and return the
Perl data structure.

=cut

sub load_conf {
    my ( $self, $config_file ) = @_;

    my $conf = Config::General->new($config_file);

    my %config = $conf->getall;

    return \%config;
}

=head2 load_yaml

Use YAML::Tiny to load a YAML file and return as a Perl hash data
structure.

=cut

sub load_yaml {
    my ( $self, $yaml_file ) = @_;

    return YAML::Tiny::LoadFile( $yaml_file );
}

=head2 find_subdirs

Find subdirectories of a directory, not recursively

=cut

sub find_subdirs {
    my ($self, $dir) = @_;

    # Find all the sub directories of a given directory
    my $rule = File::Find::Rule->new
        ->mindepth(1)
        ->maxdepth(1);
    # Ignore git
    $rule->or(
        $rule->new
            ->directory
            ->name('.git')
            ->prune
            ->discard,
        $rule->new);

    my @subdirs = $rule->directory->in( $dir );

    my @dbs = map { basename($_); } @subdirs;

    return \@dbs;
}

=head1 AUTHOR

Stefan Suciu, C<< <stefansbv at user.sourceforge.net> >>

=head1 BUGS

None known.

Please report any bugs or feature requests to the author.


=head1 LICENSE AND COPYRIGHT

Copyright 2010 Stefan Suciu.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation.

=cut

1; # End of Tpda3::Config::Utils