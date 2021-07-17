unit class Pod::To::Mdoc;

method render($pod) {
    pod2mdoc($pod)
}

# lists must be sequential, e.g.:
# =item something
# =item2 something

my $iter = 0;
#my $defn-lvl = 0;

sub pod2mdoc($pod) is export {
    say "iteration $iter"; $iter++;
    my $ret = '';

    my $prev-listlvl = 0;

    my $start-list = True;
    if $prev-listlvl > 0 {
        if $pod ~~ Pod::Item {
            $start-list = False if $pod.level == $prev-listlvl
        } else {
            # end lists
            for 1..$prev-listlvl -> $i {
                $ret ~= ".El\n"
            }
        }
    }

    #if $list-lvl != 0 {
    #    if $pod ~~ Pod::Item {
    #    } else {
    #    }
    #}
    given $pod {
        when Positional             { .flat».&pod2mdoc.grep(?*).join('') }

        when Pod::Heading           { $ret ~ heading2mdoc $pod              }
        when Pod::Block::Code       { $ret ~    code2mdoc $pod              }
        when Pod::Block::Named      { $ret ~   named2mdoc $pod              }
        when Pod::Block::Para       { $ret ~    para2mdoc $pod              }
        #when Pod::Block::Table      { table2text($pod)               }
        #when Pod::Block::Declarator { declarator2text($pod)          }
        when Pod::Item {
            #my $prev-listlvl = 0;

            if $start-list {
                item2mdoc $pod, $prev-listlvl, $start-list
            } else {
                item2mdoc $pod, $prev-listlvl
            }
        }
        #when Pod::Defn              { pod2text($pod.contents[0]) ~ "\n"
        #                              ~ pod2text($pod.contents[1..*-1]) }

        when Pod::FormattingCode    { formatting2mdoc $pod           }
        when Pod::Block::Comment    { '' }
        #when Pod::Config            { '' }
        default                     { $pod.Str                       }
    }
}

sub heading2mdoc($pod) {
    given $pod.level {
        when 1  { '.Sh ' ~ pod2mdoc($pod.contents[0].contents) ~     "\n" }
        when 2  { '.Ss ' ~ pod2mdoc($pod.contents[0].contents) ~     "\n" }
        default { '\fB'  ~ pod2mdoc($pod.contents[0].contents) ~ "\\fP\n" }
    }
}

sub code2mdoc($pod) {
    #$pod.contents>>.&pod2mdoc.join.indent(4)
    ".Bd -literal -offset indent\n" ~ pod2mdoc($pod.contents) ~ "\n.Ed\n"
}

sub named2mdoc($pod) {
    given $pod.name {
        when 'pod'  { pod2mdoc $pod.contents }
        when 'para' { pod2mdoc $pod.contents }
        #when 'config' { }
        #when 'nested' { }
        default     { '.Sh ' ~ $pod.name ~ "\n" ~ pod2mdoc($pod.contents) }
    }
}

sub para2mdoc($pod) {
    ".Pp\n" ~ twrap( $pod.contents.map({pod2mdoc($_)}).join('') ) ~ "\n"
}

sub item2mdoc($pod, Int $prev-listlvl is rw, Bool $start-list=False) {
    my $ret = '';

    if $start-list {
        my $list-flags = ($pod.level % 2 == 1) ?? '-bullet' !! '-dash';
        $list-flags ~= ' -compact' if $pod.level > 1;

        $ret ~= ".Bl $list-flags\n";
    }

    $prev-listlvl = $pod.level;
    $ret ~= ".It\n" ~ pod2mdoc($pod.contents[0].contents) ~
        "\n" ~ pod2mdoc($pod.contents[1..*-1]);
    #('* ' ~ pod2mdoc($pod.contents).chomp.chomp).indent(2 * $pod.level)
}

#`{
sub para2text($pod) {
    twine2text($pod.contents)
}

sub table2text($pod) {
    my @rows = $pod.contents;
    @rows.unshift($pod.headers.item) if $pod.headers;
    my @maxes;
    my $cols = [max] @rows.map({ .elems });
    for ^$cols -> $i {
        @maxes.push([max] @rows.map({ $i < $_ ?? $_[$i].chars !! 0 }));
    }
    @maxes[*-1] = 0;  # Don't pad last column with spaces
    my $ret;
    if $pod.config<caption> {
        $ret = $pod.config<caption> ~ "\n"
    }
    for @rows -> $row {
        # Gutter of two spaces between columns
        $ret ~= '  ' ~ join '  ',
            (@maxes Z=> @$row).map: { .value.fmt("%-{.key}s") };
        $ret ~= "\n";
    }
    $ret
}

sub declarator2text($pod) {
    next unless $pod.WHEREFORE.WHY;
    my $what = do given $pod.WHEREFORE {
        when Method {
            my @params=$_.signature.params[1..*];
              @params.pop if @params.tail.name eq '%_';
              'method ' ~ $_.name ~ signature2text(@params, $_.returns)
        }
        when Sub {
            'sub ' ~ $_.name ~ signature2text($_.signature.params, $_.returns)
        }
        when Attribute {
            'attribute ' ~ $_.gist
        }
        when .HOW ~~ Metamodel::EnumHOW {
            "enum $_.raku() { signature2text $_.enums.pairs } \n"
        }
        when .HOW ~~ Metamodel::ClassHOW {
            'class ' ~ $_.raku
        }
        when .HOW ~~ Metamodel::ModuleHOW {
            'module ' ~ $_.raku
        }
        when .HOW ~~ Metamodel::SubsetHOW {
            'subset ' ~ $_.raku ~ ' of ' ~ $_.^refinee().raku
        }
        when .HOW ~~ Metamodel::PackageHOW {
            'package ' ~ $_.raku
        }
        default {
            ''
        }
    }
    "$what\n{$pod.WHEREFORE.WHY.contents}"
}

sub signature2text($params, Mu $returns?) {
    my $result = '(';

    if $params.elems {
        $result ~= "\n\t" ~ $params.map(&param2text).join("\n\t")
    }
    unless $returns<> =:= Mu {
        $result ~= "\n\t--> " ~ $returns.raku
    }
    if $result.chars > 1 {
        $result ~= "\n";
    }
    $result ~= ')';
    return $result;
}

sub param2text($p) {
    $p.raku ~ ',' ~ ( $p.WHY ?? ' # ' ~ $p.WHY !! ' ')
}

my %formats =
  C => "bold",
  L => "underline",
  D => "underline",
  R => "inverse"
;

sub twine2text($_) {
    .map({ when Pod::Block { twine2text .contents }; .&pod2text }).join
}
}

sub formatting2mdoc($pod) {
    my $text = $pod.contents>>.&pod2mdoc.join;
    given $pod.type {
        when 'I' { '\fI'   ~ $text ~ '\fP' }
        when 'C' { '\f(CW' ~ $text ~ '\fP' }
        default  { $text }
    }
}

sub twrap($text is copy, :$wrap=75 ) {
    $text ~~ s:g/(. ** {$wrap} <[\s]>*)\s+/$0\n/;
    $text
}

# vim: syntax=perl
# vim: expandtab shiftwidth=4
