#!/usr/bin/perl -w

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
use Gtk2 '-init';

# uncomment this to run the ### lines
use Smart::Comments;

{
  require Test::Weaken;
  print Test::Weaken->VERSION,"\n";
  require Test::Weaken::Gtk2;

  # cellview doesn't like get_cells without set_display_row, or something
  my $cellview = Gtk2::CellView->new;
  my $renderer = Gtk2::CellRendererText->new;

  my @cells = Test::Weaken::Gtk2::contents_cell_renderers($cellview);
  ### @cells;

  $cellview->pack_start ($renderer, 0);

  @cells = Test::Weaken::Gtk2::contents_cell_renderers($cellview);
  ### @cells;

  exit 0;
}
