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


package MyNewFilterModel;
use strict;
use warnings;
use Gtk2;
use base 'Gtk2::Ex::TreeModelFilter::Change';
use Glib::Object::Subclass
  'Gtk2::TreeModelFilter';

package MyChildModel;
use strict;
use warnings;
use Gtk2;
use Glib::Object::Subclass
  'Gtk2::ListStore';

my $child_set_called;
sub set {
  my ($self, $iter, @values) = @_;
  $child_set_called++;
  $self->SUPER::set($iter, @values);
}

package main;
use strict;
use warnings;
use Test::More tests => 7;

SKIP: { eval 'use Test::NoWarnings; 1'
          or skip 'Test::NoWarnings not available', 1; }

my $want_version = 12;
cmp_ok ($Gtk2::Ex::TreeModelFilter::Change::VERSION, '>=', $want_version,
        'VERSION variable');
cmp_ok (Gtk2::Ex::TreeModelFilter::Change->VERSION,  '>=', $want_version,
        'VERSION class method');
ok (eval { Gtk2::Ex::TreeModelFilter::Change->VERSION($want_version); 1 },
    "VERSION class check $want_version");
{ my $check_version = $want_version + 1000;
  ok (! eval { Gtk2::Ex::TreeModelFilter::Change->VERSION($check_version); 1 },
      "VERSION class check $check_version");
}

{
  my $child = MyChildModel->new;
  $child->set_column_types ('Glib::String');

  my $filter = MyNewFilterModel->new (child_model => $child);
  my $iter = $filter->append(undef);
  isa_ok ($iter, 'Gtk2::TreeIter');

  $filter->set ($iter, 0, 'foo');
  is ($child_set_called, 1, 'child set() called');
}

exit 0;
