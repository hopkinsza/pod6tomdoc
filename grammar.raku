#!/usr/bin/env raku
# vim: ft=perl6

grammar LOL {
	token TOP {
		<word> [<.ws> <word>]* <.ws>
	}
	token word {
		\w+
	}
}

my $x = "hello there pal ";
my $match = LOL.parse($x);

say $match;
