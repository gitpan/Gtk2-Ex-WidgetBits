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

our $VERSION = 30;

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
      "Test::Without::Gtk2Things -- count without $count thing",
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

#------------------------------------------------------------------------------
# withouts

sub without_insert_with_values {
  require Gtk2;
  if ($VERBOSE) {
    print STDERR "Test::Without::Gtk2Things -- without ListStore,TreeStore insert_with_values(), per Gtk before 2.6\n";
  }

  _without_methods ('Gtk2::ListStore', 'insert_with_values');
  _without_methods ('Gtk2::TreeStore', 'insert_with_values');

  # check the desired effect ...
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
    print STDERR "Test::Without::Gtk2Things -- without CursorType blank-cursor, per Gtk before 2.16\n";
  }

  no warnings 'redefine', 'once';
  {
    my $orig = Glib::Type->can('list_values');
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
    my $orig = Gtk2::Gdk::Cursor->can($func);
    my $new = sub {
      my $cursor_type = $_[-1];
      if ($cursor_type eq 'blank-cursor') {
        require Carp;
        Carp::croak ('Test::Without::Gtk2Things -- no blank-cursor');
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
    print STDERR "Test::Without::Gtk2Things -- without Gtk2::CellLayout get_cells() method, per Gtk before 2.12\n";
  }

  _without_methods ('Gtk2::CellLayout', 'get_cells');
}

sub without_menuitem_label_property {
  require Gtk2;
  if ($VERBOSE) {
    print STDERR "Test::Without::Gtk2Things -- without Gtk2::MenuItem label and use-underline properties, per Gtk before 2.16\n";
  }
  _without_properties ('Gtk2::MenuItem', 'label', 'use-underline');

  # check the desired effect ...
  {
    if (eval { Gtk2::MenuItem->Glib::Object::new (label => 'hello') }) {
      die 'Oops, Gtk2::MenuItem create with Glib::Object::new and label still succeeds';
    }
    if (eval { Gtk2::MenuItem->Glib::Object::new ('use-underline' => 1) }) {
      die 'Oops, Gtk2::MenuItem create with Glib::Object::new and use-underline still succeeds';
    }
  }
}

sub without_warp_pointer {
  require Gtk2;
  if ($VERBOSE) {
    print STDERR "Test::Without::Gtk2Things -- without Gtk2::Gdk::Display warp_pointer() method, per Gtk before 2.8\n";
  }

  _without_methods ('Gtk2::Gdk::Display', 'warp_pointer');

  # check the desired effect ...
  if (Gtk2::Gdk::Display->can('get_default')) { # new in Gtk 2.2
    if (my $display = Gtk2::Gdk::Display->get_default) {
      if (my $coderef = $display->can('warp_pointer')) {
        die "Oops, display->can(warp_pointer) still true: $coderef";
      }
    }
  }
}

sub without_widget_tooltip {
  require Gtk2;
  if ($VERBOSE) {
    print STDERR "Test::Without::Gtk2Things -- without Gtk2::Widget tooltips, per Gtk before 2.12\n";
  }
  _without_properties ('Gtk2::Widget',
                       'tooltip-text', 'tooltip-markup', 'has-tooltip');
  _without_methods ('Gtk2::Widget',
                    'get_tooltip_text', 'set_tooltip_text',
                    'get_tooltip_markup', 'set_tooltip_markup',
                    'get_has_tooltip', 'set_has_tooltip',);
  _without_signals ('Gtk2::Widget', 'query-tooltip');
}

sub without_EXPERIMENTAL_GdkDisplay {
  require Gtk2;
  if ($VERBOSE) {
    print STDERR "Test::Without::Gtk2Things -- without Gdk2::Gdk::Display, per Gtk 2.0.x\n";
  }
  _without_methods ('Gtk2::Widget', 'get_display', 'get_screen');
  _without_methods ('Gtk2::Gdk::Cursor', 'new_for_display');
  _without_packages ('Gtk2::Gdk::Display', 'Gtk2::Gdk::Screen');

  # check the desired effect ...
  if (my $coderef = Gtk2::Gdk::Display->can('get_default')) {
    die "Oops, Gtk2::Gdk::Display->can(get_default) still true: $coderef";
  }
  if (my $coderef = Gtk2::Gdk::Screen->can('get_display')) {
    die "Oops, Gtk2::Gdk::Screen->can(get_display) still true: $coderef";
  }
}

#------------------------------------------------------------------------------
# removing stuff

sub _without_packages {
  foreach my $package (@_) {
    $package->can('something'); # finish lazy loading, or some such
    no strict 'refs';
    foreach my $name (%{"${package}::"}) {
      my $fullname = "${package}::$name";
      undef *$fullname;
    }
  }
}

sub _without_methods {
  my $class = shift;
  foreach my $method (@_) {
    # force autoload ... umm, or something
    $class->can($method);

    my $fullname = "${class}::$method";
    { no strict 'refs'; undef *$fullname; }
  }

  # check the desired effect ...
  foreach my $method (@_) {
    if (my $coderef = $class->can($method)) {
      die "Oops, $class->can($method) still true: $coderef";
    }
  }
}

sub _without_properties {
  my ($without_class, @without_pnames) = @_;

  foreach my $without_pname (@without_pnames) {
    (my $method = $without_pname) =~ tr/-/_/;
    _without_methods ('Gtk2::Widget', 'get_$method', 'set_$method');
  }

  my %without_pnames;
  @without_pnames{@without_pnames} = (1) x scalar(@without_pnames); # slice

  no warnings 'redefine', 'once';
  {
    my $orig = Glib::Object->can('list_properties');
    *Glib::Object::list_properties = sub {
      my ($class) = @_;
      if ($class->isa($without_class)) {
        return grep {! $without_pnames{$_->get_name}} &$orig (@_);
      }
      goto $orig;
    };
  }
  {
    my $orig = Glib::Object->can('find_property');
    *Glib::Object::find_property = sub {
      my ($class, $pname) = @_;
      if ($class->isa($without_class)
          && _pnames_match ($pname, \%without_pnames)) {
        ### wrapped find_property() exclude
        return undef;
      }
      goto $orig;
    };
  }
  foreach my $func ('get', 'get_property') {
    my $orig = Glib::Object->can($func);
    my $new = sub {
      if ($_[0]->isa($without_class)) {
        for (my $i = 1; $i < @_; $i++) {
          my $pname = $_[$i];
          if (_pnames_match ($pname, \%without_pnames)) {
            require Carp;
            Carp::croak ("Test-Without-Gtk2Things: no get property $pname");
          }
        }
      }
      goto $orig;
    };
    my $func = "Glib::Object::$func";
    no strict 'refs';
    *$func = $new;
  }
  foreach my $func ('new', 'set', 'set_property') {
    my $orig = Glib::Object->can($func); # force autoload
    my $new = sub {
      if ($_[0]->isa($without_class)) {
        for (my $i = 1; $i < @_; $i += 2) {
          my $pname = $_[$i];
          if (_pnames_match ($pname, \%without_pnames)) {
            require Carp;
            Carp::croak ("Test-Without-Gtk2Things: no set property $pname");
          }
        }
      }
      goto $orig;
    };
    my $func = "Glib::Object::$func";
    no strict 'refs';
    *$func = $new;
  }


  # check the desired effect ...
  foreach my $without_pname (@without_pnames) {
    if (my $pspec = $without_class->find_property($without_pname)) {
      die "Oops, $without_class->find_property() still finds $without_pname: $pspec";
    }
    if (my @pspecs = grep {$_->get_name eq $without_pname}
        $without_class->list_properties) {
      local $, = ' ';
      die "Oops, $without_class->list_properties() still finds $without_pname: @pspecs";
    }
  }
}

sub _pnames_match {
  my ($pname, $without_pnames) = @_;
  ### $want
  ### $pname
  $pname =~ tr/_/-/;
  return $without_pnames->{$pname};
}

sub _without_signals {
  my ($without_class, @without_signames) = @_;

  my %without_signames;
  @without_signames{@without_signames} # hash slice
    = (1) x scalar(@without_signames);

  no warnings 'redefine', 'once';
  {
    require Glib;
    my $orig = Glib::Type->can('list_signals');
    *Glib::Type::list_signals = sub {
      my (undef, $list_class) = @_;
      if ($list_class->isa($without_class)) {
        return grep {! $without_signames{$_->{'signal_name'}}} &$orig (@_);
      }
      goto $orig;
    };
  }
  {
    my $orig = Glib::Object->can('signal_query');
    *Glib::Object::signal_query = sub {
      my ($class, $signame) = @_;
      if ($class->isa($without_class)
          && _pnames_match ($signame, \%without_signames)) {
        ### wrapped signal_query() exclude
        return undef;
      }
      goto $orig;
    };
  }
  foreach my $func ('signal_connect',
                    'signal_connect_after',
                    'signal_connect_swapped',
                    'signal_emit',
                    'signal_add_emission_hook',
                    'signal_remove_emission_hook',
                    'signal_stop_emission_by_name') {
    my $orig = Glib::Object->can($func);
    my $new = sub {
      my ($obj, $signame) = @_;
      if ($obj->isa($without_class)) {
        if (_pnames_match ($signame, \%without_signames)) {
          require Carp;
          Carp::croak ("Test-Without-Gtk2Things: no signal $signame");
        }
      }
      goto $orig;
    };
    my $func = "Glib::Object::$func";
    no strict 'refs';
    *$func = $new;
  }


  # check the desired effect ...
  foreach my $without_signame (@without_signames) {
    if (my $siginfo = $without_class->signal_query($without_signame)) {
      die "Oops, $without_class->signal_query() still finds $without_signame: $siginfo";
    }
    if (my @siginfos = grep {$_->{'signal_name'} eq $without_signame}
        Glib::Type->list_signals($without_class)) {
      local $, = ' ';
      die "Oops, Glib::Type->list_signals($without_class) still finds $without_signame: @siginfos";
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

In each case generally the "withouts" should be established before loading
application code in case it checks features at C<BEGIN> time.

Currently C<Test::Without::Gtk2Things> loads C<Gtk2> if not already loaded,
but don't rely on that.  A mangle-after-load instead might be good, if it
could be done reliably.

=head1 WITHOUT THINGS

=over

=item C<verbose>

Have C<Test::Without::Gtk2Things> print some diagnostic messages to C<STDERR>.
For example,

    perl -MTest::Without::Gtk2Things=verbose,blank_cursor foo.t
    =>
    Test::Without::Gtk2Things -- without CursorType blank-cursor, per Gtk before 2.16
    ...

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

=item C<insert_with_values>

Remove the C<insert_with_values> method from C<Gtk2::ListStore> and
C<Gtk2::TreeStore>.  That method is new in Gtk 2.6.  In earlier versions
separate C<insert> and C<set> calls are necessary.

=item C<menuitem_label_property>

Remove from C<Gtk2::MenuItem> C<label> and C<use-underline> properties and
corresponding explicit C<get_label>, C<set_use_underline> etc methods.

C<label> and C<use-underline> are new in Gtk 2.16.  (For prior versions
C<new_with_label> or C<new_with_mnemonic> create and set a child label
widget.)

=item C<widget_tooltip>

Remove from C<Gtk2::Widget> base tooltip support new in Gtk 2.12.  This
means the C<tooltip-text>, C<tooltip-markup> and C<has-tooltip> properties,
their direct get/set methods such as C<< $widget->set_tooltip_text >>, and
the C<query-tooltip> signal.

For code supporting both earlier and later than 2.12 it may be enough to
just skip the tooltip setups for the earlier versions.  See
C<set_property_maybe> in L<Glib::Ex::ObjectBits> for some help with that.

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
