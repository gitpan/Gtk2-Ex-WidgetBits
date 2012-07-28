# Copyright 2010, 2011, 2012 Kevin Ryde

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

our $VERSION = 46;

# Names a bit too generic to want to import usually.
# use Exporter;
# our @ISA = ('Exporter');
# our @EXPORT_OK = qw(scroll_value
#                     scroll_increment
#                     set_maybe);

#------------------------------------------------------------------------------

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

# Validate $type as "page" or "step" so as not to let dubious input call an
# arbitrary method.
my %increment_method = (page => 'page_increment',
                        step => 'step_increment',
                        # page_increment => 'page_increment',
                        # step_increment => 'step_increment',
                       );
sub scroll_increment {
  my ($adj, $inctype, $inverted) = @_;
  my $method = $increment_method{$inctype}
    || croak "Unrecognised increment type: ",$inctype;
  scroll_value ($adj, $adj->$method * ($inverted ? -1 : 1));
}

my %direction_is_inverted = (up    => 1,  # Gtk2::Gdk::ScrollDirection enum
                             down  => 0,
                             left  => 1,
                             right => 0);
sub scroll_event {
  my ($adj, $event, $inverted) = @_;
  $inverted ^= $direction_is_inverted{$event->direction};
  Gtk2::Ex::AdjustmentBits::scroll_increment
      ($adj,
       ($event->state & 'control-mask' ? 'page' : 'step'),
       $inverted);
  return 0; # Gtk2::EVENT_PROPAGATE
}

#------------------------------------------------------------------------------
# set_maybe()

BEGIN {
# configure() emits notify and changed even if upper/lower etc unchanged
#
#   if (Gtk2::Adjustment->can('configure')) {
#     # new in gtk 2.14 and Perl-Gtk 1.240
#     eval "\n#line ".(__LINE__+1)." \"".__FILE__."\"\n" . <<'HERE' or die;
# 
#   sub set_maybe {
#     my ($adj, %values) = @_;
#     ### AdjustmentBits set_maybe(), with configure()
#     
#     $adj->configure (map {
#       my $value = delete $values{$_};
#       (defined $value ? $value : $adj->$_)
#     } qw(value
#          lower upper
#          step_increment page_increment page_size));
#     if (%values) {
#       croak "Unrecognised adjustment field(s) ",join(',',keys %values);
#     }
#   }
#   1;
# HERE
# 
#   } els
  if (do {
    my $adj = Gtk2::Adjustment->new (0,0,0,0,0,0);
    my $result = 0;
    $adj->signal_connect (changed => sub { $result = 1 });
    $adj->notify ('upper');
    ### test of notify emits changed: $result
    $result
  }) {

    # In gtk 2.18 emitting 'notify' wastefully emits 'changed' too.
    # Freezing collapses to just one of those.
    require Glib::Ex::FreezeNotify;
    eval "\n#line ".(__LINE__+1)." \"".__FILE__."\"\n" . <<'HERE' or die;

  sub set_maybe {
    my ($adj, %values) = @_;
    ### AdjustmentBits set_maybe() from ",caller()
    
    my $value = delete $values{'value'};
    if (! defined $value) { $value = $adj->value; }
    
    # compare after storing to see the value converted to double perhaps
    # from a 64-bit perl integer etc
    foreach my $key (keys %values) {
      my $old = $adj->$key;
      $adj->$key ($values{$key});
      if ($adj->$key == $old) {
        delete $values{$key};
      }
    }
    ### set_maybe change: %values
    
    $value = max ($adj->lower,
                  min ($adj->upper - $adj->page_size,
                       $value));
    {
      my $old = $adj->value;
      $adj->value ($value);
      if ($adj->value != $old) {
        $values{'value'} = 1;
      }
    }
    
    if (%values) {
      my $freezer = Glib::Ex::FreezeNotify->new ($adj);
      foreach my $key (keys %values) {
        $adj->notify ($key);
      }
      if (defined $values{'value'}) {
        $adj->value_changed;
      }
    }
  }
  1;
HERE

  } else {
    eval "\n#line ".(__LINE__+1)." \"".__FILE__."\"\n" . <<'HERE' or die;

  sub set_maybe {
    my ($adj, %values) = @_;

    my $value = delete $values{'value'};
    if (! defined $value) { $value = $adj->value; }

    # compare after storing so as to see the value converted to double
    # possibly from a 64-bit perl int etc
    foreach my $key (keys %values) {
      my $old = $adj->$key;
      $adj->$key ($values{$key});
      if ($adj->$key == $old) {
        delete $values{$key};
      }
    }
    ### set_maybe change: \%values

    $value = max ($adj->lower,
                  min ($adj->upper - $adj->page_size,
                       $value));
    {
      my $old = $adj->value;
      $adj->value ($value);
      if ($adj->value != $old) {
        $values{'value'} = 1;
      }
    }

    foreach my $key (keys %values) {
      $adj->notify ($key);
    }
    my $v = delete $values{'value'};
    if (%values) {
      $adj->changed;
    }
    if (defined $v) {
      $adj->value_changed;
    }
  }
  1;
HERE
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

=head2 Scroll

=over 4

=item C<< Gtk2::Ex::AdjustmentBits::scroll_value ($adj, $amount) >>

Add C<$amount> to the value in C<$adj>, restricting the result to between
C<lower> and S<C<upper - page>>, as suitable for a scrollbar range etc.

=item C<< Gtk2::Ex::AdjustmentBits::scroll_increment ($adj, $inctype) >>

=item C<< Gtk2::Ex::AdjustmentBits::scroll_increment ($adj, $inctype, $inverted) >>

Increment the value in C<$adj>.  C<$inctype> (a string) can be either

    "step"         increment by step_increment()
    "page"         increment by page_increment()

If optional parameter C<$inverted> is true then decrement instead of
increment.  The scroll is applied per C<scroll_value()> above.

=item C<< $propagate = Gtk2::Ex::AdjustmentBits::scroll_event ($adj, $event) >>

=item C<< $propagate = Gtk2::Ex::AdjustmentBits::scroll_event ($adj, $event, $inverted) >>

Scroll C<$adj> according to C<$event>, a C<Gtk2::Gdk::Event::Scroll>.

C<$event-E<gt>direction()> gives the direction

    "up"          decrement
    "left"        decrement
    "down"        increment
    "right"       increment

If the control key is held down (C<control-mask> in
C<< $event->state() >>) then the scroll amount is C<page_increment> rather
than C<step_increment>.

If optional parameter C<$inverted> is true then increment/decrement are
swapped, so up+left are increment and down+right are decrement.

The return value is C<Gtk2::EVENT_PROPAGATE> which may be convenient if
called from a widget C<scroll-event> signal handler.

The increment direction corresponds to an adjustment used in a
C<Gtk2::ScrollBar> (and its C<inverted> property), and similar such widgets.

=back

=head2 Other

=over

=item C<< Gtk2::Ex::AdjustmentBits::set_maybe ($adjustment, field => $value, ...) >>

Set fields in C<$adjustment>, with changed and notify signals emitted if the
values are different from what's already there.  The fields are

    value
    upper
    lower
    page_size
    page_increment
    step_increment

For example

    Gtk2::Ex::AdjustmentBits::set_maybe
           ($adjustment, upper => 100.0,
                         lower => 0.0,
                         value => 50.0);

The plain field getter/setters like C<< $adjustment->upper() >> don't emit
any signals, and the object C<< $adjustment->set >> only emits C<notify> (or
C<changed> too in Gtk 2.18 or thereabouts).  C<set_maybe> takes care of all
necessary signals and does them only after storing all the values and only
if actually changed.

Not emitting signals when values are unchanged may save some work in widgets
controlled by C<$adjustment>, though a good widget might notice unchanged
values itself.

=back

=head1 SEE ALSO

L<Gtk2::Adjustment>, L<Gtk2::Ex::WidgetBits>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/gtk2-ex-widgetbits/index.html>

=head1 LICENSE

Copyright 2010, 2011, 2012 Kevin Ryde

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
