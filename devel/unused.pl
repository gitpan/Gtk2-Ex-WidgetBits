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











my %tooltip_text_pname = ('tooltip_text' => 1,
                          'tooltip-text' => 1);

sub without_tooltip_text {
  require Gtk2;
  if ($VERBOSE) {
    print STDERR "Test::Without::Gtk2Things: without tooltip-text property, per Gtk before 2.12\n";
  }

  no warnings 'redefine', 'once';
  undef *Gtk2::Widget::get_tooltip_text;
  undef *Gtk2::Widget::set_tooltip_text;
  undef *Gtk2::Entry::get_icon_tooltip_text;
  undef *Gtk2::Entry::set_icon_tooltip_markup;
  undef *Gtk2::MenuToolButton::set_arrow_tooltip_text;
  undef *Gtk2::MenuToolButton::set_arrow_tooltip_markup;

  # think these are the query-tooltip mechanism, and are 2.16 up
  # undef *Gtk2::StatusIcon::set_tooltip_text;
  # undef *Gtk2::StatusIcon::get_tooltip_text;
  {
    my $orig = Glib::Object->can('list_properties');
    *Glib::Object::list_properties = sub {
      my ($class) = @_;
      if ($class->isa('Gtk2::Widget')) {
        return grep {$_->get_name ne 'tooltip-text'} &$orig (@_);
      } else {
        goto $orig;
      }
    };
  }
  {
    my $orig = Glib::Object->can('find_property');
    *Glib::Object::find_property = sub {
      my ($class, $pname) = @_;
      if ($class->isa('Gtk2::Widget') && $tooltip_text_pname{$pname}) {
        return undef;
      } else {
        goto $orig;
      }
    };
  }
  foreach my $func ('get', 'get_property') {
    my $orig = Glib::Object->can($func); # force autoload
    my $new = sub {
      for (my $i = 1; $i < @_; $i++) {
        if ($tooltip_text_pname{$_[$i]}) {
          croak "Test-Without-Gtk2Things: no get property $pname";
        }
      }
      goto $orig;
    };
    my $func = "Glib::Object::$func";
    no strict 'refs';
    *$func = $new;
  }
  foreach my $func ('set', 'set_property') {
    my $orig = Glib::Object->can($func); # force autoload
    my $new = sub {
      for (my $i = 1; $i < @_; $i += 2) {
        if ($tooltip_text_pname{$_[$i]}) {
          croak "Test-Without-Gtk2Things: no set property $pname";
        }
      }
      goto $orig;
    };
    my $func = "Glib::Object::$func";
    no strict 'refs';
    *$func = $new;
  }
}

