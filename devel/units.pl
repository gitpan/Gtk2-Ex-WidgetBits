#!/usr/bin/perl

# Copyright 2009 Kevin Ryde

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

use5.010;
use strict;
use warnings;
use Gtk2 '-init';
use Gtk2::Ex::Units;

my $toplevel = Gtk2::Window->new;
my $area = Gtk2::DrawingArea->new;
$toplevel->add ($area);

my $layout = $area->create_pango_layout ('');
my $context  = $layout->get_context;
my $fontdesc = ($layout->get_font_description
                || $context->get_font_description);
print "fontdesc '",$fontdesc->to_string,"'\n";
my $lang = $context->get_language;
print "lang '",$lang->to_string,"'\n";

say "ex   ", Gtk2::Ex::Units::height($area, '1 ex');
say "line ", Gtk2::Ex::Units::height($area, '1 line');
say "em   ", Gtk2::Ex::Units::width ($area, '1 em');
say "emh  ", Gtk2::Ex::Units::height($area, '1 em');
say "sw   ", Gtk2::Ex::Units::width($area, '1 screen');
say "sh   ", Gtk2::Ex::Units::height($area, '1 screen');
say "dw   ", Gtk2::Ex::Units::width($area, '1 digit');
say "mmw  ", Gtk2::Ex::Units::width ($area, '1mm');
say "mmh  ", Gtk2::Ex::Units::height($area, '1mm');
say "inw  ", Gtk2::Ex::Units::width ($area, '1inch');
say "inh  ", Gtk2::Ex::Units::height($area, '1inch');
say "mmw  ", Gtk2::Ex::Units::_mm_width ($area);
say "mmh  ", Gtk2::Ex::Units::_mm_height($area);
say "inw  ", Gtk2::Ex::Units::_inch_width ($area);
say "inh  ", Gtk2::Ex::Units::_inch_height($area);

my $rect = Gtk2::Ex::Units::_pango_ink_rect($area,'abc');
say "abc  $rect->{'width'} x $rect->{'width'}";

$area->set_size_request (Gtk2::Ex::Units::width ($area, '100 mm'),
                         Gtk2::Ex::Units::height($area, '100 mm'));
$toplevel->show_all;
Gtk2->main;

exit 0;
