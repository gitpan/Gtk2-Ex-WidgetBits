#!/usr/bin/perl -w

# Copyright 2011 Kevin Ryde

# This file is part of Gtk2-Ex-WidgetBits.
#
# Gtk2-Ex-WidgetBits is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Gtk2-Ex-WidgetBits is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-WidgetBits.  If not, see <http://www.gnu.org/licenses/>.

use 5.008;
use strict;
use warnings;
use Test::More;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

require Gtk2::Ex::ToolItem::OverflowToDialog;

require Gtk2;
Gtk2->disable_setlocale;  # leave LC_NUMERIC alone for version nums
Gtk2->init_check
  or plan skip_all => 'due to no DISPLAY available';

plan tests => 24;

sub force_dialog {
  my ($toolitem) = @_;
  my $menuitem = $toolitem->retrieve_proxy_menu_item;
  $menuitem->activate;
  if (! $toolitem->{'dialog'}) {
    die "Oops, force_dialog() didn't make a dialog";
  } elsif (! $toolitem->{'dialog'}->mapped) {
    die "Oops, force_dialog() didn't map the dialog";
  }
  return $toolitem->{'dialog'};
}

#------------------------------------------------------------------------------
# child property

{
  my $child_widget = Gtk2::Button->new ('XYZ');
  my $toolitem =  Gtk2::Ex::ToolItem::OverflowToDialog->new
    (child => $child_widget);
  is ($toolitem->get_child, $child_widget);
}

#------------------------------------------------------------------------------
# weaken

{
  my $toolitem =  Gtk2::Ex::ToolItem::OverflowToDialog->new;
  Scalar::Util::weaken($toolitem);
  is ($toolitem, undef, 'toolitem weaken away');
}
{
  my $child_widget = Gtk2::Button->new;
  my $toolitem =  Gtk2::Ex::ToolItem::OverflowToDialog->new
    (child_widget => $child_widget);
  Scalar::Util::weaken($toolitem);
  is ($toolitem, undef, 'toolitem weaken away');
}
{
  my $child_widget = Gtk2::Button->new;
  my $toolitem =  Gtk2::Ex::ToolItem::OverflowToDialog->new
    (child_widget => $child_widget);
  my $menuitem = $toolitem->retrieve_proxy_menu_item;
  Scalar::Util::weaken($toolitem);
  Scalar::Util::weaken($menuitem);
  is ($toolitem, undef, 'toolitem with menu weaken away');
  is ($menuitem, undef, 'menuitem weaken away');
}
{
  my $child_widget = Gtk2::Button->new;
  my $toolitem =  Gtk2::Ex::ToolItem::OverflowToDialog->new
    (child_widget => $child_widget);
  my $menuitem = $toolitem->retrieve_proxy_menu_item;
  my $dialog = force_dialog($toolitem);
  Scalar::Util::weaken($toolitem);
  Scalar::Util::weaken($menuitem);
  Scalar::Util::weaken($dialog);
  is ($toolitem, undef, 'toolitem with dialog weaken away');
  is ($menuitem, undef, 'menuitem weaken away');
  is ($dialog, undef, 'dialog weaken away');
}
  # Scalar::Util::weaken($child_widget);
  # is ($child_widget, undef, 'prev child_widget weaken away');


#------------------------------------------------------------------------------
# add()

{
  my $child_widget = Gtk2::Button->new ('XYZ');
  my $toolitem =  Gtk2::Ex::ToolItem::OverflowToDialog->new;
  $toolitem->add ($child_widget);
  is ($toolitem->get_child, $child_widget, 'add() - get_child');
  is ($toolitem->get('child_widget'), $child_widget, 'add() - child_widget');

  force_dialog($toolitem);
  is ($toolitem->get_child, undef,
      'get_child - undef when in dialog');
  is ($toolitem->get('child_widget'), $child_widget,
      'child_widget prop - when in dialog');

  my $new_child_widget = Gtk2::Button->new ('ABC');

  $toolitem->add ($new_child_widget);
  is ($toolitem->get_child, undef,
      'add() while in dialog - get_child');
  is ($toolitem->get('child_widget'), $new_child_widget,
      'add() while in dialog - child_widget');
}

#------------------------------------------------------------------------------
# child-widget property

{
  my $child_widget = Gtk2::Button->new ('XYZ');
  my $toolitem =  Gtk2::Ex::ToolItem::OverflowToDialog->new
    (child_widget => $child_widget);
  is ($toolitem->get_child, $child_widget, 'get_child - initial');
  is ($toolitem->get('child_widget'), $child_widget, 'child_widget - initial');

  $toolitem->set (child_widget => undef);
  is ($toolitem->get_child, undef, 'set undef - get_child');
  is ($toolitem->get('child_widget'), undef, 'set undef - child_widget');
}
{
  my $child_widget = Gtk2::Button->new ('XYZ');
  my $toolitem =  Gtk2::Ex::ToolItem::OverflowToDialog->new;

  $toolitem->set_child_widget ($child_widget);
  is ($toolitem->get_child, $child_widget, 'set_child_widget() - get_child');
  is ($toolitem->get('child_widget'), $child_widget,
      'set_child_widget() - child_widget property');

  force_dialog($toolitem);
  is ($toolitem->get_child, undef,
      'get_child - undef when in dialog');
  is ($toolitem->get('child_widget'), $child_widget,
      'child_widget prop - when in dialog');

  $toolitem->set (child_widget => undef);
  is ($toolitem->get_child, undef,
      'set undef with dialog - get_child');
  is ($toolitem->get('child_widget'), undef,
      'set undef with dialog - child_widget');
}

exit 0;
