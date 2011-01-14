# Copyright 2007, 2008, 2009, 2010, 2011 Kevin Ryde

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

package Gtk2::Ex::GdkBits;
use 5.008;
use strict;
use warnings;
use Carp;
use Gtk2;

use Exporter;
our @ISA = ('Exporter');
our @EXPORT_OK = qw(window_get_root_position
                    window_clear_region);

our $VERSION = 35;


# The loop here is similar to what gtk_widget_translate_coordinates() does
# chasing up through window ancestors.
#
sub window_get_root_position {
  my ($window) = @_;
  my $x = 0;
  my $y = 0;
  while ($window->get_window_type ne 'root') {
    my ($parent_x, $parent_y) = $window->get_position;
    $x += $parent_x;
    $y += $parent_y;
    $window = $window->get_parent
      || croak 'Gtk2::Ex::GdkBits::window_get_root_position(): oops, didn\'t reach root window';
  }
  return ($x, $y);
}

sub window_clear_region {
  my ($win, $region) = @_;
  foreach my $rect ($region->get_rectangles) {
    $win->clear_area ($rect->values);
  }
}

# Not yet documented, might move elsewhere ...
# Or maybe better $rect->intersect not undef ...
sub rect_contains_rect {
  my ($rect, $part) = @_;
  return $rect->x <= $part->x
    && $rect->y <= $part->y
    && $rect->x + $rect->width  >= $part->x + $part->width
    && $rect->y + $rect->height >= $part->y + $part->height;
}

1;
__END__

=for stopwords Gdk Ryde Gtk2-Ex-WidgetBits pixmap

=head1 NAME

Gtk2::Ex::GdkBits - miscellaneous Gdk helpers

=head1 SYNOPSIS

 use Gtk2::Ex::GdkBits;

=head1 FUNCTIONS

=over 4

=item C<($x,$y) = Gtk2::Ex::GdkBits::window_get_root_position ($window)>

Return two values C<$x,$y> which are the top left corner of C<$window> in
root window coordinates.

This is the same as C<< $window->get_origin >>, but it's implemented with
C<< $window->get_position >> calls and thus uses the most recently recorded
window positions rather than making an X server round-trip.

=item C<($x,$y) = Gtk2::Ex::GdkBits::window_clear_region ($window, $region)>

Clear the area of C<$region> in C<$window> to its background pixel colour or
pixmap contents.

=cut

# The only time there's a difference is if another client (like the window
# manager) is moving your windows, in which case new positions are only
# recorded once the C<configure-notify> events have been processed.
#

# Not certain about this yet:
#
# =item C<Gtk2::Ex::GdkBits::rect_contains_rect ($rect, $part)>
# 
# C<$rect> and C<$part> are C<Gtk2::Gdk::Rectangle> objects.  Return true if
# C<$rect> contains C<$part> entirely, including if the two are equal.

=back

=head1 EXPORTS

Nothing is exported by default, but the functions can be requested in usual
C<Exporter> style,

    use Gtk2::Ex::GdkBits 'window_clear_region';
    position_widget_topcentre ($win, $region);

There's no C<:all> tag since this module is meant as a grab-bag of functions
and to import as-yet unknown things would be asking for name clashes.

=head1 SEE ALSO

L<Gtk2::Ex::WidgetBits>, L<Gtk2::Gdk>, L<Gtk2::Gdk::Window>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/gtk2-ex-widgetbits/index.html>

=head1 LICENSE

Copyright 2008, 2009, 2010, 2011 Kevin Ryde

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
