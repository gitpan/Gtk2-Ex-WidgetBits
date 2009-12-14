# Copyright 2007, 2008, 2009 Kevin Ryde

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

package Gtk2::Ex::Units;
use 5.008;
use strict;
use warnings;
use Carp;
use Gtk2::Pango; # for PANGO_SCALE

use base 'Exporter';
our @EXPORT_OK = qw(em ex digit_width line_height
                    width height
                    set_default_size_with_subsizes
                    size_request_with_subsizes);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

our $VERSION = 13;

use constant DEBUG => 0;


#------------------------------------------------------------------------------

sub _to_screen {
  my ($target) = @_;
  if (my $func = $target->can('get_screen')) {
    $target = &$func ($target);
  }
  return ($target
          || croak "No screen for target $target");
}

sub _pango_rect {
  my ($target, $str, $logical) = @_;
  if (DEBUG) { print "_pango_rect() $target '$str'\n"; }

  if ($target->can ('create_pango_layout')) {
    # if widget instead of layout
    $target = $target->create_pango_layout ($str);
  } else {
    $target->set_text ($str);
  }
  return ($target->get_extents)[$logical||0];  # ($ink_rect,$logical_rect)
}

#------------------------------------------------------------------------------

sub em {
  my ($target) = @_;
  return _pango_rect($target,'M')->{'width'} / Gtk2::Pango::PANGO_SCALE;
}
sub ex {
  my ($target) = @_;
  return _pango_rect($target,'x')->{'height'} / Gtk2::Pango::PANGO_SCALE;
}

sub line_height {
  my ($target) = @_;
  return _pango_rect($target,"\n",1)->{'height'} / Gtk2::Pango::PANGO_SCALE;
}

sub digit_width {
  my ($target) = @_;
  return _pango_rect($target,"0\n1\n2\n3\n4\n5\n6\n7\n8\n9")->{'width'}
    / Gtk2::Pango::PANGO_SCALE;
}

#------------------------------------------------------------------------------
# width

use constant { _pixel => 1,
               _MILLIMETRES_PER_INCH => 25.4 };

sub _mm_width {
  my ($target) = @_;
  my $screen = _to_screen($target);
  return $screen->get_width / $screen->get_width_mm;
}
sub _inch_width {
  my ($target) = @_;
  return _MILLIMETRES_PER_INCH * _mm_width($target);
}
sub _screen_width {
  my ($target) = @_;
  return _to_screen($target)->get_width;
}
my %width = (pixel   => \&_pixel,
             pixels  => \&_pixel,
             em      => \&em,
             ems     => \&em,
             digit   => \&digit_width,
             digits  => \&digit_width,
             mm      => \&_mm_width,
             inch    => \&_inch_width,
             inches  => \&_inch_width,
             screen  => \&_screen_width,
             screens => \&_screen_width,
            );

#------------------------------------------------------------------------------
# height

sub _mm_height {
  my ($target) = @_;
  my $screen = _to_screen($target);
  return $screen->get_height / $screen->get_height_mm;
}
sub _inch_height {
  my ($target) = @_;
  return _MILLIMETRES_PER_INCH * _mm_height($target);
}
sub _screen_height {
  my ($target) = @_;
  return _to_screen($target)->get_height;
}

my %height = (pixel   => \&_pixel,
              pixels  => \&_pixel,
              ex      => \&ex,
              exes    => \&ex,
              line    => \&line_height,
              lines   => \&line_height,
              mm      => \&_mm_height,
              inch    => \&_inch_height,
              inches  => \&_inch_height,
              screen  => \&_screen_height,
              screens => \&_screen_height,
             );

#------------------------------------------------------------------------------
# shared

sub width {
  push @_, \%width, \%height;
  goto \&_units;
}
sub height {
  push @_, \%height, \%width;
  goto \&_units;
}
sub _units {
  my ($target, $str, $h, $other) = @_;
  if (DEBUG) { print "_units \"$str\"\n"; }

  my ($amount,$unit) = ($str =~ /(.*?)\s*([[:alpha:]_]+)$/s)
    or return $str;

  if (my $func = $h->{$unit}) {
    return $amount * &$func ($target);
  }
  croak "Unrecognised unit \"$unit\"";
}


#-----------------------------------------------------------------------------

sub set_default_size_with_subsizes {
  my $window = $_[0];
  my $req = size_request_with_subsizes (@_);
  $window->set_default_size ($req->width, $req->height);
}

sub size_request_with_subsizes {
  my ($widget, @elems) = @_;

  # Each change is guarded as it's made, in case the action on a subsequent
  # $widget provokes an error, eg. if not a Gtk2::Widget.  A guard object
  # for each widget is a little less code than say an array of saved
  # settings and a loop to undo them.

  require Scope::Guard;
  my @guard;

  foreach my $elem (@elems) {
    my ($widget, $width, $height) = @$elem;
    my ($save_width, $save_height) = $widget->get_size_request;
    my $width_pixels = (defined $width
                        ? Gtk2::Ex::Units::width($widget,$width)
                        : $save_width);
    my $height_pixels = (defined $height
                        ? Gtk2::Ex::Units::height($widget,$height)
                        : $save_height);
    push @guard, Scope::Guard->new
      (sub { $widget->set_size_request ($save_width, $save_height) });
    $widget->set_size_request ($width_pixels, $height_pixels);
  }

  return $widget->size_request;
}

#-----------------------------------------------------------------------------
# unused bits

#   if (my $func = $other->{$unit}) {
#     my $factor = $h->{'_factor_other'};
#     return $amount * &$factor($target) * &$func($target);
#   }
# sub _factor_width_to_height {
#   my ($target) = @_;
#   return 1 / _factor_height_to_width($target);
# }
# sub _factor_height_to_width {
#   my ($target) = @_;
#   my $screen = _to_screen($target);
#   return ($screen->get_height_mm * $screen->get_width)
#     / ($screen->get_height * $screen->get_width_mm);
# }
#              _factor_other => \&_factor_width_to_height
#              _factor_other => \&_factor_height_to_width

# For the subsizes really have to dig out the actual child to set the size
# on, so as to correctly incorporate any container border-width etc.
#
# For unit sizes as such looking into the label child of a menuitem is handy
# though ...
#
#   while (my $func = $target->can('Gtk2_Ex_Units_target')) {
#     $target = (&$func($target) || last);
#   }
# *Gtk2::Bin::Gtk2_Ex_Units_target = \&Gtk2::Bin::get_child;

# Subclass for new units is handy and needs no explicit setup.  Choose a
# name for width/height functions down there.  Maybe distinguish not-found
# from cannot-load using Module::Find or Module::Plugin, as long as funcs in
# @INC still worked.
#
#   require Module::Load;
#   foreach my $suffix ('', 's', 'es') {
#     my $unitclass = lc($unit);
#     $unitclass =~ s/$suffix$// or next;
#     $unitclass = "Gtk2::Ex::Units::$unitclass";
#     eval { Module::Load::load ($unitclass) }
#       || do {
#         if (DEBUG >= 2) { print "  cannot load $unitclass -- $@"; };
#       };
#
#     if (my $func = $unitclass->can($method)) {
#       if (DEBUG) { print "  use $unitclass->$method\n"; }
#       return &$func ($unitclass, $target, $amount);
#     }
#   }


#-----------------------------------------------------------------------------

1;
__END__

=head1 NAME

Gtk2::Ex::Units -- widget sizes in various units

=for test_synopsis my ($dialog, $entry, $textview, $pixels, $widget)

=head1 SYNOPSIS

 use Gtk2::Ex::Units;

 Gtk2::Ex::Units::set_default_size_with_subsizes
     ($dialog, [ $entry, '40 em' ],
               [ $textview, '20 em', '10 lines' ]);

 $pixels = Gtk2::Ex::Units::em($widget);

=head1 DESCRIPTION

This is some functions for working with sizes of widgets etc expressed in
units like em, line height, millimetres, etc.

The best feature is C<set_default_size_with_subsizes> which helps establish
a sensible initial size for a dialog or toplevel window when it includes
text entry widgets etc which don't have a desired size, or not when empty.

=head1 EXPORTS

Nothing is exported by default, but the functions can be requested
individually or with C<:all> in the usual way (see L<Exporter>).

    use Gtk2::Ex::Units qw(em ex);

=head1 FUNCTIONS

=head2 String Sizes

=over 4

=item C<< $pixels = Gtk2::Ex::Units::width ($target, $str) >>

=item C<< $pixels = Gtk2::Ex::Units::height ($target, $str) >>

Return a size in pixels on C<$target> for a string size C<$str> like

    6 ems          # width of an "M" character
    1 digit        # width of a digit 0 to 9
    2 ex           # height of an "x" character
    1 line         # height of a line (baseline to baseline)
    10 mm          # millimetres, per screen size
    2.5 inches     # inches, per screen size
    5 pixels       # already pixels, just return 5
    100            # no units, just return 100

Either singular like "inch" or plural "inches" can be given.  Decimals can
be given, and the return may not be an integer.

"em", "ex", "digit" and "line" follow the basic sizes functions below,
according to the font in C<$target>.  For them C<$target> can be a
C<Gtk2::Widget> or a Pango layout C<Gtk2::Pango::Layout>.

"mm" and "inch" are based on the screen size for C<$target>.  For them
C<$target> can be a C<Gtk2::Widget>, a C<Gtk2::Gdk::Window>, or anything
with a C<get_screen> giving a C<Gtk2::Gdk::Screen>.

Currently "em" and "digit" are only for use as a width, and C<ex> and
C<line> only for a height.  In the future they may be supported on the
opposite axis, probably based on what rotated text would look like.  (The
same pixels, or scaled if pixels aren't square?)

=item C<< Gtk2::Ex::Units::set_default_size_with_subsizes ($toplevel, $subsize, ...) >>

=item C<< $requisition = Gtk2::Ex::Units::size_request_with_subsizes ($widget, $subsize, ...) >>

Establish a widget size based on temporary forced sizes for some of its
children.  Generally the child widgets will be things like C<Gtk2::TreeView>
or C<Gtk2::Viewport> which don't have a size while empty but where you want
to allow room for likely contents.

Each C<$subsize> argument is an arrayref

    [ $widget, $width, $height ]

C<$width> and C<$height> are put through the C<width> and C<height>
functions above, so they can be either a count of pixels, or a string like
S<"6 ems"> or S<"10 lines">.  C<-1> means the widget's desired size in that
axis (as usual for C<set_size_request>), and C<undef> means the current size
request setting of that axis (ie. no change to it).

C<set_default_size_with_subsizes> is for use on C<Gtk2::Window> toplevel or
dialog widgets and applies the size to C<< $toplevel->set_default_size >>.
This gives a good initial size for C<$toplevel>, but allows the user to
expand or shrink later.

    Gtk2::Ex::Units::set_default_size_with_subsizes
        ($dialog, [ $textview, '40 ems', '10 lines' ]);

C<size_request_with_subsizes> is for use on any container widget and just
returns a new C<Gtk2::Requisition> with the size determined.

=back

=head2 Basic Sizes

In the following functions C<$target> can be a C<Gtk2::Widget> or a
C<Pango::Layout>.

=over 4

=item C<< $pixels = Gtk2::Ex::Units::em ($target) >>

=item C<< $pixels = Gtk2::Ex::Units::ex ($target) >>

Return the width of an "M", or the height of an "x", in pixels, for
C<$target>.

=item C<< $pixels = Gtk2::Ex::Units::digit_width ($target) >>

Return the width of the widest digit "0" to "9", in pixels, for C<$target>.
In a proportional font a "1" might be narrower than a "9", making
C<digit_width> an over-estimate of the size you need for some values.

=item C<< $pixels = Gtk2::Ex::Units::line_height ($target) >>

Return the height of a line, in pixels, for C<$target>.  This the height of
the tallest glyph in the target font, plus any pango line spacing
(C<< $layout->set_spacing >>).

=back

=head1 SEE ALSO

L<Gtk2::Gdk::Screen> for screen size in pixels and millimetres

L<Math::Units>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/gtk2-ex-widgetbits/index.html>

=head1 LICENSE

Copyright 2007, 2008, 2009 Kevin Ryde

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
