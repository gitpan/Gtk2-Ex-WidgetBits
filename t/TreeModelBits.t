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
use Gtk2::Ex::TreeModelBits;

use Test::More tests => 13;

ok ($Gtk2::Ex::TreeModelBits::VERSION >= 6);
ok (Gtk2::Ex::TreeModelBits->VERSION  >= 6);


#------------------------------------------------------------------------------
# column_contents

{
  my $store = Gtk2::ListStore->new ('Glib::String', 'Glib::Int');
  is_deeply ([ Gtk2::Ex::TreeModelBits::column_contents ($store, 1) ],
             [],
             'column_contents empty');
  $store->insert_with_values (0, 0=>'one', 1=>100);
  is_deeply ([ Gtk2::Ex::TreeModelBits::column_contents ($store, 1) ],
             [ 100 ],
             'column_contents 1');
  $store->insert_with_values (1, 0=>'two', 1=>200);
  is_deeply ([ Gtk2::Ex::TreeModelBits::column_contents ($store, 0) ],
             [ 'one', 'two' ],
             'column_contents 2 text');
  is_deeply ([ Gtk2::Ex::TreeModelBits::column_contents ($store, 1) ],
             [ 100, 200 ],
             'column_contents 2 numbers');
}

#------------------------------------------------------------------------------
# remove_matching_rows

{
  my $store = Gtk2::ListStore->new ('Glib::String');
  Gtk2::Ex::TreeModelBits::remove_matching_rows ($store, sub { return 1; });
  is ($store->iter_n_children(undef), 0);
}
{
  my $store = Gtk2::ListStore->new ('Glib::String');
  $store->insert_with_values (0, 0=>'one');
  Gtk2::Ex::TreeModelBits::remove_matching_rows ($store, sub { return 1; });
  is ($store->iter_n_children(undef), 0);
}
{
  my $store = Gtk2::ListStore->new ('Glib::String');
  $store->insert_with_values (0, 0=>'one');
  $store->insert_with_values (1, 0=>'two');
  Gtk2::Ex::TreeModelBits::remove_matching_rows ($store, sub { return 1; });
  is ($store->iter_n_children(undef), 0);
}
{
  my $store = Gtk2::ListStore->new ('Glib::String');
  $store->insert_with_values (0, 0=>'one');
  $store->insert_with_values (1, 0=>'two');
  Gtk2::Ex::TreeModelBits::remove_matching_rows
      ($store, sub { my ($store, $iter) = @_;
                     my $value = $store->get_value ($iter, 0);
                     return ($value eq 'one'); });
  is ($store->iter_n_children(undef), 1);
}
{
  my $store = Gtk2::ListStore->new ('Glib::String');
  $store->insert_with_values (0, 0=>'one');
  $store->insert_with_values (1, 0=>'two');
  Gtk2::Ex::TreeModelBits::remove_matching_rows
      ($store, sub { my ($store, $iter) = @_;
                     my $value = $store->get_value ($iter, 0);
                     return ($value eq 'two'); });
  is ($store->iter_n_children(undef), 1);
}

sub tree_insert {
  my ($treestore, $indices, $value) = @_;
  my $path = Gtk2::TreePath->new_from_indices (@$indices);
  $path->up;
  my $pos = $indices->[-1];
  my $iter = ($path->get_depth == 0 ? undef : $treestore->get_iter ($path));
  $treestore->insert_with_values ($iter, $pos, 0 => $value);
}

{
  my $store = Gtk2::TreeStore->new ('Glib::String');
  tree_insert ($store, [0], 'one');
  tree_insert ($store, [0,0], 'one-one');
  tree_insert ($store, [1], 'two');
  tree_insert ($store, [1,0], 'two-one');
  tree_insert ($store, [2], 'three');
  Gtk2::Ex::TreeModelBits::remove_matching_rows
      ($store, sub { my ($store, $iter) = @_;
                     my $value = $store->get_value ($iter, 0);
                     return ($value eq 'two'); });
  is_deeply ([ Gtk2::Ex::TreeModelBits::column_contents($store,0) ],
             [ 'one', 'one-one', 'three' ]);
}

#------------------------------------------------------------------------------
# all_column_types

{
  my $store = Gtk2::ListStore->new ('Glib::String', 'Glib::Int');
  is_deeply ([ Gtk2::Ex::TreeModelBits::all_column_types ($store) ],
             [ 'Glib::String', 'Glib::Int' ],
             'all_column_types');
}

exit 0;
