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
use Test::More tests => 12;

use lib 't';
use MyTestHelpers;
MyTestHelpers::nowarnings();

require Gtk2::Ex::EntryBits;

{
  my $want_version = 22;
  is ($Gtk2::Ex::EntryBits::VERSION, $want_version, 'VERSION variable');
  is (Gtk2::Ex::EntryBits->VERSION,  $want_version, 'VERSION class method');
  ok (eval { Gtk2::Ex::EntryBits->VERSION($want_version); 1 },
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Gtk2::Ex::EntryBits->VERSION($check_version); 1 },
      "VERSION class check $check_version");
}

require Gtk2;
Gtk2->disable_setlocale;  # leave LC_NUMERIC alone for version nums
my $have_display = Gtk2->init_check;
MyTestHelpers::glib_gtk_versions();

#-----------------------------------------------------------------------------

SKIP: {
  $have_display or skip 'due to no DISPLAY available', 5;

  my $toplevel = Gtk2::Window->new;
  my $entry = Gtk2::Entry->new;
  $toplevel->add ($entry);
  my $atom = Gtk2::Gdk::Atom->new ('PRIMARY');
  my $clipboard = Gtk2::Clipboard->get_for_display ($entry->get_display,$atom);
  diag $entry->flags;

  Gtk2::Ex::EntryBits::select_region_noclip ($entry, 0, 1);
  ok (! $entry->realized, 'realized - still unrealized');
  isnt ($clipboard->get_owner, $entry, 'unrealized - clipboard owner');

  $entry->realize;
  ok ($entry->realized, 'realized - now realized');
  Gtk2::Ex::EntryBits::select_region_noclip ($entry, 1, 2);
  ok ($entry->realized, 'realized - still realized');
  isnt ($clipboard->get_owner, $entry, 'realized - clipboard owner');
}


#-----------------------------------------------------------------------------
# on a DrawingArea

SKIP: {
  $have_display or skip 'due to no DISPLAY available', 3;

  my $toplevel = Gtk2::Window->new;
  my $drawingarea = Gtk2::DrawingArea->new;
  $toplevel->add ($drawingarea);
  diag $drawingarea->flags;

  eval { Gtk2::Ex::EntryBits::select_region_noclip ($drawingarea, 0, 1) };
  ok (! $drawingarea->realized, 'drawingarea - still unrealized');

  $drawingarea->realize;
  ok ($drawingarea->realized, 'drawingarea - now realized');
  eval { Gtk2::Ex::EntryBits::select_region_noclip ($drawingarea, 1, 2) };
  ok ($drawingarea->realized, 'drawingarea - preserved realized on error');
}


exit 0;
