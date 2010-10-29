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

package Gtk2::Ex::TreeModelBits;
use 5.008;
use strict;
use warnings;
use Gtk2;

our $VERSION = 28;

# uncomment this to run the ### lines
#use Smart::Comments;

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
  # iterating should give n_children, trim @ret if it doesn't
  ### assert: $pos >= scalar(@ret)
  $#ret = $pos-1;

  return @ret;
}

# If a remove() might end up removing more than one row then it's expected
# to leave $iter at whatever next row then exists (at the same depth).
# A multi-remove happens for instance in Gtk2::Ex::ListModelConcat when it's
# presenting two or more copies of one submodel.
# Gtk2::Ex::TreeModelFilter::Change::remove() asks for similar from its
# child remove().
#
sub remove_matching_rows {
  my $model = shift;
  my $subr = shift;

  my @pending;
  my $iter = $model->get_iter_first;

  for (;;) {
    # undef at end of one level, pop to upper level, or finished if no upper
    $iter ||= pop @pending || last;
    ### looking at: $model->get_path($iter)->to_string

    if ($subr->($model, $iter, @_)) {
      if (! $model->remove ($iter)) {
        $iter = undef; # no more at this depth
      }
      # otherwise $iter updated to next row
      next;
    }

    my $child = $model->iter_children ($iter);
    $iter = $model->iter_next ($iter);

    if ($child) {
      ### descend to child: $model->get_path($child)->to_string
      push @pending, $iter;
      $iter = $child;
    }
  }
}

sub all_column_types {
  my ($model) = @_;
  return map { $model->get_column_type($_) } 0 .. $model->get_n_columns - 1;
}

1;
__END__

=for stopwords TreeModel ListStore Ryde Gtk2 Gtk2-Ex-WidgetBits Gtk

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

=item C<Gtk2::Ex::TreeModelBits::remove_matching_rows ($store, $subr, ...)>

Remove from C<$store> all rows passing C<$subr>.  C<$store> can be a
C<Gtk2::TreeStore>, a C<Gtk2::ListStore>, or another type with the same
style C<< $store->remove >> method.  C<$subr> is called

    $want_remove = &$subr ($store, $iter, ...)

where C<$iter> is the row being considered, and any extra arguments to
C<remove_matching_rows> are passed on to C<$subr>.  C<$subr> should return
true if it wants to remove the row.

The order rows are considered and removed is unspecified, except that a
parent row is tested before its children (the children of course tested only
if the parent is not removed).

=item C<@types = Gtk2::Ex::TreeModelBits::all_column_types ($model)>

Return a list of all the column types in C<$model>.  For example to create
another ListStore with the same types as an existing one,

    my $new_store = Gtk2::ListStore->new
      (Gtk2::Ex::TreeModelBits::all_column_types ($old_store));

=back

=head1 OTHER NOTES

If you use an old Gtk 2.0.x and want to pass a C<Gtk2::ListStore> or
C<Gtk2::TreeStore> to C<remove_matching_rows> then get Perl-Gtk 1.240 or
higher to have the C<remove> method on those Stores return a flag the same
as in Gtk 2.2 and up.  Otherwise C<remove_matching_rows> will stop after the
first row removed.

=head1 SEE ALSO

L<Gtk2::ListStore>, L<Gtk2::TreeModel>, L<Gtk2::Ex::WidgetBits>

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
