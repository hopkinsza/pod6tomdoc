# vim: ft=perl6 tabstop=4 shiftwidth=4

unit class Pod::To::Mdoc;

method render(Positional $pod) {
	pod2mdoc($pod)
}

sub check-NAME(Pod::Block::Named $pod) {
	if $pod.contents.elems != 1 {
		die 'NAME should contain exactly 1 line';
	}
	if !$pod.contents[0].contents.join.grep(/\s*'--'\s*/) {
		die 'NAME line improperly formatted';
	}
}
sub check-meta(Pod::Block::Named $pod) {
	if $pod.contents.elems != 0 {
		die 'meta should not contain any lines';
	}
}

#| Array of Pod values to mdoc. typical usage: pod2mdoc($=pod)
sub pod2mdoc(Positional $pod) is export {

	my $ret = '';

	#
	# check first block
	#
	my $first = $pod[0].contents[0];
	my $e = 'First thingy is not a Pod::Block::Named with name=>NAME or name=>meta';
	if $first !~~ Pod::Block::Named {
		die $e;
	}

	given $first.name {
		when 'NAME' {
			check-NAME($first);

			my @arr = $first.contents[0].contents[0].split(/\s*'--'\s*/);

			$ret = '.Dd $Mdocdate$'      ~ "\n";
			$ret ~= ".Dt {@arr[0].uc} 1" ~ "\n";
			$ret ~= ".Os"                ~ "\n";
			$ret ~= ".Sh NAME"           ~ "\n";
			$ret ~= ".Nm {@arr[0]}"      ~ "\n";
			$ret ~= ".Nd {@arr[1]}"      ~ "\n";

			# delete element
			$pod[0].contents.splice(0, 1);
		}
		when 'meta' {
			die 'name=>meta not yet implemented';
			check-meta($first);
		}
		default {
			die $e;
		}
	}

	# $prev-listlvl is a number. TODO add something to tell if it was a defn list
	my $prev-listlvl = 0;
	for $pod -> $rpod {
		$ret ~= rpod2mdoc($rpod, $prev-listlvl);
	}
	return $ret;
}

#| real Pod to mdoc
sub rpod2mdoc($pod, $prev-listlvl is rw) {
	my $ret = '';
	my Bool $begin-list = True;

	# end lists if necessary
	if $prev-listlvl > 0 {
		#
		# end all lists if we're not an item
		#
		if $pod !~~ Pod::Item {
			for 1..$prev-listlvl {
				$ret ~= ".El\n";
			}
		}
		#
		# otherwise...
		#
		elsif $pod.level == $prev-listlvl {
			# continue adding to the same list
			$begin-list = False;
		}
		elsif $pod.level > $prev-listlvl {
			# begin a new list
			$begin-list = True;
			if $prev-listlvl - $pod.level > 1 {
				die 'Skipping =item levels unsupported; ' ~
				"level $prev-listlvl -> {$pod.level} requested";
			}
		}
		else {
			# close as many as needed
			$begin-list = False;
			for 1..($prev-listlvl - $pod.level) {
				$ret ~= ".El\n";
			}
		}
	}

	given $pod {
		when Positional				{ $ret ~= $pod.flat>>.&rpod2mdoc($prev-listlvl).join }
		when Pod::Heading			{ $ret ~= heading2mdoc $pod }
		when Pod::Block::Code		{ $ret ~=	 code2mdoc $pod }
		when Pod::Block::Named		{ $ret ~=	named2mdoc $pod }
		when Pod::Block::Para		{ $ret ~=	 para2mdoc $pod }
		#when Pod::Block::Table		 { table2text($pod)				  }
		#when Pod::Block::Declarator { declarator2text($pod)		  }
		when Pod::Item {
				$ret ~= item2mdoc $pod, $prev-listlvl, $begin-list
		}
		#when Pod::Defn				 { pod2text($pod.contents[0]) ~ "\n"
		#							   ~ pod2text($pod.contents[1..*-1]) }

		when Pod::FormattingCode	{ $ret ~= formatting2mdoc $pod				   }
		when Pod::Block::Comment	{ return '' }
		#when Pod::Config			 { '' }
		default						{ return $pod.Str						}
	}

	return $ret;
}

sub heading2mdoc($pod) {
	my $prev-listlvl = 0;
	given $pod.level {
		when 1	{ '.Sh ' ~ rpod2mdoc($pod.contents[0].contents, $prev-listlvl) ~     "\n" }
		when 2	{ '.Ss ' ~ rpod2mdoc($pod.contents[0].contents, $prev-listlvl) ~     "\n" }
		default { '\fB'	 ~ rpod2mdoc($pod.contents[0].contents, $prev-listlvl) ~ "\\fP\n" }
	}
}

sub code2mdoc($pod) {
	#$pod.contents>>.&pod2mdoc.join.indent(4)
	".Bd -literal -offset indent\n" ~ $pod.contents ~ "\n.Ed\n"
}

sub named2mdoc($pod) {
	my $prev-listlvl = 0;
	given $pod.name {
		when 'pod'	{ rpod2mdoc($pod.contents, $prev-listlvl) }
		when 'para' { rpod2mdoc($pod.contents, $prev-listlvl) }
		#when 'config' { }
		#when 'nested' { }
		default		{ '.Sh ' ~ $pod.name ~ "\n" ~ rpod2mdoc($pod.contents, $prev-listlvl) }
	}
}

sub para2mdoc($pod) {
	my $prev-listlvl = 0;
	".Pp\n" ~ rpod2mdoc($pod.contents, $prev-listlvl) ~ "\n"
}

sub item2mdoc($pod, $prev-listlvl is rw, Bool $begin-list=False) {
	my $ret = '';

	if $begin-list {
		my $list-flags = ($pod.level % 2 == 1) ?? '-bullet' !! '-dash';
		$list-flags ~= ' -compact' if $pod.level > 1;

		$ret ~= ".Bl $list-flags\n";
	}

	$prev-listlvl = $pod.level;
	my $tmp = 0;
	$ret ~= ".It\n" ~ rpod2mdoc($pod.contents[0].contents, $tmp) ~
		"\n" ~ rpod2mdoc($pod.contents[1..*-1], $tmp);
	return $ret;
}

sub formatting2mdoc($pod) {
	my $text = $pod.contents.join;
	given $pod.type {
		when 'I' { '\fI'   ~ $text ~ '\fP' }
		when 'C' { '\f(CW' ~ $text ~ '\fP' }
		default	 { $text }
	}
}
