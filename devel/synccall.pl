#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010 Kevin Ryde

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
use Gtk2 '-init';
use Gtk2::Ex::SyncCall;

my $toplevel = Gtk2::Window->new('toplevel');

my $drawingarea = Gtk2::DrawingArea->new;
$drawingarea->set_size_request (100, 100);
$toplevel->add($drawingarea);

$toplevel->show_all;
my $widget = $drawingarea;

if (1) {
  print "initial\n";
  Gtk2::Ex::SyncCall->sync ($widget, sub { print "hello\n"; });
  Gtk2::Ex::SyncCall->sync ($widget, sub { print "world\n"; });
}

if (1) {
  Glib::Timeout->add
      (3000, sub {
         print "another\n";
         Gtk2::Ex::SyncCall->sync ($widget, sub { print "one\n"; });
         Gtk2::Ex::SyncCall->sync ($widget, sub { print "two\n"; });
         return 1;
       });
}

Gtk2->main;
exit 0;
