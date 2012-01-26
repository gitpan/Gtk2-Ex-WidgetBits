# Copyright 2007, 2008, 2009, 2010, 2011, 2012 Kevin Ryde

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

package Gtk2::Ex::EntryBits;
use 5.008;
use strict;
use warnings;
use Gtk2;
use Scope::Guard;

our $VERSION = 45;

sub select_region_noclip {
  my ($entry, $start, $end) = @_;

  # Gtk2::Entry::select_region won't error out, but a subclassed method
  # might, or $entry might not be a Gtk2::Entry at all, so guard the temp
  # change to the realized() flag
  #
  my $save = $entry->realized;
  my $guard = Scope::Guard->new (sub { $entry->realized($save) });

  $entry->realized (0);
  $entry->select_region ($start, $end);
}

1;
__END__

=for stopwords Ryde Gtk2-Ex-WidgetBits

=head1 NAME

Gtk2::Ex::EntryBits -- misc functions for Gtk2::Entry widgets

=head1 SYNOPSIS

 use Gtk2::Ex::EntryBits;

=head1 FUNCTIONS

=over 4

=item C<< Gtk2::Ex::EntryBits::select_region_noclip ($entry, $start, $end) >>

Select text from C<$start> to C<$end> like C<< $entry->select_region >>, but
don't put it on the clipboard.  This is a good way to let the user type over
previous text, without upsetting any cut and paste in progress.

This is implemented with a nasty hack temporarily pretending C<$entry> is
unrealized.

=back

=head1 SEE ALSO

L<Gtk2::Entry>, L<Gtk2::Editable>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/gtk2-ex-widgetbits/index.html>

=head1 LICENSE

Copyright 2007, 2008, 2009, 2010, 2011, 2012 Kevin Ryde

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
