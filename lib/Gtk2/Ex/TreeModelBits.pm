# Copyright 2007, 2008 Kevin Ryde

# This file is part of Gtk2-Ex-WidgetBits.
#
# Gtk2-Ex-WidgetBits is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 2, or (at your option) any
# later version.
#
# Gtk2-Ex-WidgetBits is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-WidgetBits.  If not, see <http://www.gnu.org/licenses/>.

package Gtk2::Ex::TreeModelBits;
use strict;
use warnings;
use Gtk2;

our $VERSION = 7;

use constant DEBUG => 0;


sub column_contents {
  my ($model, $column) = @_;
  my @ret;

  # pre-extend, helpful for a list model style, likely to do little for an
  # actual tree
  $#ret = $model->iter_n_children(undef) - 1;

  my $pos = 0;
  $model->foreach (sub {
                     my ($model, $path, $iter) = @_;
                     $ret[$pos++] = $model->get_value ($iter, $column);
                     return 0; # keep walking
                   });
  if (DEBUG) {
    if ($pos < @ret) {
      print "column_contents(): oops, iterating gave less than n_children\n";
    }
  }
  $#ret = $pos-1;
  return @ret;
}

sub remove_matching_rows {
  my ($model, $subr) = @_;

  my @pending;
  my $iter = $model->get_iter_first;

  for (;;) {
    # undef at end of one level, pop the upper level, or finished if no upper
    $iter ||= pop @pending || last;

    if (DEBUG) { print "looking at ",$model->get_path($iter)->to_string,"\n"; }

    if ($subr->($model, $iter)) {
      if (! $model->remove ($iter)) {
        $iter = undef; # no more at this depth
      }
      # otherwise $iter updated to next row
      next;
    }

    my $child = $model->iter_children ($iter);
    $iter = $model->iter_next ($iter);

    if ($child) {
      if (DEBUG) { print "descend to child ",
                     $model->get_path($child)->to_string,"\n"; }
      push @pending, $iter;
      $iter = $child;
    }
  }
}

sub all_column_types {
  my ($model) = @_;
  return map { $model->get_column_type($_) } 0 .. $model->get_n_columns - 1;
}


=head1 NAME

Gtk2::Ex::TreeModelBits - miscellaneous TreeModel helpers

=head1 SYNOPSIS

 use Gtk2::Ex::TreeModelBits;

=head1 FUNCTIONS

=over 4

=item C<@values = Gtk2::Ex::TreeModelBits::column_contents ($model, $col)>

Return a list of all the values in column number C<$col> of a
C<Gtk2::TreeModel> object C<$model>.

Any tree structure in the model is flattened out for the return.  A parent
row's column value comes first, followed by the column values from its
children, recursively, as per C<< $model->foreach >>.

=item C<Gtk2::Ex::TreeModelBits::remove_matching_rows ($store, $subr)>

Remove from C<$store> all rows passing C<$subr>.  C<$store> can be a
C<Gtk2::TreeStore>, a C<Gtk2::ListStore>, or another type with the same
style C<< $store->remove >> method.  C<$subr> is called

    $want_remove = &$subr ($store, $iter)

where C<$iter> is the row being considered and C<$subr> should return true
if it wants to remove the row.  The order rows are considered is
unspecified, except that a parent row is tested before its children (the
children of course tested only if the parent is not removed).

=item C<@types = Gtk2::Ex::TreeModelBits::all_column_types ($model)>

Return a list of all the column types in C<$model>.  For example to create
another ListStore with the same types as an existing one,

    my $new_store = Gtk2::ListStore->new
      (Gtk2::Ex::TreeModelBits::all_column_types ($old_store));

=back

=head1 SEE ALSO

L<Gtk2::ListModel>, L<Gtk2::TreeModel>, L<Gtk2::Ex::WidgetBits>

=cut

1;
