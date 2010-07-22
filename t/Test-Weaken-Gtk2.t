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
use Test::More tests => 4;

use lib 't';
use MyTestHelpers;
MyTestHelpers::nowarnings();

require Test::Weaken::Gtk2;
{
  my $want_version = 19;
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

exit 0;
