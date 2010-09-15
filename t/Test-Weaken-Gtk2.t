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
use Test::More tests => 17;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

require Test::Weaken::Gtk2;
{
  my $want_version = 24;
  is ($Test::Weaken::Gtk2::VERSION, $want_version,
      'VERSION variable');
  is (Test::Weaken::Gtk2->VERSION,  $want_version,
      'VERSION class method');
  ok (eval { Test::Weaken::Gtk2->VERSION($want_version); 1 },
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Test::Weaken::Gtk2->VERSION($check_version); 1 },
      "VERSION class check $check_version");
}

require Gtk2;

#------------------------------------------------------------------------------
# contents_submenu()

is_deeply ([], [Test::Weaken::Gtk2::contents_submenu ([])],
           'contents_cell_submenu() on arrayref');

eval "use Test::Weaken::Gtk2 'contents_submenu'";
{
  my $item = Gtk2::MenuItem->new;
  is_deeply ([], [Test::Weaken::Gtk2::contents_submenu ($item)],
             'contents_submenu() MenuItem empty');

  is_deeply ([], [contents_submenu ($item)],
             'contents_submenu() MenuItem empty, import');
}

#------------------------------------------------------------------------------
# contents_cell_renderers()

is_deeply ([], [Test::Weaken::Gtk2::contents_cell_renderers ([])],
           'contents_cell_renderers() on arrayref');

eval "use Test::Weaken::Gtk2 'contents_cell_renderers'";
{
  my $column = Gtk2::TreeViewColumn->new;
  is_deeply ([], [Test::Weaken::Gtk2::contents_cell_renderers ($column)],
             'contents_cell_renderers() TreeViewColumn empty');

  my $renderer = Gtk2::CellRendererText->new;
  $column->pack_start ($renderer, 1);
  is_deeply ([$renderer],
             [contents_cell_renderers ($column)],
             'contents_cell_renderers() TreeViewColumn one');

  my $renderer2 = Gtk2::CellRendererText->new;
  $column->pack_start ($renderer2, 1);
  is_deeply ([$renderer, $renderer2],
             [contents_cell_renderers ($column)],
             'contents_cell_renderers() TreeViewColumn two');
}

{
  my $cellview = Gtk2::CellView->new;
  is_deeply ([], [contents_cell_renderers ($cellview)],
             'contents_cell_renderers() CellView empty');

  my $model = Gtk2::ListStore->new ('Glib::String');
  $cellview->set_model ($model);
  is_deeply ([], [contents_cell_renderers ($cellview)],
             'contents_cell_renderers() CellView with empty model');

  $model->append;
  is_deeply ([], [contents_cell_renderers ($cellview)],
             'contents_cell_renderers() CellView with non-empty model but no display row');

  my $path = Gtk2::TreePath->new (0);
  $cellview->set_displayed_row ($path);
  is_deeply ([], [contents_cell_renderers ($cellview)],
             'contents_cell_renderers() CellView with display row');

  my $renderer = Gtk2::CellRendererText->new;
  $cellview->pack_start ($renderer, 1);
  is_deeply ([$renderer],
             [contents_cell_renderers ($cellview)],
             'contents_cell_renderers() CellView one');

  my $renderer2 = Gtk2::CellRendererText->new;
  $cellview->pack_start ($renderer2, 1);
  is_deeply ([$renderer, $renderer2],
             [contents_cell_renderers ($cellview)],
             'contents_cell_renderers() CellView two');
}

exit 0;
