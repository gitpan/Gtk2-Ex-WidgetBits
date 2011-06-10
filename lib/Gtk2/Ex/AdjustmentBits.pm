# Copyright 2010, 2011 Kevin Ryde

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

package Gtk2::Ex::AdjustmentBits;
use 5.008;
use strict;
use warnings;
use Carp;
use Gtk2 1.220;
use List::Util 'min', 'max';

# uncomment this to run the ### lines
#use Smart::Comments;

our $VERSION = 41;

sub scroll_value {
  my ($adj, $amount) = @_;
  my $oldval = $adj->value;
  $adj->value (max ($adj->lower,
                    min ($adj->upper - $adj->page_size,
                         $oldval + $amount)));
  # re-fetch $adj->value() for comparison to allow round-off on storing if
  # perl NV is a long double
  if ($adj->value != $oldval) {
    $adj->notify ('value');
    $adj->signal_emit ('value-changed');
  }
}

1;
__END__

=for stopwords Ryde Gtk2-Ex-WidgetBits scrollbar

=head1 NAME

Gtk2::Ex::AdjustmentBits -- helpers for Gtk2::Adjustment objects

=head1 SYNOPSIS

 use Gtk2::Ex::AdjustmentBits;

=head1 FUNCTIONS

=over 4

=item C<< Gtk2::Ex::AdjustmentBits::scroll_value ($adj, $amount) >>

Add C<$amount> to the value in C<$adj>, restricting the result to between
C<lower> and S<C<upper - page>>, as suitable for a scrollbar range etc.

=back

=head1 SEE ALSO

L<Gtk2::Adjustment>, L<Gtk2::Ex::WidgetBits>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/gtk2-ex-widgetbits/index.html>

=head1 LICENSE

Copyright 2010, 2011 Kevin Ryde

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
