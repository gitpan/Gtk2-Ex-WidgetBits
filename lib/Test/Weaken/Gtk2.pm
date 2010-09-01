# Copyright 2008, 2009, 2010 Kevin Ryde

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


package Test::Weaken::Gtk2;
use 5.006;  # for "our"
use strict;
use warnings;

# uncomment this to run the ### lines
#use Smart::Comments;

use Exporter;
our @ISA = ('Exporter');
our @EXPORT_OK = qw(contents_container
                    contents_submenu
                    destructor_destroy
                    destructor_destroy_and_iterate
                    ignore_default_display);

our $VERSION = 23;

sub contents_container {
  my ($ref) = @_;
  require Scalar::Util;
  if (Scalar::Util::blessed($ref)
      && $ref->isa('Gtk2::Container')) {
    return $ref->get_children;
  } else {
    return ();
  }
}

sub contents_submenu {
  my ($ref) = @_;
  require Scalar::Util;
  if (Scalar::Util::blessed($ref)
      && $ref->isa('Gtk2::MenuItem')) {
    return $ref->get_submenu;
  } else {
    return ();
  }
}

#------------------------------------------------------------------------------
sub destructor_destroy {
  my ($ref) = @_;
  if (ref($ref) eq 'ARRAY') {
    $ref = $ref->[0];
  }
  $ref->destroy;
}

sub destructor_destroy_and_iterate {
  my ($ref) = @_;
  destructor_destroy ($ref);
  _main_iterations();
}

# Gtk 2.16 can go into a hard loop on events_pending() / main_iteration_do()
# if dbus is not running, or something like that.  In any case limiting the
# iterations is good for test safety.
#
# FIXME: Not sure how aggressive to be on hitting the maximum count.  If
# testing can likely continue then a diagnostic is enough, but maybe a
# count-out means something too broken to continue.
#
# The iterations count actually run is cute to see to check what has gone
# through the main loop.  Would it be worth giving that always, or under an
# option, or something?
#
sub _main_iterations {
  require Test::More;
  my $count = 0;
  ### _main_iterations() ...
  while (Gtk2->events_pending) {
    $count++;
    Gtk2->main_iteration_do (0);

    if ($count >= 1000) {
      ### _main_iterations() count exceeded: $count
      eval {
        Test::More::diag ("main_iterations(): oops, bailed out after $count events/iterations");
      };
      return;
    }
  }
  ### _main_iterations() events/iterations: $count
}

#------------------------------------------------------------------------------
sub ignore_default_display {
  my ($ref) = @_;
  return (Gtk2::Gdk::Display->can('get_default') # if Gtk2 loaded
          && Gtk2::Gdk::Display->get_default     # if Gtk2 inited
          && ($ref == (Gtk2::Gdk::Display->get_default)));
}

#------------------------------------------------------------------------------
1;
__END__

=for stopwords destructors arrayref submenu MenuItem Destructor toplevel AccelLabel finalizations Ryde Gtk2-Ex-WidgetBits Gtk

=head1 NAME

Test::Weaken::Gtk2 -- Gtk2 helpers for Test::Weaken

=head1 SYNOPSIS

 use Test::Weaken::Gtk2;

=head1 DESCRIPTION

This is a few functions to help C<Test::Weaken> C<leaks()> on C<Gtk2>
widgets etc.  The functions can be used individually, or combined into
larger application-specific contents etc handlers.

This module doesn't load C<Gtk2>.  If C<Gtk2> is not loaded then the
functions simply return empty, false, or do nothing, as appropriate.  This
module also doesn't load C<Test::Weaken>, that's left to a test script.

=head1 FUNCTIONS

=head2 Contents Functions

=over 4

=item C<< @widgets = Test::Weaken::Gtk2::contents_container ($ref) >>

If C<$ref> is a C<Gtk2::Container> or subclass then return its widget
children per C<< $container->get_children >>.  If C<$ref> is not a
container, or C<Gtk2> is not loaded, then return an empty list.

The children of a container are held in C structures and are not otherwise
reached by the traversal C<Test::Weaken> does.

=item C<< @widgets = Test::Weaken::Gtk2::contents_submenu ($ref) >>

If C<$ref> is a C<Gtk2::MenuItem> (or subclass) and it has a submenu per
C<< $item->get_submenu >> then return that submenu.  If C<$ref> is not a
MenuItem, or it doesn't have a submenu, or C<Gtk2> is not loaded, then
return an empty list.

A submenu is held in the item's C structure and is not otherwise reached by
the traversal C<Test::Weaken> does.

=back

=head2 Destructor Functions

=over 4

=item C<< Test::Weaken::Gtk2::destructor_destroy ($top) >>

Call C<< $top->destroy >>, or if C<$top> is an arrayref then call C<destroy>
on its first element.  This can be used when a constructed widget or object
requires an explicit C<destroy>.  For example,

    my $leaks = leaks({
      constructor => sub { Gtk2::Window->new('toplevel') },
      destructor => \&Test::Weaken::Gtk2::destructor_destroy,
    });

The arrayref case is designed for multiple widgets etc returned from a
constructor, the first of which is a toplevel window or similar needing a
C<destroy>,

    my $leaks = leaks({
      constructor => sub {
        my $toplevel = Gtk2::Window->new('toplevel');
        my $label = Gtk2::Label->new('Hello World');
        $toplevel->add($label);
        return [ $toplevel, $label ];
      },
      destructor => \&Test::Weaken::Gtk2::destructor_destroy,
    });

All C<Gtk2::Object>s support C<destroy> but most don't need it for garbage
collection.  C<Gtk2::Window> is the most common which does.  Another is a
MenuItem which has an AccelLabel and is not in a menu (see notes in
L<Gtk2::MenuItem>).

=item C<< Test::Weaken::Gtk2::destructor_destroy_and_iterate ($top) >>

The same as C<destructor_destroy> above, but in addition run
C<< Gtk2->main_iteration_do >> for queued main loop actions.  There's a
limit on the number of iterations done, so as to protect against a runaway
main loop.

This is good if some finalizations are only done in an idle handler, or
perhaps under a timer which has now expired.  Currently queued events from
the X server are run, but there's no read or wait for further events.

=back

=head2 Ignore Functions

=over 4

=item C<< $bool = Test::Weaken::Gtk2::ignore_default_display ($ref) >>

Return true if C<$ref> is the default display
C<< Gtk2::Gdk::Display->get_default_display >>.

If C<Gtk2> is not loaded or C<< Gtk2->init >> has not been called then
there's no default display yet and this function returns false.

    my $leaks = leaks({
      constructor => sub { make_something },
      ignore => \&Test::Weaken::Gtk2::ignore_default_display,
    });

The default display is generally a permanent object, existing across a test,
and on that basis should not be tracked for leaking.  Usually the display
object is not seen by C<leaks> anyway, since it's only in the C structures
of a widget or window.  This function can be used if it might appear
elsewhere, such as a Perl code sub-object.

=back

=head1 EXPORTS

Nothing is exported by default, but the functions can be requested in usual
C<Exporter> style.

    use Test::Weaken::Gtk2 'contents_container';

There's no C<:all> tag since new functions are likely to be added in the
future and an import of all would run the risk of name clashes with
application functions etc.

=head1 SEE ALSO

L<Test::Weaken>, L<Gtk2::Container>, L<Gtk2::MenuItem>, L<Gtk2::Object>,
L<Gtk2::Window>, L<Gtk2::Gdk::Display>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/gtk2-ex-widgetbits/index.html>

=head1 LICENSE

Copyright 2008, 2009, 2010 Kevin Ryde

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
