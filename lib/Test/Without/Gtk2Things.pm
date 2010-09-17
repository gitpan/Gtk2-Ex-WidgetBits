# Copyright 2010 Kevin Ryde

# Gtk2-Ex-WidgetBits is shared by several distributions.
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

package Test::Without::Gtk2Things;
use strict;
use warnings;

# uncomment this to run the ### lines
#use Smart::Comments;

our $VERSION = 25;

our $VERBOSE = 0;


# Not sure the without_foo methods are a good idea.  Might prefer a hash of
# names so can associate a gtk version number to a without-ness, to have a
# "without version 2.x" option etc.
#
# FIXME: deleting the whole glob with "undef *Foo::Bar::func" is probably
# not a good idea.  Maybe let Sub::Delete do the work.
#

sub import {
  my $class = shift;
  my $count = 0;

  foreach my $thing (@_) {
    if ($thing eq '-verbose' || $thing eq 'verbose') {
      $VERBOSE++;

    } elsif ($thing eq 'all') {
      foreach my $method ($class->all_without_methods) {
        $class->$method;
        $count++;
      }

    } else {
      (my $method = "without_$thing") =~ tr/-/_/;
      if (! $class->can($method)) {
        die "Unknown thing to disable: $thing";
      }
      $class->$method;
      $count++;
    }
  }
  if ($VERBOSE) {
    print STDERR
      "Test::Without::Gtk2Things: count without $count thing",
        ($count==1?'':'s'), "\n";
  }
}

# search @ISA with a view to subclasses, but is it a good idea?
sub all_without_methods {
  my ($class) = @_;
  ### all_without_methods(): $class
  my @methods;
  no strict 'refs';
  my @classes = ($class, @{"${class}::ISA"});
  ### @classes
  while (@classes) {
    my $c = shift @classes;
    ### $c
    #     my @keys = keys %{"${c}::"};
    #     ### keys: @keys
    push @methods, grep {/^without_/} keys %{"${c}::"};
    push @classes, grep {/^Test/} @{$c::ISA};
    ### @classes
  }
  ### @methods
  return @methods;
}

# our @ISA = ('TestX');
# {
# package TestX;
# our @ISA = ('TestY');
# }
# print __PACKAGE__->all_without_methods();

sub without_insert_with_values {
  require Gtk2;
  if ($VERBOSE) {
    print STDERR "Test::Without::Gtk2Things: without ListStore,TreeStore insert_with_values(), per Gtk before 2.6\n";
  }

  # force autoload ... umm, or something
  Gtk2::ListStore->can('insert_with_values');
  Gtk2::TreeStore->can('insert_with_values');

  { no warnings 'once';
    undef *Gtk2::ListStore::insert_with_values;
    undef *Gtk2::TreeStore::insert_with_values;
  }

  # check the desired effect ...
  foreach my $class ('Gtk2::ListStore', 'Gtk2::TreeStore') {
    if ($class->can('insert_with_values')) {
      die "Oops, $class->can(insert_with_values) still true";
    }
  }
  {
    my $store = Gtk2::ListStore->new ('Glib::String');
    if (eval { $store->insert_with_values(0, 0=>'foo'); 1 }) {
      die 'Oops, Gtk2::ListStore call store->insert_with_values() still succeeds';
    }
  }
  {
    my $store = Gtk2::TreeStore->new ('Glib::String');
    if (eval { $store->insert_with_values(undef, 0, 0=>'foo'); 1 }) {
      die 'Oops, Gtk2::TreeStore call store->insert_with_values() still succeeds';
    }
  }
}

sub without_blank_cursor {
  require Gtk2;
  if ($VERBOSE) {
    print STDERR "Test::Without::Gtk2Things: without CursorType blank-cursor, per Gtk before 2.16\n";
  }

  no warnings 'redefine', 'once';
  {
    my $orig = Glib::Type->can('list_values'); # force autoload
    *Glib::Type::list_values = sub {
      my ($class, $package) = @_;
      my @result = &$orig (@_);
      if ($package eq 'Gtk2::Gdk::CursorType') {
        @result = grep {$_->{'nick'} ne 'blank-cursor'} @result;
      }
      return @result;
    };
  }
  foreach my $func ('new', 'new_for_display') {
    my $orig = Gtk2::Gdk::Cursor->can($func); # force autoload
    my $new = sub {
      my $cursor_type = $_[-1];
      if ($cursor_type eq 'blank-cursor') {
        require Carp;
        Carp::croak ('Test::Without::Gtk2Things: no blank-cursor');
      }
      goto $orig;
    };
    my $func = "Gtk2::Gdk::Cursor::$func";
    no strict 'refs';
    *$func = $new;
  }

}

sub without_cell_layout_get_cells {
  require Gtk2;
  if ($VERBOSE) {
    print STDERR "Test::Without::Gtk2Things: without Gtk2::CellLayout get_cells() method, per Gtk before 2.12\n";
  }

  { no warnings 'once';
    undef *Gtk2::CellLayout::get_cells;
  }

  # check the desired effect ...
  foreach my $class ('Gtk2::CellView', 'Gtk2::TreeViewColumn',
                     'Gtk2::ComboBox') {
    if ($class->can('get_cells')) {
      die "Oops, $class->can(get_cells) still true";
    }
  }
}

sub without_warp_pointer {
  require Gtk2;
  if ($VERBOSE) {
    print STDERR "Test::Without::Gtk2Things: without Gtk2::Gdk::Display warp_pointer() method, per Gtk before 2.8\n";
  }

  { no warnings 'once';
    undef *Gtk2::Gdk::Display::warp_pointer;
  }

  # check the desired effect ...
  foreach my $class ('Gtk2::Gdk::Display') {
    if (my $coderef = $class->can('warp_pointer')) {
      die "Oops, $class->can(warp_pointer) still true: $coderef";
    }
  }
  if (Gtk2::Gdk::Display->can('get_default')) { # new in Gtk 2.2
    if (my $display = Gtk2::Gdk::Display->get_default) {
      if (my $coderef = $display->can('warp_pointer')) {
        die "Oops, display->can(warp_pointer) still true: $coderef";
      }
    }
  }
}

1;
__END__

=head1 NAME

Test::Without::Gtk2Things - disable selected Gtk2 methods for testing

=head1 SYNOPSIS

 # perl -MTest::Without::Gtk2Things=insert_with_values foo.t

 # or
 use Test::Without::Gtk2Things 'insert_with_values';

=head1 DESCRIPTION

This module removes or disables selected features from C<Gtk2> in order to
simulate an older version (or other restrictions).  It can be used for
development or testing to check code which adapts itself to available
features or which is meant to run on older Gtk.  There's only a couple of
"without" things as yet.

Obviously the best way to test application code on older Gtk is to run it on
an older Gtk, but making a full environment for that can be difficult.

=head2 Usage

From the command line use a C<-M> module load (per L<perlrun>) for a program
or test script,

    perl -MTest::Without::Gtk2Things=insert_with_values foo.t

Or the same through C<Test::Harness> in a C<MakeMaker> test run

    HARNESS_PERL_SWITCHES="-MTest::Without::Gtk2Things=blank_cursor" \
      make test

A test script can do the same with a C<use>,

    use Test::Without::Gtk2Things 'insert_with_values';

Or an equivalent explicit import,

    require Test::Without::Gtk2Things;
    Test::Without::Gtk2Things->import('insert_with_values');

In each case generally "withouts" should be established before loading
application code in case it checks features at C<BEGIN> time.

Currently C<Test::Without::Gtk2Things> loads C<Gtk2> if not already loaded.
(A mangle-after-load instead might be good, if it could be done reliably.)

=head1 WITHOUT THINGS

=over

=item C<verbose>

Have C<Test::Without::Gtk2Things> print some diagnostic messages to C<STDERR>.
For example,

    perl -MTest::Without::Gtk2Things=verbose,blank_cursor foo.t
    =>
    Test::Without::Gtk2Things: without CursorType blank-cursor, per Gtk before 2.16
    ...

=item C<insert_with_values>

Remove the C<insert_with_values> method from C<Gtk2::ListStore> and
C<Gtk2::TreeStore>.  That method is new in Gtk 2.6.  In earlier versions
separate C<insert> and C<set> calls are necessary.

=item C<blank_cursor>

Remove C<blank-cursor> from the C<Gtk2::Gdk::CursorType> enumeration.
Currently this means removing from C<< Glib::Type->list_values >>, and
making C<< Gtk2::Gdk::Cursor->new >> and C<new_for_display> throw an error
if asked for that type.

Object properties of type C<Gtk2::Gdk::CursorType> are are not affected
(they can still be set to C<blank-cursor>), but perhaps that could be done
in the future.  Blank cursors within Gtk itself are unaffected.

C<blank-cursor> is new in Gtk 2.16.  In earlier versions an invisible cursor
can be made by applications with a no-pixels-set bitmap as described by
C<gdk_cursor_new> in such earlier versions.  (See L<Gtk2::Ex::WidgetCursor>
for some help with that.)

=item C<cell_layout_get_cells>

Remove the C<get_cells> method from the C<Gtk2::CellLayout> interface.  That
interface method is new in Gtk 2.12 and removal affects all widget classes
implementing that interface.  In earlier Gtk versions C<Gtk2::CellView> and
C<Gtk2::TreeViewColumn> have individual C<get_cell_renderers> methods.
Those methods are unaffected by this without.

=back

=head1 SEE ALSO

L<Gtk2>,
L<Test::Without::Module>,
L<Test::Weaken::Gtk2>

=head1 COPYRIGHT

Copyright 2010 Kevin Ryde

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
