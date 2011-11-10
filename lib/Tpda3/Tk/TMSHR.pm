package Tpda3::Tk::TMSHR;

use strict;
use warnings;
use Carp;

use Hash::Merge qw(merge);

use Tpda3::Utils;

use Tk;
use base qw{Tk::Derived Tk::TableMatrix::SpreadsheetHideRows};

Tk::Widget->Construct('TMSHR');

=head1 NAME

Tpda3::Tk::TMSHR - Create a table matrix SpreadsheetHideRows widget.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    use Tpda3::Tk::TM;

    my ($xtvar, $expand_data) = ( {}, {} );
    my $xtable = $frame->Scrolled(
        'TMSHR',
        -rows           => 6,
        -cols           => 1,
        -width          => -1,
        -height         => -1,
        -ipadx          => 3,
        -titlerows      => 1,
        -validate       => 1,
        -variable       => $xtvar,
        -selectmode     => 'single',
        -colstretchmode => 'unset',
        -resizeborders  => 'none',
        -bg             => 'white',
        -scrollbars     => 'osw',
        -expandData     => $expand_data,
    );
    $xtable->pack( -expand => 1, -fill => 'both' );

    $xtable->init($frame, $header);

=head1 METHODS

=head2 ClassInit

Constructor method.

=cut

sub ClassInit {
    my ( $class, $mw ) = @_;

    $class->SUPER::ClassInit($mw);

    return;
}

=head2 Populate

Constructor method.

=cut

sub Populate {
    my ( $self, $args ) = @_;

    $self->SUPER::Populate($args);

    return $self;
}

=head2 init

Write header on row 0 of TableMatrix

=cut

sub init {
    my ( $self, $frame, $args ) = @_;

    $self->{columns}     = $args->{columns};
    $self->{selectorcol} = $args->{selectorcol};
    $self->{colstretch}  = $args->{colstretch};

    $self->{frame}  = $frame;
    $self->{tm_sel} = undef;    # selected row

    $self->set_tags();

    return;
}

=head2 set_tags

Set tags for the table matrix.

=cut

sub set_tags {
    my $self = shift;

    my $cols = scalar keys %{ $self->{columns} };

    # TM is SpreadsheetHideRows type increase cols number with 1
    $cols += 1 if $self =~ m/SpreadsheetHideRows/;

    # Tags for the detail data:
    $self->tagConfigure(
        'detail',
        -bg     => 'darkseagreen2',
        -relief => 'sunken',
    );
    $self->tagConfigure(
        'detail2',
        -bg     => 'burlywood2',
        -relief => 'sunken',
    );
    $self->tagConfigure(
        'detail3',
        -bg     => 'lightyellow',
        -relief => 'sunken',
    );

    $self->tagConfigure(
        'expnd',
        -bg     => 'grey85',
        -relief => 'raised',
    );
    $self->tagCol( 'expnd', 0 );

    # Make enter do the same thing as return:
    $self->bind( '<KP_Enter>', $self->bind('<Return>') );

    if ($cols) {
        $self->configure( -cols => $cols );

        # $self->configure( -rows => 1 ); # Keep table dim in grid
    }
    $self->tagConfigure(
        'active',
        -bg     => 'lightyellow',
        -relief => 'sunken',
    );
    $self->tagConfigure(
        'title',
        -bg     => 'tan',
        -fg     => 'black',
        -relief => 'raised',
        -anchor => 'n',
    );
    $self->tagConfigure( 'find_left', -anchor => 'w', -bg => 'lightgreen' );
    $self->tagConfigure(
        'find_center',
        -anchor => 'n',
        -bg     => 'lightgreen',
    );
    $self->tagConfigure(
        'find_right',
        -anchor => 'e',
        -bg     => 'lightgreen',
    );
    $self->tagConfigure( 'ro_left',      -anchor => 'w', -bg => 'lightgrey' );
    $self->tagConfigure( 'ro_center',    -anchor => 'n', -bg => 'lightgrey' );
    $self->tagConfigure( 'ro_right',     -anchor => 'e', -bg => 'lightgrey' );
    $self->tagConfigure( 'enter_left',   -anchor => 'w', -bg => 'white' );
    $self->tagConfigure( 'enter_center', -anchor => 'n', -bg => 'white' );
    $self->tagConfigure(
        'enter_center_blue',
        -anchor => 'n',
        -bg     => 'lightblue',
    );
    $self->tagConfigure( 'enter_right', -anchor => 'e', -bg => 'white' );
    $self->tagConfigure( 'find_row', -bg => 'lightgreen' );

    # TableMatrix header, Set Name, Align, Width
    foreach my $field ( keys %{ $self->{columns} } ) {
        my $col = $self->{columns}->{$field}{id};
        $self->tagCol( $self->{columns}->{$field}{tag}, $col );
        $self->set( "0,$col", $self->{columns}->{$field}{label} );

        # If colstretch = 'n' in screen config file, don't set width,
        # because of the -colstretchmode => 'unset' setting, col 'n'
        # will be of variable width
        next if $self->{colstretch} and $col == $self->{colstretch};

        my $width = $self->{columns}->{$field}{width};
        if ( $width and ( $width > 0 ) ) {
            $self->colWidth( $col, $width );
        }
    }

    $self->tagRow( 'title', 0 );
    if ( $self->tagExists('expnd') ) {

        # Change the tag priority
        $self->tagRaise( 'expnd', 'title' );
    }

    return;
}

=head2 clear_all

Clear all data from the Tk::TableMatrix widget, but preserve the header.

=cut

sub clear_all {
    my $self = shift;

    my $rows_no  = $self->cget( -rows );
    my $rows_idx = $rows_no - 1;
    my $r;

    $self->configure( -expandData => {} );   # clear detail data

    for my $row ( 1 .. $rows_idx ) {
        $self->deleteRows( $row, 1 );
    }

    return;
}

=head2 fill

Fill TableMatrix widget with data.

=cut

sub fill {
    my ( $self, $record_ref ) = @_;

    my $xtvar = $self->cget( -variable );

    my $row = 1;

    #- Scan and write to table

    foreach my $record ( @{$record_ref} ) {
        foreach my $field ( keys %{ $self->{columns} } ) {
            my $fld_cfg = $self->{columns}{$field};

            croak "$field field's config is EMPTY\n" unless %{$fld_cfg};

            my $value = $record->{$field};
            $value = q{} unless defined $value;    # empty
            $value =~ s/[\n\t]//g;                 # delete control chars

            my ( $col, $validtype, $width, $places )
                = @$fld_cfg{ 'id', 'validation', 'width',
                'places' };                        # hash slice

            if ( $validtype eq 'numeric' ) {
                $value = 0 unless $value;
                if ( defined $places ) {

                    # Daca SCALE >= 0, Formatez numarul
                    $value = sprintf( "%.${places}f", $value );
                }
                else {
                    $value = sprintf( "%.0f", $value );
                }
            }

            $xtvar->{"$row,$col"} = $value;
        }

        $row++;
    }

    # Refreshing the table...
    $self->configure( -rows => $row );

    return;
}

sub fill_details {
    my ( $self, $record_ref, $row ) = @_;

    my $xpdata = [];    # init
    my $r      = 0;

    #- Scan and write to table

    foreach my $record ( @{$record_ref} ) {
        foreach my $field ( keys %{ $self->{columns} } ) {
            my $fld_cfg = $self->{columns}{$field};

            croak "$field field's config is EMPTY\n" unless %{$fld_cfg};

            my $value = $record->{$field};
            $value = q{} unless defined $value;    # empty
            $value =~ s/[\n\t]//g;                 # delete control chars

            my ( $c, $validtype, $width, $places )
                = @$fld_cfg{ 'id', 'validation', 'width',
                'places' };                        # hash slice

            if ( $validtype eq 'numeric' ) {
                $value = 0 unless $value;
                if ( defined $places ) {

                    # Daca SCALE >= 0, Formatez numarul
                    $value = sprintf( "%.${places}f", $value );
                }
                else {
                    $value = sprintf( "%.0f", $value );
                }
            }

            $xpdata->[$r][$c] = $value;
        }

        $r++;
    }

    my $data_new = {
        $row => {
            data => $xpdata,
            tag  => 'detail',
        },
    };

    my $xpdvar_old = $self->cget( -expandData );
    my $xpdvar_new = merge($xpdvar_old, $data_new);

    $self->configure( -expandData => $xpdvar_new );

    return;
}

=head2 write_row

Write a row to a TableMatrix widget.

TableMatrix designator is optional and default to 'tm1'.

=cut

sub write_row {
    my ( $self, $row, $col, $record_ref ) = @_;

    return unless ref $record_ref;    # No results

    my $xtvar = $self->cget( -variable );

    my $nr_col = 0;
    foreach my $field ( keys %{$record_ref} ) {

        my $fld_cfg = $self->{columns}{$field};
        my $value   = $record_ref->{$field};

        my ( $col, $validtype, $width, $places )
            = @$fld_cfg{ 'id', 'validation', 'width', 'places' }; # hash slice

        if ( $validtype =~ /digit/ ) {
            $value = 0 unless $value;
            if ( defined $places ) {

                # Daca SCALE >= 0, Formatez numarul
                $value = sprintf( "%.${places}f", $value );
            }
            else {
                $value = sprintf( "%.0f", $value );
            }
        }

        $xtvar->{"$row,$col"} = $value;
        $nr_col++;
    }

    return $nr_col;
}

=head1 AUTHOR

Stefan Suciu, C<< <stefansbv at user.sourceforge.net> >>

=head1 BUGS

None known.

Please report any bugs or feature requests to the author.

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Stefan Suciu.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation.

=cut

1;    # end of Tpda3::Tk::TM