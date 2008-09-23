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
use Gtk2::Ex::GdkBits;
use Test::More tests => 4;

ok ($Gtk2::Ex::GdkBits::VERSION >= 4);
ok (Gtk2::Ex::GdkBits->VERSION  >= 4);

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
  if (! Gtk2->init_check) { skip 'due to no DISPLAY available', 2; }

  {
    my $root = Gtk2::Gdk->get_default_root_window;
    is_deeply ([ Gtk2::Ex::GdkBits::window_get_root_position ($root) ],
               [ 0, 0 ],
               'window_get_root_position() on root window');

    my $win = Gtk2::Gdk::Window->new ($root,
                                      { window_type => 'temp',
                                        x => 200,
                                        y => 100,
                                        width => 20,
                                        height => 10 });
    is_deeply ([ Gtk2::Ex::GdkBits::window_get_root_position ($win) ],
               [ 200, 100 ],
               'window_get_root_position() on temp window');
  }

}

exit 0;
