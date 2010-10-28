# Copyright 2007, 2008, 2009, 2010 Kevin Ryde

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

package Gtk2::Ex::WidgetBits;
use 5.008;
use strict;
use warnings;
use Carp;
use Gtk2;

our $VERSION = 27;

# get_root_position() might be done as
#
#     my $toplevel = $widget->get_toplevel;
#     my $window = $toplevel->window || return; # if unrealized
#     return $widget->translate_coordinates ($toplevel,
#                                            $window->get_position);
#
# if it can be assumed the toplevel widget of a hierarchy has its window a
# child of the root window (after possible window manager frame).  Or
# alternately just get_toplevel() could eliminate the 'no-window' test if it
# can be assumed the toplevel is a windowed widget.  All of which is of
# course true of GtkWindow, and probably ends up right for GtkPlug too, but
# could a custom toplevel widget do something tricky?
#
sub get_root_position {
  my ($widget) = @_;
  my $window = $widget->window || return; # if unrealized
  require Gtk2::Ex::GdkBits;
  my ($x, $y) = Gtk2::Ex::GdkBits::window_get_root_position ($window);
  if ($widget->flags & 'no-window') {
    my $alloc = $widget->allocation;
    $x += $alloc->x;
    $y += $alloc->y;
  }
  return ($x, $y);
}
sub warp_pointer {
  my ($widget, $x, $y) = @_;
  my ($origin_x, $origin_y) = get_root_position ($widget)
    or croak "Cannot warp on unrealized $widget";
  my $screen = $widget->get_screen;
  my $display = $widget->get_display;
  $display->warp_pointer ($screen, $origin_x + $x, $origin_y + $y);
}

sub xy_distance_mm {
  my ($widget, $x1, $y1, $x2, $y2) = @_;
  my ($xf, $yf) = _widget_mm_factors ($widget);
  return _hypot ($xf * ($x1 - $x2),
                 $yf * ($y1 - $y2));
}
sub _widget_mm_factors {
  my ($widget) = @_;

  # gtk_widget_get_screen() returns the default screen if the widget is not
  # yet in a toplevel, so test gtk_widget_has_screen() first.  Often just
  # that default screen would be good enough, but best not to be sloppy with
  # that sort of thing if potentially multi-display.
  #
  $widget->has_screen or croak 'widget not on a screen yet';
  my $screen = $widget->get_screen;

  # Pointless in Gtk 2.14, the monitor sizes are always -1 ...
  #
  # For a multi-monitor screen an individual monitor size is used if
  # available.  Currently the calculation only looks at a single monitor
  # containing or nearest to the widget, using C<get_monitor_at_window>.  No
  # attempt is made to tell if the line x1,y1 to x2,y2 crosses multiple
  # monitors.
  #
  #   # xinerama new in Gtk 2.14 (2008) and Gtk2-Perl 1.191 (Aug 2008)
  #   if (my $func = $screen->can('get_monitor_at_window')) {
  #     # no position on the screen until realized
  #     if (my $win = $widget->window) {
  #       my $mnum = $func->($screen, $win);
  #       my $rect = $screen->get_monitor_geometry ($mnum);
  #       my $width_mm = $screen->get_monitor_width_mm ($mnum);
  #       my $height_mm = $screen->get_monitor_height_mm ($mnum);
  #       # sizes -1 if not known
  #       if ($width_mm != -1 && $height_mm != -1) {
  #         return ($width_mm / $rect->width,
  #                 $height_mm / $rect->height);
  #       }
  #     }
  #   }

  return ($screen->get_width_mm / $screen->get_width,
          $screen->get_height_mm / $screen->get_height);
}
sub _hypot {
  my ($x, $y) = @_;
  return sqrt ($x ** 2 + $y ** 2);
}

1;
__END__

=for stopwords Gdk ie eg toplevel Ryde Gtk2-Ex-WidgetBits Gtk2 Gtk

=head1 NAME

Gtk2::Ex::WidgetBits - miscellaneous Gtk widget helpers

=head1 SYNOPSIS

 use Gtk2::Ex::WidgetBits;

=head1 FUNCTIONS

=over 4

=item C<($x,$y) = Gtk2::Ex::WidgetBits::get_root_position ($widget)>

Return the position of the top left corner of C<$widget> in root window
coordinates.  If C<$widget> is unrealized the return is an empty list C<()>.

This uses C<< Gtk2::Ex::GdkBits::window_get_root_position >> so takes the
most recently recorded window positions rather than making an X server
round-trip.

=item C<< Gtk2::Ex::WidgetBits::warp_pointer ($widget, $x, $y) >>

Warp, ie. forcibly move, the mouse pointer to C<$x>,C<$y> in C<$widget>
coordinates (ie. relative to the widget's top-left corner).  C<$widget> must
be realized, since otherwise it doesn't have a screen position.

See L<Gtk2::Gdk::Display> for the basic C<warp_pointer> which operates in
root window coordinates.  The code here converts using C<get_root_position>
above, so there's no server round-trip.

(The underlying C<XWarpPointer> operates relative to any window, not just
the root, but Gdk doesn't make that feature available.)

=item C<< $mm = Gtk2::Ex::WidgetBits::xy_distance_mm ($widget, $x1,$y1, $x2,$y2) >>

Return the distance in millimetres between pixel points C<$x1>,C<$y1> and
C<$x2>,C<$y2> in C<$widget>.

Pixels are converted to millimetres using the screen size from
C<Gtk2::Gdk::Screen>.  C<$widget> must have been added into a toplevel
widget hierarchy (eg. C<Gtk2::Window>), since the toplevel widget determines
the screen.

=back

=head1 SEE ALSO

L<Gtk2::Ex::EntryBits>,
L<Gtk2::Ex::GdkBits>,
L<Gtk2::Ex::MenuBits>,
L<Gtk2::Ex::TextBufferBits>,
L<Gtk2::Ex::TreeModelBits>,
L<Gtk2::Ex::TreeModel::ImplBits>,
L<Gtk2::Ex::TreeViewBits>,
L<Gtk2::Ex::Units>

L<Gtk2::Ex::ActionTooltips>,
L<Gtk2::Ex::KeySnooper>,
L<Gtk2::Ex::SyncCall>,
L<Gtk2::Ex::Statusbar::MessageUntilKey>,
L<Gtk2::Ex::TreeModelFilter::Change>,
L<Test::Weaken::Gtk2>

L<Gtk2::Widget>, L<Gtk2::Ex::WidgetCursor>.

=head1 HOME PAGE

L<http://user42.tuxfamily.org/gtk2-ex-widgetbits/index.html>

=head1 LICENSE

Copyright 2008, 2009, 2010 Kevin Ryde

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
