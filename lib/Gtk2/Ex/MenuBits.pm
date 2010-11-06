# Copyright 2007, 2008, 2009, 2010 Kevin Ryde

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

package Gtk2::Ex::MenuBits;
use 5.008;
use strict;
use warnings;
use Gtk2;
use List::Util qw(max);

# uncomment this to run the ### lines
#use Smart::Comments;

our $VERSION = 29;

use Exporter;
our @ISA = ('Exporter');
our @EXPORT_OK = qw(position_widget_topcentre);

sub position_widget_topcentre {
  my ($menu, $x, $y, $widget) = @_;
  ### position_widget_topcentre(): "@{[$widget||'undef']}"
  if (ref $widget eq 'REF') { $widget = $$widget; }

  ### widget mapped: $widget && $widget->mapped
  ### widget screen: "@{[$widget && $widget->get_screen]}"
  ### menu   screen: "@{[$menu->get_screen]}"

  if ($widget
      && $widget->get_screen == $menu->get_screen
      && $widget->mapped) {
    ### mapped and same screen

    require Gtk2::Ex::WidgetBits;
    if (my ($wx, $wy) = Gtk2::Ex::WidgetBits::get_root_position($widget)) {
      ### have root x,y: "$wx,$wy"

      my $widget_alloc = $widget->allocation;
      my $menu_req = $menu->requisition;

      $x = $wx + max (0, int (($widget_alloc->width - $menu_req->width) / 2));
      $y = $wy +         int (($widget_alloc->height + 1) / 2);  # round up
    }
  }

  ### $x
  ### $y
  return ($x, $y, 1);  # push_in to be visible on screen
}

1;
__END__

=for stopwords userdata multi-screen iconified toplevel un-iconified Ryde Gtk2 Gtk2-Ex-WidgetBits popup

=head1 NAME

Gtk2::Ex::MenuBits -- miscellaneous Gtk2::Menu helpers

=head1 SYNOPSIS

 use Gtk2::Ex::MenuBits;

=head1 FUNCTIONS

=over 4

=item C<< ($x,$y,$push_in) = Gtk2::Ex::MenuBits::position_widget_topcentre ($menu, $x, $y, $userdata) >>

Position a menu with its top edge centred in a given C<$userdata> widget.
This is good for a menu popped up by a keystroke in a "strip" type widget
which is wide but has only a small height.

    $menu->popup (undef,    # no parent menushell
                  undef,    # no parent menuitem
                  \&Gtk2::Ex::MenuBits::position_widget_topcentre,
                  $widget,  # userdata
                  0,        # no button for keyboard popup
                  $event_time);

C<$userdata> can be either a widget or a reference to a widget.  The latter
can be a weak reference so as to avoid a circular reference between a widget
and a menu within it (C<< $menu->popup >> holds C<$userdata> within the menu
for later C<reposition>).

If C<$userdata> is C<undef> or a ref to C<undef>, or if the widget is not
mapped or is on a different screen than C<$menu>, then the return is the
given C<$x>,C<$y> input parameters.  This is the mouse pointer position if
called straight from C<Gtk2::Menu>.

A multi-screen program should C<set_screen> on the menu to ensure it's the
same as the widget.  This is left to the application because it's probably
not safe within the positioning function, especially not if the positioning
is called from C<set_screen> itself due to moving a popped-up menu to a
different screen.

In the current implementation if the widget is in an iconified toplevel then
the position is based on its un-iconified location.  The intention in the
future is to go to the mouse position fallback in this case, since the
widget is not on-screen.  Of course when iconified a widget won't get
keyboard or button events to cause a menu popup, so in practice this doesn't
arise.

=back

=head1 EXPORTS

Nothing is exported by default, but C<position_widget_topcentre> can be
requested in usual C<Exporter> style,

    use Gtk2::Ex::MenuBits 'position_widget_topcentre';
    $menu->popup (undef, undef,
                  \&position_widget_topcentre, $widget,
                  0, 0);

There's no C<:all> tag since this module is meant as a grab-bag of functions
and to import as-yet unknown things would be asking for name clashes!

=head1 SEE ALSO

L<Gtk2::Menu>, L<Gtk2::Ex::WidgetBits>, L<Exporter>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/gtk2-ex-widgetbits/index.html>

=head1 LICENSE

Copyright 2007, 2008, 2009, 2010 Kevin Ryde

Gtk2-Ex-WidgetBits is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3, or (at your option) any later
version.

Gtk2-Ex-WidgetBits is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Gtk2-Ex-WidgetBits.  If not, see L<http://www.gnu.org/licenses/>.

=cut
