package Tpda3::Tk::Dialog::AppList;

use strict;
use warnings;

use Tk;
use Tk::widgets qw(StatusBar LabFrame JComboBox);

require Tpda3::Config;
require Tpda3::Tk::TM;

=head1 NAME

Tpda3::Tk::Dialog::AppList - Dialog for the applications list.

=head1 VERSION

Version 0.66

=cut

our $VERSION = 0.66;

=head1 SYNOPSIS

    use Tpda3::Tk::Dialog::AppList;

    my $fd = Tpda3::Tk::Dialog::AppList->new;

    $fd->login($self);

=head1 METHODS

=head2 new

Constructor method

=cut

sub new {
    my $class = shift;

    my $self = {
        mnemonics => [],
        selected  => undef,
        _cfg      => Tpda3::Config->instance(),
    };

    bless $self, $class;

    return $self;
}

=head2 cfg

Return config instance variable

=cut

sub cfg {
    my $self = shift;

    return $self->{_cfg};
}

=head2 show_app_list

Show dialog.

=cut

sub show_app_list {
    my ( $self, $view ) = @_;

    $self->{tlw} = $view->Toplevel();
    $self->{tlw}->title('AppList');
    #$self->{tlw}->geometry('430x420');

    my $f1d = 110;              # distance from left

    #-- Key bindings

    $self->{tlw}->bind( '<Escape>', sub { $self->dlg_exit } );

    #-- StatusBar

    my $sb = $self->{tlw}->StatusBar();

    # Dummy label for left space
    my $ldumy = $sb->addLabel(
        -width  => 1,
        -relief => 'flat',
    );

    $self->{_sb}{ms} = $sb->addLabel( -relief => 'flat' );

    #-- end StatusBar

    #- Main frame

    my $mf = $self->{tlw}->Frame();
    $mf->pack(
        -side   => 'top',
        -expand => 1,
        -fill   => 'both',
    );

    #-  Frame top - TM

    my $frm_top = $mf->LabFrame(
        -foreground => 'blue',
        -label      => 'List',
        -labelside  => 'acrosstop'
    )->pack(
        -expand => 1,
        -fill   => 'both',
    );

    my $xtvar1 = {};
    $self->{tmx} = $frm_top->Scrolled(
        'TM',
        -rows           => 5,
        -cols           => 4,
        -width          => -1,
        -height         => -1,
        -ipadx          => 3,
        -titlerows      => 1,
        -variable       => $xtvar1,
        -selectmode     => 'single',
        -selecttype     => 'row',
        -colstretchmode => 'unset',
        -resizeborders  => 'none',
        -bg             => 'white',
        -scrollbars     => 'osw',
        -validate       => 1,
        -vcmd           => sub { $self->select_idx(@_) },
    );
    $self->{tmx}->pack(
        -expand => 1,
        -fill   => 'both',
    );

    #-- TM header

    my $header = {
        colstretch    => 2,
        selectorcol   => 3,
        selectorstyle => 'radio',
        selectorcolor => 'darkgreen',
        columns       => {
            id_rep => {
                id          => 0,
                label       => '#',
                tag         => 'ro_center',
                displ_width => 3,
                valid_width => 5,
                numscale    => 0,
                readwrite   => 'ro',
                datatype    => 'integer',
            },
            title => {
                id          => 1,
                label       => 'Mnemonic',
                tag         => 'ro_left',
                displ_width => 10,
                valid_width => 10,
                numscale    => 0,
                readwrite   => 'ro',
                datatype    => 'alphanumplus',
            },
            descr => {
                id          => 2,
                label       => 'Application name',
                tag         => 'ro_left',
                displ_width => 25,
                valid_width => 25,
                numscale    => 0,
                readwrite   => 'ro',
                datatype    => 'alphanumplus',
            },
        },
    };

    $self->{tmx}->init( $frm_top, $header );
    $self->{tmx}->clear_all;
    $self->{tmx}->configure(-state => 'disabled');

    #-  Frame middle - Entries

    my $frm_middle = $mf->LabFrame(
        -foreground => 'blue',
        -label      => 'Connection',
        -labelside  => 'acrosstop'
    );
    $frm_middle->pack(
        -expand => 0,
        -fill   => 'x',
        -ipadx  => 3,
        -ipady  => 3,
    );

    #-- driver

    #- ComboBox choices
    my $choices = [
        { -name => 'CUBRID',     -value => 'cubrid', },
        { -name => 'Firebird',   -value => 'firebird', },
        { -name => 'PostgreSQL', -value => 'postgresql', },
        { -name => 'SQLite',     -value => 'sqlite', },
    ];

    my $ldriver = $frm_middle->Label( -text => 'Driver', );
    $ldriver->form(
        -top     => [ %0, 5 ],
        -left    => [ %0, 0 ],
        -padleft => 10,
    );

    my $selected;
    my $cdriver = $frm_middle->JComboBox(
        -entrywidth         => 15,
        -textvariable       => \$selected,
        -choices            => $choices,
        -state              => 'disabled',
        -disabledforeground => 'black',
    );
    $cdriver->form(
        -top  => [ '&', $ldriver, 0 ],
        -left => [ %0, ($f1d + 1) ],
    );

    #-- host

    my $lhost = $frm_middle->Label( -text => 'Host' );
    $lhost->form(
        -top     => [ $ldriver, 8 ],
        -left    => [ %0, 0 ],
        -padleft => 10,
    );
    my $ehost = $frm_middle->Entry(
        -width              => 36,
        -state              => 'disabled',
        -disabledforeground => 'black',
    );
    $ehost->form(
        -top  => [ '&', $lhost, 0 ],
        -left => [ %0, $f1d ],
    );

    #-- dbname

    my $ldbname = $frm_middle->Label( -text => 'Database' );
    $ldbname->form(
        -top     => [ $lhost, 8 ],
        -left    => [ %0, 0 ],
        -padleft => 10,
    );
    my $edbname = $frm_middle->Entry(
        -width              => 36,
        -state              => 'disabled',
        -disabledforeground => 'black',
    );
    $edbname->form(
        -top  => [ '&', $ldbname, 0 ],
        -left => [ %0, $f1d ],
    );

    #-- port

    my $lport = $frm_middle->Label( -text => 'Port' );
    $lport->form(
        -top     => [ $ldbname, 8 ],
        -left    => [ %0, 0 ],
        -padleft => 10,
    );
    my $eport = $frm_middle->Entry(
        -width              => 5,
        -state              => 'disabled',
        -disabledforeground => 'black',
    );
    $eport->form(
        -top  => [ '&', $lport, 0 ],
        -left => [ %0, $f1d ],
    );

    #-  Frame bottom - Buttons

    my $frm_bottom = $mf->Frame();
    $frm_bottom->pack(
        -expand => 0,
        -fill   => 'both',
    );

    my $test_b = $frm_bottom->Button(
        -text    => 'Set',
        -width   => 10,
        -command => sub { $self->save_as_default() },
    );
    $test_b->pack( -side => 'left', -padx => 20, -pady => 5 );

    my $close_b = $frm_bottom->Button(
        -text    => 'Close',
        -width   => 10,
        -command => sub { $self->dlg_exit },
    );
    $close_b->pack( -side => 'right', -padx => 20, -pady => 5 );

    # End

    # Entry objects
    $self->{controls} = {
        driver => [ \$selected, $cdriver ],
        port   => [ undef,      $eport ],
        dbname => [ undef,      $edbname ],
        host   => [ undef,      $ehost ],
    };

    $self->load_mnemonics();
    $self->select_default();

    return;
}

=head2 load_mnemonics

Load the mnemonics data.

=cut

sub load_mnemonics {
    my $self = shift;

    my $mnemonics_ref = $self->cfg->get_mnemonics();
    my $cnt = 1;
    my @mnemos;
    foreach my $mnemonic ( @{$mnemonics_ref} ) {
        next if $mnemonic eq 'test-wx';      # skip Wx apps

        my $record = {
            id_rep => $cnt,
            title  => $mnemonic,
            descr  => '',
        };
        $self->{tmx}->add_row();
        $self->{tmx}->write_row( $cnt, 0, $record );

        # Store mnemonics list
        push @mnemos, { idx => $cnt, name => $mnemonic };

        $cnt++;
    }

    $self->{mnemonics} = \@mnemos;

    return;
}

=head2 select_default

Select the default mnemonic, the one from the command line id any else
the first.

=cut

sub select_default {
    my $self = shift;

    my $selected = 1;           # default

    foreach my $rec ( @{ $self->{mnemonics} } ) {
        $selected = $rec->{idx} if $rec->{name} eq $self->cfg->cfname;
    }

    $self->select_idx($selected);

    return;
}

=head2 select_idx

Select the mnemonic at the index and load its details.

=cut

sub select_idx {
    my ($self, $sel) = @_;

    my $idx = $sel -1 ;
    my $rec = $self->{mnemonics}[$idx];
    $self->{tmx}->set_selected($sel);
    $self->load_mnemonic_details_for($rec);
    $self->{selected} = $rec->{name};

    return;
}

=head2 load_mnemonic_details_for

Load the selected mnemonic details in the controls.

=cut

sub load_mnemonic_details_for {
    my ( $self, $rec ) = @_;

    my $conn_ref = $self->cfg->get_details_for( $rec->{name} );

    return unless ref $conn_ref;

    #- Write data to the controls
    foreach my $field ( keys %{ $self->{controls} } ) {
        my $value = $conn_ref->{connection}{$field};
        if ( defined $self->{controls}{$field}[0] ) {
            # JComboBox
            $self->{controls}{$field}[1]
                ->setSelected( $value, -type => 'value' );
        }
        else {
            # Entry
            my $start_idx = 0;
            $self->{controls}{$field}[1]->configure( -state => 'normal');
            $self->{controls}{$field}[1]->delete( $start_idx, 'end' );
            $self->{controls}{$field}[1]->insert( $start_idx, $value )
                if $value;
            $self->{controls}{$field}[1]->configure( -state => 'disabled');
        }
    }

    $self->_set_status('');    # clear

    return;
}

=head2 save_as_default

Save the curent mnemonic as default.

=cut

sub save_as_default {
    my $self = shift;

    $self->cfg->set_default_mnemonic( $self->{selected} );
    $self->_set_status( '[' .$self->{selected} . '] '
            . 'active after restart, if not overridden by CLI option.'
    );

    return;
}

=head2 _set_status

Display message in the status bar.

=cut

sub _set_status {
    my ( $self, $text, $color ) = @_;

    my $sb_label = $self->{_sb}{'ms'};

    return unless ( $sb_label and $sb_label->isa('Tk::Label') );

    # ms
    $sb_label->configure( -text       => $text )  if defined $text;
    $sb_label->configure( -foreground => $color ) if defined $color;

    return;
}

=head2 dlg_exit

Quit Dialog.

=cut

sub dlg_exit {
    my $self = shift;

    $self->{tlw}->destroy;

    return;
}

=head1 AUTHOR

Stefan Suciu, C<< <stefan@s2i2.ro> >>

=head1 BUGS

None known.

Please report any bugs or feature requests to the author.

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2013 Stefan Suciu.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation.

=cut

1;    # End of Tpda3::Tk::Dialog::AppList
