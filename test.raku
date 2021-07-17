#!/usr/bin/env raku
# vim: ft=perl6

use lib 'lib';
use Pod::To::Mdoc;
#use Pod::To::Man;

=begin pod

=NAME
test -- do something

=DESCRIPTION

Paragraph with I<italic text>.

Another para.

=head2 Subsection

Subsection text.

=head2 A list:

=item item
=item2 item2
=item2 item2
=item3 item3
=item item

=begin item
Bullet with

Some text embedded inside it.

=end item

=begin para
A paragraph using =begin para.

Which can include more text.

=item and embedded bullet points
=end para

=defn -a
alpha

=defn -b
bravo

=end pod

for $=pod -> $pod-item {
	say '* ' ~ $pod-item.raku;
	for $pod-item.contents -> $pod-block {
		say '**** ' ~ $pod-block.raku
	}
}
say '';
say '********';
say '';

say pod2mdoc($=pod);

#say '**** pod2man:';
#say Pod::To::Man.render($=pod);
