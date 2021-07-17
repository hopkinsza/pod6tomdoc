#!/usr/bin/env raku
# vim: ft=perl6

#| The thing
class Thing {
	has $.a = "^ ^";
	has $.b = ". .";
}
#= Is a thing

#| lol sub as in submarine
sub bap(Thing $a, Thing $b) {
}
#= not accurate

#say Thing.WHY;
#say Thing.WHY.leading;
#say Thing.WHY.trailing;
#say &bap.WHY;
#say &bap.WHY.leading;
#say &bap.WHY.trailing;

my $t = Thing.new;

say "{$t.a} lol"
