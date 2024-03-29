package Tpda3::Wx::Grid::Table;

use strict;
use warnings;
use Carp;
use Data::Printer;

use Wx::Grid;
use Wx qw(wxRED wxGREEN wxALIGN_LEFT wxALIGN_CENTRE wxALIGN_RIGHT
          wxALIGN_TOP wxALIGN_CENTRE wxALIGN_BOTTOM
          wxGRIDTABLE_NOTIFY_ROWS_INSERTED wxGRIDTABLE_NOTIFY_ROWS_DELETED);

use base qw(Wx::PlGridTable Tpda3::Wx::CP::Class);

our @properties = qw( tabledata );

__PACKAGE__->create_both_accessors( @properties );

my %default = (
    integer => 0,
    string  => q{},
    double  => 0.00,
);

=head1 NAME

Tpda3::Wx::GridTable

=head1 VERSION

Version 0.66

=cut

our $VERSION = 0.66;

=head1 SYNOPSIS

=head1 DESCRIPTION

wxGridTableBase

Documentation from gridtablebase.h:

The almost abstract base class for grid tables.

A grid table is responsible for storing the grid data and, indirectly,
grid cell attributes. The data can be stored in the way most
convenient for the application but has to be provided in string form
to wxGrid. It is also possible to provide cells values in other
formats if appropriate, e.g. as numbers.

This base class is not quite abstract as it implements a trivial
strategy for storing the attributes by forwarding it to
wxGridCellAttrProvider and also provides stubs for some other
functions. However it does have a number of pure virtual methods which
must be implemented in the derived classes.

=cut

sub new {
    my ( $class, $data, $grid ) = @_;

    my $self = $class->SUPER::new();

    $self->set_tabledata($data);

    $self->{view} = $grid;

    return $self;
}

=head2 GetView

Overridden to return the grid? Otherwise GetView returns undef.

=cut

sub GetView {
    my $self = shift;

    return $self->{view};
}

=head2 GetNumberRows

Overridden to return the number of rows in the table.

=cut

sub GetNumberRows {
    my $self = shift;

    my $rowcount = scalar( @{ $self->get_tabledata->{datarows} } );

    return $rowcount;
}

=head2 GetNumberCols

Overridden to return the number of columns in the table.

=cut

sub GetNumberCols {
    my $self = shift;

    my $colcount = scalar( @{ $self->get_tabledata->{datacols} } );

    return $colcount;
}

=head2 IsEmptyCell

Overridden to implement testing for empty cells.

=cut

sub IsEmptyCell {
    my ( $self, $row, $col ) = @_;

    return ( defined( $self->get_tabledata->{datarows}->[$row]->[$col] ) )
        ? 0
        : 1;
}

=head2 GetValue

Overridden to implement accessing the table values as text.

=cut

sub GetValue {
    my ( $self, $row, $col ) = @_;

    my $result = undef;
    eval {
        $result = $self->get_tabledata->{datarows}[$row][$col]
            if  $row < $self->GetNumberRows
            and $col < $self->GetNumberCols
            and defined $self->get_tabledata->{datarows}[$row][$col];
    };
    croak "Exception in Grid::Table::GetValue: $@" if $@;
    my $type = $self->GetTypeName(0, $col);
    $result = $default{$type} unless defined $result;

    return $result;
}

sub get_data_all {
    my $self = shift;

    return $self->get_tabledata->{datarows};
}

=head2 SetValue

Overridden to implement setting the table values as text.

=cut

sub SetValue {
    my ( $self, $row, $col, $value ) = @_;

    carp "row overflow" if $row > $self->GetNumberRows;
    carp "col overflow" if $col > $self->GetNumberCols;

    my $type = $self->GetTypeName(0, $col);
    $value = $default{$type} unless defined $value;

    #print "I: $row, $col, $value\n";
    $self->get_tabledata->{datarows}[$row][$col] = $value;
}

###

sub GetTypeName {
    my($self, $row, $col) = @_;
    return $self->get_tabledata->{datacols}[$col]{type};
}

sub CanGetValueAs {
    my($self, $row, $col) = @_;
    return $self->get_tabledata->{datacols}->[$col]->{type};
}

sub CanSetValueAs {
    my($self, $row, $col) = @_;
    return $self->get_tabledata->{datacols}->[$col]->{type};
}

sub GetValueAsLong { shift->GetValue( @_ ); }

sub GetValueAsDouble { shift->GetValue( @_ ); }

sub GetValueAsBool { shift->GetValue( @_ ); }

sub SetValueAsLong { shift->SetValue( @_ ); }

sub SetValueAsDouble { shift->SetValue( @_ ); }

sub SetValueAsBool { shift->SetValue( @_ ); }

###

=head1 Table Structure Modifiers

Notice that none of these functions are pure virtual as they don't
have to be implemented if the table structure is never modified after
creation, i.e. neither rows nor columns are never added or deleted but
that you do need to implement them if they are called, i.e. if your
code either calls them directly or uses the matching wxGrid methods,
as by default they simply do nothing which is definitely
inappropriate.

Clear the table contents.

sub Clear {

}

=head2 InsertRows

Insert additional rows into the table.

=cut

sub InsertRows {
    my ( $self, $pos, $rows ) = @_;
    return 0;
}

=head2 AppendRows

Append additional rows at the end of the table.

=cut

sub AppendRows {
    my ( $self, $pos, $rows, $record_aref ) = @_;

    $rows = 1 unless defined $rows && $rows >= 0;

    return 0 if $rows == 0;

    print " AppendRows: pos=$pos rows=$rows\n";
    my $table_cols = $self->GetNumberCols;
    my $data_cols  = scalar @{$record_aref};

    croak "Wrong data columns number got:$data_cols, expected $table_cols"
        if $table_cols != $data_cols;

    # Insert data
    for (my $col = 0; $col < $data_cols; $col++) {
        $self->SetValue( $pos, $col, $record_aref->[$col] );
    }

    # Notify the Grid about the insert
    eval {
        if ( my $grid = $self->GetView() ) {
            my $msg
                = Wx::GridTableMessage->new( $self,
                wxGRIDTABLE_NOTIFY_ROWS_INSERTED,
                $pos, $rows );
            $grid->ProcessTableMessage($msg);
        }
        else {
            croak "No Grid!\n";
        }
    };
    if ($@) {
        croak "Grid::Table::AppendRows Exception: $@";
        return 0;
    }

    return 1;
}

=head2 DeleteRows

Delete rows from the table.

=cut

sub DeleteRows {
    my ( $self, $pos, $rows ) = @_;

    $rows = 1 unless defined $rows && $rows >= 0;

    return 0 if $rows == 0;

    print " DeleteRows: pos=$pos rows=$rows\n";

    my $data = $self->get_data_all;
    splice @{$data}, $pos, $rows;            # why does this work ???

    eval {
        if ( my $grid = $self->GetView() ) {
            my $msg
                = Wx::GridTableMessage->new( $self,
                wxGRIDTABLE_NOTIFY_ROWS_DELETED,
                $pos, $rows );
            $grid->ProcessTableMessage($msg);
        }
        else {
            croak "No Grid!\n";
        }
    };
    if ($@) {
        croak "Grid::Table::DeleteRows Exception: $@";
        return 0;
    }

    return 1;
}

=head2 InsertCols

Exactly the same as InsertRows() but for columns.

sub InsertCols {
    my ($pos, $numCols);
}

Exactly the same as AppendRows() but for columns.

sub AppendCols {
    my ($numCols);
    return;
}

Exactly the same as DeleteRows() but for columns.

sub DeleteCols {
    my ($pos, $numCols);
}

=head1 Table Row and Column Labels

=head2 GetRowLabelValue

Return the label of the specified row.

=cut

sub GetRowLabelValue {
    my ($self, $row) = @_;

    return "RLV$row";
}

=head2 GetColLabelValue

Return the label of the specified column.

=cut

sub GetColLabelValue {
    my ($self, $col) = @_;

    return $self->get_tabledata->{datacols}[$col]{label};
}

=head2 SetRowLabelValue

Set the given label for the specified row.

The default version does nothing, i.e. the label is not stored. You
must override this method in your derived class if you wish
wxGrid::SetRowLabelValue() to work.

=cut

sub SetRowLabelValue {
    my ($self, $row, $label) = @_;

    return;
}

=head2 SetColLabelValue

Set the given label for the specified col.

The default version does nothing, i.e. the label is not stored. You
must override this method in your derived class if you wish
wxGrid::SetRowLabelValue() to work.

=cut

sub SetColLabelValue {
    my ($self, $col, $label) = @_;

    return;
}

=head1 Attributes Management

By default the attributes management is delegated to
wxGridCellAttrProvider class. You may override the methods in this
section to handle the attributes directly if, for example, they can be
computed from the cell values.

Associate this attributes provider with the table.
SetAttrProvider(wxGridCellAttrProvider *attrProvider);

Returns the attribute provider currently being used.
GetAttrProvider

Return the attribute for the given cell.

=cut

=head1 GetAttr

GetAttr(int row, int col, wxGridCellAttr::wxAttrKind kind)

=cut

sub GetAttr {
  my( $self, $row, $col, $kind ) = @_;

  my $cell_attr = Wx::GridCellAttr->new;

  # Text alignment
  if ($self->GetTypeName(0, $col) eq 'double' ) {
      $cell_attr->SetAlignment(wxALIGN_RIGHT, wxALIGN_TOP);
  }
  elsif ($self->GetTypeName(0, $col) eq 'int_id') {
      $cell_attr->SetAlignment(wxALIGN_CENTRE, wxALIGN_TOP);
  }

  $cell_attr->SetOverflow(0);

  return $cell_attr;
}

=head1 Attribs

Set attribute of the specified cell.
SetAttr(wxGridCellAttr* attr, int row, int col);

Set attribute of the specified row.
SetRowAttr(wxGridCellAttr *attr, int row);

Set attribute of the specified column.
SetColAttr(wxGridCellAttr *attr, int col);

Returns true if this table supports attributes or false otherwise.
CanHaveAttributes();

=cut

1;

=head1 AUTHOR

Stefan Suciu, C<< <stefan@s2i2.ro> >>

=head1 BUGS

None known.

Please report any bugs or feature requests to the author.

=head1 ACKNOWLEDGMENTS

Based on the CP::Wx::Grid::Table module Copyright (c) 2012 Mark
Dootson and the DBGridTable package example from
http://wiki.wxperl.nl/Wx::GridTableBase.

Also the Grid_MegaExample.py from
git://github.com/freephys/wxPython-In-Action.git, is a good source of
inspiration.

Thank you!

=head1 LICENSE AND COPYRIGHT

Copyright:
  Mark Dootson  2012
  Stefan Suciu  2013

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation.

=cut

1;    # End of Tpda3::Wx::Grid::Table
