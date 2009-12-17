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
use Gtk2::Ex::TreeViewBits;

use Test::More tests => 7;

SKIP: { eval 'use Test::NoWarnings; 1'
          or skip 'Test::NoWarnings not available', 1; }

my $want_version = 14;
cmp_ok ($Gtk2::Ex::TreeViewBits::VERSION, '>=', $want_version,
        'VERSION variable');
cmp_ok (Gtk2::Ex::TreeViewBits->VERSION,  '>=', $want_version,
        'VERSION class method');
ok (eval { Gtk2::Ex::TreeViewBits->VERSION($want_version); 1 },
    "VERSION class check $want_version");
{ my $check_version = $want_version + 1000;
  ok (! eval { Gtk2::Ex::TreeViewBits->VERSION($check_version); 1 },
      "VERSION class check $check_version");
}

#-----------------------------------------------------------------------------

require Gtk2;
my $model = Gtk2::ListStore->new ('Glib::String');
$model->set ($model->append, 0 => 'zero');
$model->set ($model->append, 0 => 'one');
$model->set ($model->append, 0 => 'two');
$model->set ($model->append, 0 => 'three');

my $treeview = Gtk2::TreeView->new ($model);

Gtk2::Ex::TreeViewBits::remove_selected_rows ($treeview);
require Gtk2::Ex::TreeModelBits;
is_deeply ([ Gtk2::Ex::TreeModelBits::column_contents($model,0) ],
           [ 'zero', 'one', 'two', 'three' ],
           'remove_selected_rows() not removing anything');

my $selection = $treeview->get_selection;
$selection->set_mode ('multiple');
$selection->select_path (Gtk2::TreePath->new("1"));
$selection->select_path (Gtk2::TreePath->new("3"));
diag "selected paths ",
  join(' ', map {$_->to_string} $selection->get_selected_rows);

Gtk2::Ex::TreeViewBits::remove_selected_rows ($treeview);
require Gtk2::Ex::TreeModelBits;
is_deeply ([ Gtk2::Ex::TreeModelBits::column_contents($model,0) ],
           [ 'zero', 'two' ],
           'remove_selected_rows() removed two');

exit 0;
