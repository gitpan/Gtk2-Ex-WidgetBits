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
use Gtk2::Ex::Statusbar::MessageUntilKey;

use FindBin;
use File::Spec;
use lib File::Spec->catdir($FindBin::Bin,'inc');
use MyTestHelpers;

use Test::More tests => 8;

SKIP: { eval 'use Test::NoWarnings; 1'
          or skip 'Test::NoWarnings not available', 1; }

my $want_version = 1;
cmp_ok ($Gtk2::Ex::Statusbar::MessageUntilKey::VERSION, '>=', $want_version, 'VERSION variable');
cmp_ok (Gtk2::Ex::Statusbar::MessageUntilKey->VERSION,  '>=', $want_version, 'VERSION class method');
{ ok (eval { Gtk2::Ex::Statusbar::MessageUntilKey->VERSION($want_version); 1 },
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Gtk2::Ex::Statusbar::MessageUntilKey->VERSION($check_version); 1 }, "VERSION class check $check_version");
}

require Gtk2;
Gtk2->disable_setlocale;  # leave LC_NUMERIC alone for version nums
my $have_display = Gtk2->init_check;

SKIP: {
  $have_display or skip 'due to no DISPLAY available', 3;

  my $statusbar = Gtk2::Statusbar->new;
  my $pushed = 0;
  my $popped = 0;
  $statusbar->signal_connect
    (text_pushed => sub {
       my ($statusbar, $context_id, $text) = @_;
       # diag "push: ",(defined $text ? $text : 'undef');
       $pushed++ });
  $statusbar->signal_connect
    (text_popped => sub {
       my ($statusbar, $context_id, $text) = @_;
       # diag "pop: ",(defined $text ? $text : 'undef');
       $popped++;
     });

  Gtk2::Ex::Statusbar::MessageUntilKey->message($statusbar, 'hello');
  is ($pushed, 1, 'text-pushed emitted');

  $popped = 0;
  Gtk2::Ex::Statusbar::MessageUntilKey->remove($statusbar);
  is ($popped, 1, 'text-popped emitted');

  is_deeply ($statusbar, {}, 'no fields left on statusbar');
}

exit 0;
