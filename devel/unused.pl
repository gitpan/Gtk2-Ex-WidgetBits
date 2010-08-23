#!/usr/bin/perl -w

# Copyright 2009, 2010 Kevin Ryde

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
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;
use Gtk2;

# post-order visiting
#
sub remove_matching_rows {
  my ($model, $subr) = @_;

  my @pending_parents;
  my $iter = $model->get_iter_first;

  for (;;) {
    my $child = $model->iter_children;
    if ($child) {
      push @pending_parents, $iter;
      $iter = $child;
      next;
    }

  NORECURSE:
    if ($subr->($model, $iter)) {
      if ($model->remove ($iter)) {
        next;  # more at this depth
      }
    } else {
      $iter = $model->iter_next ($iter);
      if ($iter) {
        next;  # more at this depth
      }
    }

    # no more at this depth
    $iter = pop @pending_parents;
    if (! $iter) {
      return; # no more parents either
    }
    goto NORECURSE;
  }
}

__END__

# When DESTROY runs the weakening in obj_list has been applied, so our entry
# to get rid of is an undef.  Must splice() not grep or lose weakening on
# other entries.
sub _splice_out {
  my ($aref, $self) = @_;
  for (my $i = 0; $i <= $#$aref; $i++) {
    if (! defined $aref->[$i] || $aref->[$i] == $self) {
      splice @$aref, $i,1;
    } else {
      $i++;
    }
  }
  return $aref;
}

