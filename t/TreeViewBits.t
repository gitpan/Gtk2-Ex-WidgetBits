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

use Test::More tests => 4;

my $want_version = 9;
ok ($Gtk2::Ex::TreeViewBits::VERSION >= $want_version,
    'VERSION variable');
ok (Gtk2::Ex::TreeViewBits->VERSION  >= $want_version,
    'VERSION class method');
ok (eval { Gtk2::Ex::TreeViewBits->VERSION($want_version); 1 },
    "VERSION class check $want_version");
{ my $check_version = $want_version + 1000;
  ok (! eval { Gtk2::Ex::TreeViewBits->VERSION($check_version); 1 },
      "VERSION class check $check_version");
}

exit 0;
