package Tpda3::Wx::View;

use strict;
use warnings;

use Carp;
#use POSIX qw (floor);

use Log::Log4perl qw(get_logger);

use File::Spec::Functions qw(abs2rel);
use Wx qw{:everything};

use base 'Wx::Frame';

use Tpda3::Config;
use Tpda3::Utils;
#use Tpda3::Wx::Notebook;
use Tpda3::Wx::ToolBar;

=head1 NAME

Tpda3::Wx::App - Wx Perl application class

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

    use Tpda3::Wx::Notebook;

    $self->{_nb} = Tpda3::Wx::Notebook->new( $gui );

=head1 METHODS

=head2 new

Constructor method.

=cut

sub new {
    my $class = shift;
    my $model = shift;

    #- The Frame

    my $self = __PACKAGE__->SUPER::new( @_ );

    Wx::InitAllImageHandlers();

    $self->{_model} = $model;

    $self->{_cfg} = Tpda3::Config->instance();

    $self->SetMinSize( Wx::Size->new( 460, 240 ) );
    $self->SetIcon( Wx::GetWxPerlIcon() );

    #-- Menu
    $self->_create_menu();
    $self->_create_app_menu();

    #-- ToolBar
    $self->_create_toolbar();

    #-- Statusbar
    $self->_create_statusbar();

    $self->_set_model_callbacks();

    $self->Fit;

    return $self;
}

=head2 _model

Return model instance

=cut

sub _model {
    my $self = shift;

    $self->{_model};
}
=head2 _cfg

Return config instance variable

=cut

sub _cfg {
    my $self = shift;

    return $self->{_cfg};
}

=head2 _set_model_callbacks

Define the model callbacks.

=cut

sub _set_model_callbacks {
    my $self = shift;

    my $co = $self->_model->get_connection_observable;
    $co->add_callback(
        sub {
            $self->toggle_status_cn( $_[0] );
        }
    );

    my $so = $self->_model->get_stdout_observable;
    $so->add_callback( sub{ $self->set_status( $_[0], 'ms') } );

    # When the status changes, update gui components
    my $apm = $self->_model->get_appmode_observable;
    $apm->add_callback(
        sub { $self->update_gui_components(); } );

    return;
}

=head2 update_gui_components

When the application status (mode) changes, update gui components.
Screen controls (widgets) are not handled here, but in controller
module.

=cut

sub update_gui_components {
    my $self = shift;

    my $mode = $self->_model->get_appmode();

    $self->set_status($mode, 'md');          # update statusbar

    SWITCH: {
          $mode eq 'find' && do {
              $self->{_tb}->toggle_tool_check( 'tb_ad', 0 );
              $self->{_tb}->toggle_tool_check( 'tb_fm', 1 );
              last SWITCH;
          };
          $mode eq 'add' && do {
              $self->{_tb}->toggle_tool_check( 'tb_ad', 1 );
              $self->{_tb}->toggle_tool_check( 'tb_fm', 0 );
              last SWITCH;
          };

          # Else
          $self->{_tb}->toggle_tool_check( 'tb_ad', 0 );
          $self->{_tb}->toggle_tool_check( 'tb_fm', 0 );
      }

    return;
}

=head2 _create_menu

Create the menubar and the menus. Menus are defined in configuration
files.

=cut

sub _create_menu {
    my $self = shift;

    my $menu = Wx::MenuBar->new;

    $self->{_menu} = $menu;

    $self->make_menus( $self->_cfg->menubar );

    $self->SetMenuBar($menu);

    return;
}

=head2 _create_app_menu

Insert application menu. The menubars are inserted after the first
item of the default menu.

=cut

sub _create_app_menu {
    my $self = shift;

    my $attribs = $self->_cfg->appmenubar;

    $self->make_menus($attribs, 1);  # insert starting with position 1

    return;
}

=head2 make_menus

Make menus.

=cut

sub make_menus {
    my ($self, $attribs, $position) = @_;

    $position = $position ||= 0;             # default

    my $menus = Tpda3::Utils->sort_hash_by_id($attribs);

    #- Create menus
    foreach my $menu_name ( @{$menus} ) {

        $self->{$menu_name} = Wx::Menu->new();

        my @popups = sort { $a <=> $b } keys %{ $attribs->{$menu_name}{popup} };
        foreach my $id (@popups) {
            $self->make_popup_item(
                $self->{$menu_name},
                $attribs->{$menu_name}{popup}{$id},
                $attribs->{$menu_name}{id} . $id, # menu Id
            );
        }

        $self->{_menu}->Insert(
            $position,
            $self->{$menu_name},
            Tpda3::Utils->ins_underline_mark(
                $attribs->{$menu_name}{label},
                $attribs->{$menu_name}{underline}
            ),
        );

        $position++;
    }

    return;
}

=head2 get_app_menus_list

Get application menus list, needed for binding the command to load the
screen.  We only need the name of the popup which is also the name of
the screen (and also the name of the module).

=cut

sub get_app_menus_list {
    my $self = shift;

    my $attribs = $self->_cfg->appmenubar;
    my $menus = Tpda3::Utils->sort_hash_by_id($attribs);

    my @menulist;
    foreach my $menu_name ( @{$menus} ) {
        my @popups = sort { $a <=> $b } keys %{ $attribs->{$menu_name}{popup} };
        foreach my $item (@popups) {
            push @menulist, $attribs->{$menu_name}{popup}{$item}{name};
        }
    }

    return \@menulist;
}

=head2 make_popup_item

Make popup item

=cut

sub make_popup_item {
    my ( $self, $menu, $item, $id ) = @_;

    $menu->AppendSeparator() if $item->{sep} eq 'before';

    # Preserve some default Id's used by Wx
    $id = wxID_ABOUT if $item->{name} eq q{mn_ab};
    $id = wxID_EXIT  if $item->{name} eq q{mn_qt};

    $self->{ $item->{name} } = $menu->Append(
        $id,
        Tpda3::Utils->ins_underline_mark(
            $item->{label},
            $item->{underline},
        ),
    );

    $menu->AppendSeparator() if $item->{sep} eq 'after';

    return;
}

=head2 get_menu_popup_item

Return a menu popup by name

=cut

sub get_menu_popup_item {
    my ( $self, $name ) = @_;

    return $self->{_menu}{$name};
}

=head2 get_menubar

Return the menu bar handler

=cut

sub get_menubar {
    my $self = shift;

    return $self->{_menu};
}

=head2 _create_toolbar

Create toolbar

=cut

sub _create_toolbar {
    my $self = shift;

    my $tb = Tpda3::Wx::ToolBar->new( $self, wxADJUST_MINSIZE );

    my ($toolbars, $attribs) = $self->toolbar_names();

    my $ico_path = $self->{_cfg}->cfico;

    $tb->make_toolbar_buttons($toolbars, $attribs, $ico_path);

    $self->SetToolBar($tb);

    $self->{_tb} = $self->GetToolBar;
    $self->{_tb}->Realize;

    return;
}

=head2 toolbar_names

Get Toolbar names as array reference from config.

=cut

sub toolbar_names {
    my $self = shift;

    # Get ToolBar button atributes
    my $attribs = $self->_cfg->toolbar;

    # TODO: Change the config file so we don't need this sorting anymore
    # or better keep them sorted and ready to use in config
    my $toolbars = Tpda3::Utils->sort_hash_by_id($attribs);

    return ($toolbars, $attribs);
}

=head2 toggle_tool

Toggle tool bar button.  If state is defined then set to state do not
toggle.

State can come as 0 | 1 and normal | disabled.

=cut

sub enable_tool {
    my ($self, $btn_name, $state) = @_;

    $self->{_tb}->enable_tool($btn_name, $state);

    return;
}

=head2 create_statusbar

Create a statusbar with 3 fields.  The first field have a fixed width,
the rest have variable widths.

=cut

sub _create_statusbar {
    my $self = shift;

    $self->{_sb} = $self->CreateStatusBar( 3 );

    $self->SetStatusWidths( 260, -1, -2 );

    # $self->{_sb}->SetStatusStyles(3, wxSB_RAISED); #  wxSB_RAISED  wxSB_FLAT

    return;
}

=head2 get_statusbar

Return the statusbar handler.

=cut

sub get_statusbar {
    my $self = shift;

    return $self->{_sb};
}

=head2 get_notebook

Return the notebook handler

=cut

sub get_notebook {
    my $self = shift;

    return $self->{_nb};
}

=head2 dialog_popup

Define a dialog popup.

=cut

sub dialog_popup {
    my ( $self, $msgtype, $msg ) = @_;

    if ( $msgtype eq 'Error' ) {
        Wx::MessageBox( $msg, $msgtype, wxOK|wxICON_ERROR, $self )
    }
    elsif ( $msgtype eq 'Warning' ) {
        Wx::MessageBox( $msg, $msgtype, wxOK|wxICON_WARNING, $self )
    }
    else {
        Wx::MessageBox( $msg, $msgtype, wxOK|wxICON_INFORMATION, $self )
    }
}

=head2 action_confirmed

Yes - No message dialog.

=cut

sub action_confirmed {
    my ( $self, $msg ) = @_;

    my( $answer ) =  Wx::MessageBox(
        $msg,
        'Confirm',
        Wx::wxYES_NO(),  # if you use Wx ':everything', it's wxYES_NO
        undef,           # you needn't pass anything, much less $frame
     );

     if( $answer == Wx::wxYES() ) {
         return 1;
     }
}

=head2 get_toolbar_btn

Return a toolbar button by name.

=cut

sub get_toolbar_btn {
    my ( $self, $name ) = @_;

    return $self->{_tb}->get_toolbar_btn($name);
}

=head2 get_toolbar

Return the toolbar handler.

=cut

sub get_toolbar {
    my $self = shift;

    return $self->{_tb};
}

=head2 get_control_by_name

Return the control instance by name.

=cut

sub get_control_by_name {
    my ($self, $name) = @_;

    return $self->{$name},
}

=head2 log_config_options

Log configuration options with data from the Config module.

=cut

sub log_config_options {
    my $self = shift;

    my $cfg  = Tpda3::Config->instance();
    my $path = $cfg->output;

    while ( my ( $key, $value ) = each( %{$path} ) ) {
        $self->log_msg("II Config: '$key' set to '$value'");
    }
}

=head2 set_status

Set status message.

Color is ignored for wxPerl.

=cut

sub set_status {
    my ( $self, $text, $sb_id, $color ) = @_;

    print "set_status_msg $text \n";

    my $sb = $self->get_statusbar();

    if ( $sb_id eq 'cn' ) {
        $sb->SetStatusText( $text, 2 ) if defined $text;
    }
    elsif ($sb_id eq 'ms') {
        $sb->SetStatusText( $text, 0 ) if defined $text;
    }
    else {
        $sb->SetStatusText( $text, 1 ) if defined $text;
    }

    return;
}

=head2 dialog_msg

Set dialog message

=cut

sub dialog_msg {
    my ( $self, $message ) = @_;

    $self->dialog_popup( 'Error', $message );
}

=head2 log_msg

Log messages

=cut

sub log_msg {
    my ( $self, $msg ) = @_;

    my $log = get_logger();

    $log->info($msg);

    return;
}

=head2 control_set_value

Set new value for a controll

=cut

sub control_set_value {
    my ($self, $name, $value) = @_;

    return unless defined $value;

    my $ctrl = $self->get_control_by_name($name);

    $ctrl->ClearAll;
    $ctrl->AppendText($value);
    $ctrl->AppendText( "\n" );
    $ctrl->Colourise( 0, $ctrl->GetTextLength );

}

=head2 control_set_value

Set new value for a controll

=cut

sub control_append_value {
    my ($self, $name, $value) = @_;

    return unless defined $value;

    my $ctrl = $self->get_control_by_name($name);

    $ctrl->AppendText($value);
    $ctrl->AppendText( "\n" );
    $ctrl->Colourise( 0, $ctrl->GetTextLength );
}

=head2 toggle_status_cn

Toggle the icon in the status bar

=cut

sub toggle_status_cn {
    my ($self, $status) = @_;

    if ($status) {
        $self->set_status($self->_cfg->connection->{dbname},'db','darkgreen');
    }
    else {
        $self->set_status('','db');
    }

    return;
}

=head1 AUTHOR

Stefan Suciu, C<< <stefansbv at user.sourceforge.net> >>

=head1 BUGS

None known.

Please report any bugs or feature requests to the author.

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2010 - 2011 Stefan Suciu.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation.

=cut

1; # End of Tpda3::Wx::View
