# Copyright 2008, 2009 Kevin Ryde

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

$toplevel->show_all;

if (1) {
  Gtk2::Ex::SyncCall->next ($toplevel, sub { print "hello\n"; });
  Gtk2::Ex::SyncCall->next ($toplevel, sub { print "world\n"; });
}

if (1) {
  Glib::Timeout->add
      (1000, sub {
         Gtk2::Ex::SyncCall->next ($toplevel, sub { print "one\n"; });
         Gtk2::Ex::SyncCall->next ($toplevel, sub { print "two\n"; });
         return 1;
       });
}

Gtk2->main;
exit 0;
