#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010, 2011 Kevin Ryde

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

use 5.008;
use strict;
use warnings;
use Test::More tests => 17;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

require Gtk2::Ex::WidgetBits;

{
  my $want_version = 36;
  is ($Gtk2::Ex::WidgetBits::VERSION, $want_version, 'VERSION variable');
  is (Gtk2::Ex::WidgetBits->VERSION,  $want_version, 'VERSION class method');
  ok (eval { Gtk2::Ex::WidgetBits->VERSION($want_version); 1 },
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Gtk2::Ex::WidgetBits->VERSION($check_version); 1 },
      "VERSION class check $check_version");
}


require Gtk2;
MyTestHelpers::glib_gtk_versions();


#-----------------------------------------------------------------------------

SKIP: {
  Gtk2->disable_setlocale;  # leave LC_NUMERIC alone for version nums
  if (! Gtk2->init_check) { skip 'due to no DISPLAY available', 13; }

  # get_root_position()
  #
  {
    # use 'popup' to stop any window manager moving
    my $toplevel = Gtk2::Window->new('popup');
    $toplevel->set_size_request (100, 100);
    is_deeply ([ Gtk2::Ex::WidgetBits::get_root_position ($toplevel) ],
               [], 'get_root_position() on unrealized');

    $toplevel->show_all;
    MyTestHelpers::wait_for_event ($toplevel, 'map-event');
    {
      my @top_xy = Gtk2::Ex::WidgetBits::get_root_position ($toplevel);
      diag ("toplevel at $top_xy[0], $top_xy[1]");
      is (scalar @top_xy, 2, 'get_root_position() on realized, num retvals');
    }

    my $layout = Gtk2::Layout->new;
    $layout->set_size_request (50, 50);
    $layout->show;
    $toplevel->add ($layout);
    MyTestHelpers::wait_for_event ($layout, 'size-allocate');
    { my ($x, $y) = $layout->window->get_position;
      diag ("layout win relative position $x,$y");
    }
    {
      my @top_xy = Gtk2::Ex::WidgetBits::get_root_position ($toplevel);
      diag ("toplevel at $top_xy[0], $top_xy[1]");
      my @layout_xy = Gtk2::Ex::WidgetBits::get_root_position ($layout);
      diag ("layout   at $layout_xy[0], $layout_xy[1]");
      is (scalar @layout_xy, 2,
          'get_root_position() on contained layout, num retvals');
      is_deeply (\@layout_xy, \@top_xy,
                 'get_root_position() contained layout, same as toplevel');
    }

    my $label = Gtk2::Label->new ('x');
    $layout->put ($label, 20, 30);
    $toplevel->show_all;
    MyTestHelpers::main_iterations();
    {
      my @top_xy = Gtk2::Ex::WidgetBits::get_root_position ($toplevel);
      diag ("toplevel at $top_xy[0], $top_xy[1]");
      my @label_xy = Gtk2::Ex::WidgetBits::get_root_position ($label);
      diag ("label   at $label_xy[0], $label_xy[1]");
      is (scalar @label_xy, 2,
          'get_root_position() on label in layout, num retvals');
      is_deeply ([ Gtk2::Ex::WidgetBits::get_root_position ($label) ],
                 [ $top_xy[0] + 20, $top_xy[1] + 30 ],
                 'get_root_position() on label in layout, at toplevel+offset');
    }

    $toplevel->destroy;
  }

  # warp_pointer()
  #
 SKIP: {
    Gtk2::Gdk::Display->can('warp_pointer')
        or skip 'no display->warp_pointer(), per Gtk before 2.8', 3;

    my $toplevel = Gtk2::Window->new('toplevel');
    ok (! eval { Gtk2::Ex::WidgetBits::warp_pointer ($toplevel, 10, 20); 1 });
    like ($@, qr/Cannot warp on unrealized/);

    $toplevel->show_all;

    MyTestHelpers::wait_for_event ($toplevel, 'map-event');
    my @old = $toplevel->get_pointer;
    Gtk2::Ex::WidgetBits::warp_pointer ($toplevel, @old);
    my @new = $toplevel->get_pointer;
    is_deeply (\@new, \@old, 'warp_pointer() not moved');

    $toplevel->destroy;
  }

  # xy_distance_mm()
  #
  {
    my $label = Gtk2::Label->new ('foo');
    if ($label->can('get_screen')) {
      ok (!eval{ Gtk2::Ex::WidgetBits::xy_distance_mm($label, 10,10, 20,20);
                 1},
          'xy_distance_mm() error when not on a screen');
      like ($@, qr/not on a screen/);
    } else {
      ok (eval{ Gtk2::Ex::WidgetBits::xy_distance_mm($label, 10,10, 20,20);
                1},
          'xy_distance_mm() on Gtk 2.0.x single-screen');
      ok (1);
    }
  }
  {
    my $toplevel = Gtk2::Window->new('toplevel');
    is (Gtk2::Ex::WidgetBits::xy_distance_mm ($toplevel, 0,0, 0,0),
        0,
        'xy_distance_mm() zero');
    is (Gtk2::Ex::WidgetBits::xy_distance_mm ($toplevel, 10,10, 10,10),
        0,
        'xy_distance_mm() zero at 10');

    $toplevel->destroy;
  }

}

exit 0;
