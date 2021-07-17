#!/usr/bin/env raku
# vim: ft=perl6

=begin pod

=head1 Head1 I<thing>

A paragraph C<with code>.

Another para.

=head2 Subsection

Sub text.

=head3 Head3

Head3 text.

A list:

=item item
=item2 item2
=item2 item2

=item another item

=begin item
item with

some text.
=end item

=end pod

#say 'ENTIRE POD: ' ~ $=pod.raku;
#say '********';
for $=pod -> $pod-item {
	#say '* ' ~ $pod-item.raku;
	for $pod-item.contents -> $pod-block {
		say '* ' ~ $pod-block.raku
	}
}
