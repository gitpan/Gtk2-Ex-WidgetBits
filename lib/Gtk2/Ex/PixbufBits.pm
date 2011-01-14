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

package Gtk2::Ex::PixbufBits;
use 5.008;
use strict;
use warnings;
use Carp;
use Gtk2;
use List::Util;

use Exporter;
our @ISA = ('Exporter');
our @EXPORT_OK = qw(type_to_format
                    save_adapt
                    save_adapt_options
                    sampled_majority_color);

our $VERSION = 35;

# uncomment this to run the ### lines
#use Smart::Comments;

sub type_to_format {
  my ($type) = @_;
  return List::Util::first {$_->{'name'} eq $type}
    Gtk2::Gdk::Pixbuf->get_formats;
}

#------------------------------------------------------------------------------

# Could extract the tEXts from get_option() as defaults to save back.  But
# can't list what's in there, so maybe only the png specified ones.

sub save_adapt {
  my $pixbuf = shift;   # ($pixbuf, $filename, $type, key=>value, ...) 
  $pixbuf->save (save_adapt_options($pixbuf, @_));
}

my %tiff_compression_types = (none    => 1,
                              huffman => 2,
                              lzw     => 5,
                              jpeg    => 7,
                              deflate => 8);

sub save_adapt_options {
  my $pixbuf = shift;
  my $filename = shift;
  my $type = shift;
  if (@_ & 1) {
    croak 'PixbufBits save_adapt(): option key without value (odd number of arguments)';
  }
  my @first = ($pixbuf, $filename, $type);
  my @rest;
  my %seen;

  while (@_) {
    my $key = shift;
    my $value = shift;
    if ($key eq 'zlib_compression') {
      next unless $type eq 'png';
      # png saving always available, but compression option only in 2.8 up
      next if Gtk2->check_version(2,8,0);
      $key = 'compression';

    } elsif ($key eq 'tiff_compression_type') {
      next unless $type eq 'tiff';
      next if Gtk2->check_version(2,20,0);  # new in 2.20
      $key = 'compression';
      $value = $tiff_compression_types{$value} || $value;

    } elsif ($key =~ /^tEXt:/) {
      next unless $type eq 'png';
      next if Gtk2->check_version(2,8,0); # compression new in 2.8.0
      # Gtk2-Perl 1.221 doesn't upgrade byte values to utf8 the way it does
      # in other wrappers, ensure utf8 for output
      utf8::upgrade($value);
      # text before "compression" or Gtk 2.20.1 botches the file output
      push @first, $key, $value;
      next;

    } elsif ($key eq 'quality_percent') {
      next unless $type eq 'jpeg';
      $key = 'quality';

    } elsif ($key eq 'x_hot' || $key eq 'y_hot') {
      # no xpm saving as of 2.20, but maybe it would use x_hot/y_hot
      # if/when available ... || $type eq 'xpm';
      next unless $type eq 'ico';
      $seen{$key} = 1;
      next if ! defined $value; # undef means no hotspot

      # } elsif ($key eq 'depth') {
      #   next unless $type eq 'ico';
      #
      # } elsif ($key eq 'icc-profile') {
      #   # this mangling not yet documented ....
      #   next unless $type eq 'png' ||  $type eq 'tiff';
      #   next if Gtk2->check_version(2,20,0);
    }
    push @rest, $key, $value;
  }

  if ($pixbuf && $type eq 'ico') {
    foreach my $key ('x_hot', 'y_hot') {
      unless ($seen{$key}) {
        if (defined (my $default = $pixbuf->get_option($key))) {
          push @rest, $key, $default;
        }
      }
    }
  }

  return @first, @rest;
}

#------------------------------------------------------------------------------
# Currently all pixels if <= 1800, or 900 pixels at random otherwise, with
# transparents skipped but only up to an absolute limit of 3600 attempts.
#
# The worst case is every pixel different and a hash entry for each.  If
# that was done for every pixel of a big image then it might use a lot of
# memory.  An in-place sort could put same pixels adjacent to find the
# biggest count, but a sort of a big image might be a bit slow.
#
use constant _SAMPLES => 900;

sub sampled_majority_color {
  my ($pixbuf) = @_;

  my $bytes_per_sample = $pixbuf->get_bits_per_sample / 8;
  my $n_channels = $pixbuf->get_n_channels;

  if ($pixbuf->get_colorspace ne 'rgb'
      || $bytes_per_sample != 1) {
    croak "sampled_majority_color() can only read 8-bit RGB or RGBA";
    #
    # || $bytes_per_sample != int($bytes_per_sample)
  }

  my $width = $pixbuf->get_width;
  my $height = $pixbuf->get_height;
  my $row_stride = $pixbuf->get_rowstride;
  my $pixel_bytes = $bytes_per_sample * 3;
  my $pixel_stride = $bytes_per_sample * $n_channels;
  my $zero = "\0" x $bytes_per_sample;
  my $data = $pixbuf->get_pixels;

  my %hash;
  # return true if accumulated, false if skip a transparent pixel
  my $acc = sub {
    my ($offset) = @_;
    return (substr ($data, $offset+$pixel_bytes, $bytes_per_sample) ne $zero
            && ++$hash{substr ($data, $offset, $pixel_bytes)});
  };

  if ($width * $height < 2 * _SAMPLES) {
    foreach my $y (0 .. $width-1) {
      my $offset = $y * $row_stride;
      foreach my $x (0 .. $width-1) {
        $acc->($offset);
        $offset += $pixel_stride;
      }
    }
  } else {
    for (my $i = 0; $i < _SAMPLES; $i++) {
      unless ($acc->($pixel_stride * int(rand($width))        # x
                     + $row_stride * int(rand($height)))) {   # y
        $i -= .75;
      }
    }
  }

  if (! %hash) {
    ### oops, only saw transparent pixels, what to do?
    return '#000000';
  }

  return sprintf '#%02X%02X%02X', unpack ('C*', _hash_key_with_max_value (\%hash));
}

# sub _pixel_bytes_to_color_string {
#   my ($pixbuf, $bytes) = @_;
#   if ($pixbuf->get_colorspace eq 'rgb') {
#     if ($pixbuf->get_bits_per_sample == 8) {
#       return sprintf '#%02X%02X%02X', unpack ('C*', $bytes);
#     }
#     # if ($pixbuf->get_bits_per_sample == 16) {
#     #   return sprintf '#%04X%04X%04X', unpack ('S*', $bytes);
#     # }
#   }
#   croak "sampled_majority_color() can only read 8-bit RGB or RGBA";
# }

# $hash is a hashref, return the key from it with the biggest value,
# comparing values as numbers with ">"
sub _hash_key_with_max_value {
  my ($hashref) = @_;
  my ($max_key, $max_value) = each %$hashref;
  while (my ($key, $value) = each %$hashref) {
    if ($value > $max_value) {
      $max_key = $key;
      $max_value = $value;
    }
  }
  return $max_key;
}

1;
__END__

=for stopwords Ryde pixbuf Gtk Gtk2 PNG Zlib png huffman lzw jpeg lossy JPEG filename PixbufFormat Gtk2-Perl fakery

=head1 NAME

Gtk2::Ex::PixbufBits -- misc Gtk2::Gdk::Pixbuf helpers

=head1 SYNOPSIS

 use Gtk2::Ex::PixbufBits;

=head1 FUNCTIONS

=over

=item C<< Gtk2::Ex::PixbufBits::save_adapt ($pixbuf, $filename, $type, key => value, ...) >>

=item C<< @args = Gtk2::Ex::PixbufBits::save_adapt_options ($pixbuf, $filename, $type, key => value, ...) >>

C<save_adapt()> saves a C<Gtk2::Gdk::Pixbuf> with various options adapted
for the target C<$type> and the options supported by the Gtk in use.
C<$type> is a string per C<< $pixbuf->save >>, such as "png" or "jpeg".

C<save_adapt_options()> adapts options and returns them, without saving.
The return can be passed to a C<< $pixbuf->save >>.

The idea is to give a full set of save options and have them automatically
reduced if not applicable to the C<$type> or not available in the Gtk
version.  For example the C<compression> option must be set different ways
for PNG or for TIFF.  The two separate compression options here are used
according to the C<$type>.

=over

=item C<zlib_compression> (integer 0 to 9 or -1)

A Zlib style compression level.  For C<$type> "png" and Gtk 2.8 up this
becomes the C<compression> option.

=item C<tiff_compression_type> (integer, or names "none", "huffman", "lzw", "jpeg" or "deflate")

A TIFF compression method.  For C<$type> "tiff" and Gtk 2.20 up this becomes
the C<compression> option.  String names "deflate" etc are converted to the
corresponding integer value.

=item C<quality_percent> (0 to 100)

An image quality percentage for lossy formats such as JPEG.  For C<$type>
"jpeg" this becomes the C<quality> option.

=item C<tEXt:foo> (string)

A PNG style keyword string.  For C<$type> "png" and Gtk 2.8 up this is
passed through as C<tEXt>, with a C<utf8::upgrade> if necessary in Gtk2-Perl
1.221.  These options are also moved to before any C<compression> option as
a workaround for a Gtk bug (if C<tEXt> after C<compression> then wrong text
strings are written).

=item C<x_hot>, C<y_hot> (integer or C<undef>)

The cursor hotspot position for C<$type> "ico".  C<undef> means no hotspot.
The default is the pixbuf C<get_option> C<x_hot>,C<y_hot> set when reading
an ICO or XPM file.

XPM is not writable as of Gtk 2.22 but if it becomes writable then perhaps
its hotspot can be set this way too.

=back

For example

    Gtk2::Ex::PixbufBits::save_adapt
      ($pixbuf,             # Gtk2::Gdk::Pixbuf object
       $users_filename,     # eg. string "/tmp/foo"
       $users_type,         # eg. string "png"
       zlib_compression      => 9,
       quality_percent       => 100,
       tiff_compression_type => "deflate",
       tEXt:Author           => "Yorick");
       
=item C<< $str = Gtk2::Ex::PixbufBits::sampled_majority_color($pixbuf) >>

Return a string which is the apparent majority colour in C<$pixbuf>,
established by sampling some pixels at random.  For an 8-bit RGB pixbuf the
return is a string like "#FF00FF".

This function only makes sense for images which have a particular dominant
background (or foreground) colour, it's no good if there's lots of shades of
grey etc.

The current code only supports 8-bit RGB or RGBA data formats, which is all
GdkPixbuf itself supports as of Gtk 2.22.  Transparent pixels (alpha channel
zero) are ignored.

The idea of sampling pixels at random is to avoid a fixed sampling algorithm
hitting a grid or pattern in the image which is not the majority colour.
For small images all pixels are checked (currently anything up to 1800
pixels).

=item C<< $format = Gtk2::Ex::PixbufBits::type_to_format ($type) >>

Return a C<Gtk2::Gdk::PixbufFormat> object for the given C<$type> string.
C<$type> is the format name, such as "png", "jpeg", etc (lower case).  If
C<$type> is unknown then return C<undef>.

C<Gtk2::Gdk::PixbufFormat> is new in Gtk 2.2.  It's unspecified what this
function does in Gtk 2.0.x.

=back

=head1 EXPORTS

Nothing is exported by default, but all functions can be requested in usual
C<Exporter> style,

    use Gtk2::Ex::PixbufBits 'save_adapt';
    save_adapt ($pixbuf, $filename, $type,
                'tEXt::Title' => 'Picture of Matchstick Men');

There's no C<:all> tag since this module is meant as a grab-bag of functions
and to import as-yet unknown things would be asking for name clashes.

=head1 SEE ALSO

L<Gtk2::Gdk::Pixbuf>, L<Gtk2::Ex::WidgetBits>, L<Gtk2::Ex::ComboBox::PixbufType>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/gtk2-ex-widgetbits/index.html>

=head1 LICENSE

Copyright 2007, 2008, 2009, 2010, 2011 Kevin Ryde

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
