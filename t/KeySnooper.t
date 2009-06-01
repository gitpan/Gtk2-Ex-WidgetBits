#!/usr/bin/perl

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
use Gtk2::Ex::KeySnooper;
use Test::More tests => 11;

my $want_version = 10;
cmp_ok ($Gtk2::Ex::KeySnooper::VERSION, '>=', $want_version,
        'VERSION variable');
cmp_ok (Gtk2::Ex::KeySnooper->VERSION,  '>=', $want_version,
        'VERSION class method');
ok (eval { Gtk2::Ex::KeySnooper->VERSION($want_version); 1 },
    "VERSION check $want_version");
{ my $check_version = $want_version + 1000;
  ok (! eval { Gtk2::Ex::KeySnooper->VERSION($check_version); 1 },
      "VERSION class check $check_version");
}

require Gtk2;
diag ("Perl-Gtk2 version ",Gtk2->VERSION);
diag ("Perl-Glib version ",Glib->VERSION);
diag ("Compiled against Glib version ",
      Glib::MAJOR_VERSION(), ".",
      Glib::MINOR_VERSION(), ".",
      Glib::MICRO_VERSION(), ".");
diag ("Running on       Glib version ",
      Glib::major_version(), ".",
      Glib::minor_version(), ".",
      Glib::micro_version(), ".");
diag ("Compiled against Gtk version ",
      Gtk2::MAJOR_VERSION(), ".",
      Gtk2::MINOR_VERSION(), ".",
      Gtk2::MICRO_VERSION(), ".");
diag ("Running on       Gtk version ",
      Gtk2::major_version(), ".",
      Gtk2::minor_version(), ".",
      Gtk2::micro_version(), ".");

SKIP: {
  Gtk2->disable_setlocale;  # leave LC_NUMERIC alone for version nums
  if (! Gtk2->init_check) { skip 'due to no DISPLAY available', 7; }

  {
    my $toplevel = Gtk2::Window->new('toplevel');
    $toplevel->realize;
    my $called = 0;
    my $snooper = Gtk2::Ex::KeySnooper->new (sub { $called++;
                                                   return 0; # propagate
                                                 });
    is ($called, 0);

    my $event = Gtk2::Gdk::Event::Key->new ('key-press');
    $event->window ($toplevel->window);

    Gtk2->main_do_event ($event);
    is ($called, 1, 'snooper called');

    require Scalar::Util;
    Scalar::Util::weaken ($snooper);
    is ($snooper, undef, 'garbage collected when weakened');

    Gtk2->main_do_event ($event);
    is ($called, 1, 'no call after destroy');

    $toplevel->destroy;
  }

  {
    my $toplevel = Gtk2::Window->new('toplevel');
    $toplevel->realize;
    my $called = 0;
    my $snooper = Gtk2::Ex::KeySnooper->new (sub { $called++;
                                                   return 0; # propagate
                                                 });
    my $event = Gtk2::Gdk::Event::Key->new ('key-press');
    $event->window ($toplevel->window);

    Gtk2->main_do_event ($event);
    is ($called, 1, 'snooper called');

    $snooper->remove;
    Gtk2->main_do_event ($event);
    is ($called, 1, 'no call after remove()');

    $toplevel->destroy;
  }

  {
    my $toplevel = Gtk2::Window->new('toplevel');
    $toplevel->realize;
    my $called_A = 0;
    my $called_B = 0;
    my $snooper_A = Gtk2::Ex::KeySnooper->new (sub { $called_A++;
                                                     return 1; # stop
                                                   });
    my $snooper_B = Gtk2::Ex::KeySnooper->new (sub { $called_B++;
                                                     return 1; # stop
                                                   });
    my $event = Gtk2::Gdk::Event::Key->new ('key-press');
    $event->window ($toplevel->window);

    # latest installed snooper gets priority, which is probably a feature,
    # but not actually documented, so don't depend on which of A or B it is
    # that runs
    Gtk2->main_do_event ($event);
    is ($called_A + $called_B, 1, 'one snooper returns "stop"');

    $toplevel->destroy;
  }
}

exit 0;
