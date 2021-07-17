#!/usr/bin/env raku
# vim: ft=perl6

grammar LINE {
	rule TOP {
		[ <quoted> | <unquoted> ]+
	}
	token quoted {
		[ '"' ] .* [ '"' ]
	}
	token unquoted {
		\w
	}
}


my $match = LINE.parse('hello "there pal"');
say $match<TOP>;

exit 0;

=pod

my Str $in = '';

while $in ne 'exit' {
	print '[', %*ENV<PWD>, ']$ ';

	$in = prompt;

	$in = 
	say '$in is: ', qqww/$in/.raku;
	put "***";


	exit 0;
	run qqww/$in/;
}

=cut

# grammar URL {
# 	token TOP {
# 		<schema> '://' 
# 		[ <ip> | <hostname> ]
# 		[ ':' <port> ]?
# 		[ '/' <path> ]?
# 		'/'?
# 	}
# 	token decbyte {
# 		(\d**1..3) <?{ $0 < 256 }>
# 	}
# 	token ip {
# 		<decbyte> [\. <decbyte> ] ** 3
# 	}
# 	token schema {
# 		\w+
# 	}
# 	token hostname {
# 		(\w+) ( \. \w+ )*
# 	}
# 	token port {
# 		\d+
# 	}
# 	token path {
# 		<[ a..z A..Z 0..9 \-_.!~*'():@&=+$,/ ]>+
# 	}
# }
# 
# my $match = URL.parse('http://perl6.org/documentation/');
# #my $match = URL.parse('http://perl6.org/');
# 
# say "schema:   ", $match<schema>;
# say "ip:       ", $match<ip>;
# say "hostname: ", $match<hostname>;
# say "port:     ", $match<port>;
# say "path:     ", $match<path>;
