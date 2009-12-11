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
use Gtk2::Ex::GdkBits;
use Test::More tests => 7;

use FindBin;
use File::Spec;
use lib File::Spec->catdir($FindBin::Bin,'inc');
use MyTestHelpers;

SKIP: { eval 'use Test::NoWarnings; 1'
          or skip 'Test::NoWarnings not available', 1; }

my $want_version = 11;
cmp_ok ($Gtk2::Ex::GdkBits::VERSION, '>=', $want_version,
        'VERSION variable');
cmp_ok (Gtk2::Ex::GdkBits->VERSION,  '>=', $want_version,
        'VERSION class method');
ok (eval { Gtk2::Ex::GdkBits->VERSION($want_version); 1 },
    "VERSION class check $want_version");
{ my $check_version = $want_version + 1000;
  ok (! eval { Gtk2::Ex::GdkBits->VERSION($check_version); 1 },
      "VERSION class check $check_version");
}

require Gtk2;
MyTestHelpers::glib_gtk_versions();

SKIP: {
  require Gtk2;
  Gtk2->disable_setlocale;  # leave LC_NUMERIC alone for version nums
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
