#!/usr/bin/perl

# Copyright 2010 Kevin Ryde

# This file is part of Gtk2-Ex-WidgetBits.
#
# Gtk2-Ex-WidgetBits is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Gtk2-Ex-WidgetBits is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-WidgetBits.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;
use Test::More tests => 8;

BEGIN {
 SKIP: { eval 'use Test::NoWarnings; 1'
           or skip 'Test::NoWarnings not available', 1; }
}

use FindBin;
use File::Spec;
use lib File::Spec->catdir($FindBin::Bin,'inc');
use MyTestHelpers;

require Gtk2::Ex::MenuBits;
{
  my $want_version = 17;
  is ($Gtk2::Ex::MenuBits::VERSION, $want_version,
      'VERSION variable');
  is (Gtk2::Ex::MenuBits->VERSION,  $want_version,
      'VERSION class method');
  ok (eval { Gtk2::Ex::MenuBits->VERSION($want_version); 1 },
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Gtk2::Ex::MenuBits->VERSION($check_version); 1 },
      "VERSION class check $check_version");
}

require Gtk2;
Gtk2->disable_setlocale;  # leave LC_NUMERIC alone for version nums
my $have_display = Gtk2->init_check;

SKIP: {
  $have_display or skip 'due to no DISPLAY available', 3;

  my $menu = Gtk2::Menu->new;
  my $widget = Gtk2::Label->new;
  $widget->show;
  is_deeply ([ Gtk2::Ex::MenuBits::position_widget_topcentre
               ($menu, -12345, -6789, $widget) ],
             [ -12345, -6789, 1 ],
             'not in a toplevel');

  my $toplevel = Gtk2::Window->new('toplevel');
  $toplevel->add ($widget);
  is_deeply ([ Gtk2::Ex::MenuBits::position_widget_topcentre
               ($menu, -12345, -6789, $widget) ],
             [ -12345, -6789, 1 ],
             'not realized');

  $toplevel->show_all;
  # MyTestHelpers::main_iterations();
  # diag $toplevel->window;
  # diag $widget->window;
  my ($x,$y,$push_in) = Gtk2::Ex::MenuBits::position_widget_topcentre
    ($menu, -123456, -654321, $widget);
  isnt ($x, -123456,
        'with show_all()');

  $toplevel->destroy;
}

exit 0;
