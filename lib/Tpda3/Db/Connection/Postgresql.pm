package Tpda3::Db::Connection::Postgresql;

use strict;
use warnings;

use Log::Log4perl qw(get_logger);

use DBI;

=head1 NAME

Tpda3::Db::Connection::Postgresql - Connect to a PostgreSQL database.

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

    use Tpda3::Db::Connection::Postgresql;

    my $db = Tpda3::Db::Connection::Postgresql->new();

    $db->db_connect($connection);


=head1 METHODS

=head2 new

Constructor

=cut

sub new {
    my $class = shift;

    my $self = {};

    bless $self, $class;

    return $self;
}

=head2 db_connect

Connect to database

=cut

sub db_connect {
    my ($self, $conf) = @_;

    my $dbname = $conf->{dbname};
    my $host   = $conf->{server};
    my $port   = $conf->{port};
    my $driver = $conf->{driver};
    my $user   = $conf->{user};
    my $pass   = $conf->{pass};

    my $log = get_logger();

    $log->info("Connecting to the $driver server");
    $log->info("Parameters:");
    $log->info("  => Database = $dbname\n");
    $log->info("  => Server   = $host\n");
    $log->info("  => User     = $user\n");

    eval {
        $self->{_dbh} = DBI->connect(
            "dbi:Pg:"
                . "dbname="
                . $dbname
                . ";host="
                . $host
                . ";port="
                . $port,
            $user,
            $pass,
            {
                FetchHashKeyName => 'NAME_lc',
                AutoCommit       => 1,
                RaiseError       => 1,
                PrintError       => 0,
                LongReadLen      => 524288,
            }
        );
    };
    if ($@) {
        $log->fatal("Transaction aborted because $@")
            or print STDERR "$@\n";
        exit 1;
    }
    else {
        ## Date format
        # set: datestyle = 'iso' in postgresql.conf
        ##
        $self->{_dbh}{pg_enable_utf8} = 1;

        $log->info("Connected to database $dbname");

        return $self->{_dbh};
    }
}

=head2 table_info_short

Table info 'short'.  The 'table_info' method from the Pg driver
doesn't seem to be reliable.

=cut

sub table_info_short {
    my ($self, $table) = @_;

    my $log = get_logger();
    $log->info("Geting table info for $table");

    my $sql = qq( SELECT ordinal_position  AS pos
                    , column_name       AS name
                    , data_type         AS type
                    , column_default    AS defa
                    , is_nullable
                    , character_maximum_length AS length
                    , numeric_precision AS prec
                    , numeric_scale     AS scale
               FROM information_schema.columns
               WHERE table_name = '$table'
               ORDER BY ordinal_position;
    );

    $self->{_dbh}{ChopBlanks} = 1;          # trim CHAR fields

    my $flds_ref;
    eval {

        # List of lists
        my $sth = $self->{_dbh}->prepare($sql);
        $sth->execute;
        $flds_ref = $sth->fetchall_hashref('pos');
    };
    if ($@) {
        $log->fatal("Transaction aborted because $@")
            or print STDERR "$@\n";
    }

    return $flds_ref;
}

=head2 table_exists

Check if table exists in the database.

=cut

sub table_exists {
    my ($self, $table) = @_;

    my $log = get_logger();
    $log->info("Checking if $table table exists");

    my $sql = qq( SELECT COUNT(table_name)
                FROM information_schema.tables
                WHERE table_type = 'BASE TABLE'
                    AND table_schema NOT IN
                    ('pg_catalog', 'information_schema')
                    AND table_name = '$table';
    );

    $log->trace("SQL= $sql");

    my $val_ret;
    eval {
        ($val_ret) = $self->{_dbh}->selectrow_array($sql);
    };
    if ($@) {
        $log->fatal("Transaction aborted because $@")
            or print STDERR "$@\n";
    }

    return $val_ret;
}

=head2 table_keys

Get the primary key field name of the table.

=cut

sub table_keys {
    my ($self, $table, $foreign) = @_;

    my $log = get_logger();

    my $type = 'PRIMARY KEY';
    $type = 'FOREIGN KEY' if $foreign;

    $log->info("Geting '$table' table primary key(s) names");

    #  From http://www.alberton.info/postgresql_meta_info.html
    my $sql = qq( SELECT kcu.column_name
                   FROM information_schema.table_constraints tc
                     LEFT JOIN information_schema.key_column_usage kcu
                          ON tc.constraint_catalog = kcu.constraint_catalog
                            AND tc.constraint_schema = kcu.constraint_schema
                            AND tc.constraint_name = kcu.constraint_name
                   WHERE tc.table_name = '$table'
                     AND tc.constraint_type = '$type';
    );

    $log->trace("SQL= $sql");

    $self->{_dbh}{AutoCommit} = 1;    # disable transactions
    $self->{_dbh}{RaiseError} = 0;

    my $pkf = [];
    eval {
        # List of lists
        $pkf = $self->{_dbh}->selectall_arrayref( $sql );
    };
    if ($@) {
        $log->fatal("Transaction aborted because $@")
            or print STDERR "$@\n";
    }

    return $pkf;
}

=head2 table_deps

Return table dependencies and their Id field.

=cut

sub table_deps {
    my ($self, $table) = @_;

    return;
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

1; # End of Tpda3::Db::Connection::Postgresql