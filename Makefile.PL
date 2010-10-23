#
# Makefile.PL for tpda-mvc
#
# Copyright (C) 2010  Stefan Suciu
# GNU General Public License v3
#

use 5.010;
use strict;
use warnings;

use inc::Module::Install;

name     'Tpda3';
all_from 'lib/Tpda3.pm';

requires 'perl'                       => '5.008005';
requires 'Class::Singleton'           => '1.4';
requires 'Class::Accessor'            => '0';
requires 'Number::Compare'            => '0';
requires 'File::UserConfig'           => '0';
requires 'File::Find::Rule'           => '0.30';
requires 'File::HomeDir'              => '0.89';
requires 'File::Spec::Functions'      => '0';
requires 'DBI'                        => '1.53';
requires 'DBD::InterBase'             => '0.44';
requires 'DBD::Pg'                    => '1.32';
requires 'DBD::mysql'                 => '4.004';
requires 'Tk'                         => '804.028';
requires 'Tk::ToolBar'                => '0.09';
requires 'Tk::StatusBar'              => '0.04';
requires 'Tk::MListbox'               => '1.11';
requires 'Tk::JComboBox'              => '1.14';
requires 'Tk::DateEntry'              => '1.39';
requires 'Tk::TableMatrix'            => '1.23';
requires 'Tk::RadiobuttonGroup'       => '0.2.2';

#requires 'Template'                   => '2.22';

build_requires 'Test::More'           => '0.47';

install_share  'share';
#install_script 'bin/tpda-mvc';

WriteAll;