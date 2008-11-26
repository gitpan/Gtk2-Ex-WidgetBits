#!/usr/bin/perl

# Copyright 2008 Kevin Ryde

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
use Gtk2::Ex::WidgetBits;
use Test::More tests => 13;

ok ($Gtk2::Ex::WidgetBits::VERSION >= 6);
ok (Gtk2::Ex::WidgetBits->VERSION  >= 6);

sub main_iterations {
  my $count = 0;
  while (Gtk2->events_pending) {
    $count++;
    Gtk2->main_iteration_do (0);
  }
  print "main_iterations(): ran $count events/iterations\n";
}

SKIP: {
  require Gtk2;
  if (! Gtk2->init_check) { skip 'due to no DISPLAY available', 11; }

  # get_root_position()
  #
  {
    # use popup to stop any window manager moving
    my $toplevel = Gtk2::Window->new('popup');
    is_deeply ([ Gtk2::Ex::WidgetBits::get_root_position ($toplevel) ],
               [], 'get_root_position() on unrealized');

    $toplevel->show_all;
    main_iterations();
    my @top_xy = Gtk2::Ex::WidgetBits::get_root_position ($toplevel);
    is (scalar @top_xy, 2, 'get_root_position() on realized');
    diag ("toplevel at $top_xy[0], $top_xy[1]");

    my $layout = Gtk2::Layout->new;
    $toplevel->add ($layout);
    $toplevel->show_all;
    main_iterations();
    is_deeply ([ Gtk2::Ex::WidgetBits::get_root_position ($layout) ],
               \@top_xy, 'get_root_position() on contained layout');

    my $label = Gtk2::Label->new ('x');
    $layout->put ($label, 20, 30);
    $toplevel->show_all;
    main_iterations();
    is_deeply ([ Gtk2::Ex::WidgetBits::get_root_position ($label) ],
               [ $top_xy[0] + 20, $top_xy[1] + 30 ],
               'get_root_position() on label in layout');

    $toplevel->destroy;
  }

  # wrap_pointer()
  #
  {
    my $toplevel = Gtk2::Window->new('toplevel');
    ok (! eval { Gtk2::Ex::WidgetBits::warp_pointer ($toplevel, 10, 20); 1 });
    like ($@, qr/Cannot warp on unrealized/);

    $toplevel->show_all;
    main_iterations();
    my @old = $toplevel->get_pointer;
    Gtk2::Ex::WidgetBits::warp_pointer ($toplevel, @old);
    my @new = $toplevel->get_pointer;
    is_deeply (\@new, \@old,
               'wrap_pointer() not moved');

    $toplevel->destroy;
  }

  # xy_distance_mm()
  #
  {
    my $label = Gtk2::Label->new ('foo');
    ok (!eval{ Gtk2::Ex::WidgetBits::xy_distance_mm($label, 10,10, 20,20); 1});
    like ($@, qr/not on a screen/);
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
