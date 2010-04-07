#!/usr/bin/perl
use strict; use warnings;

use Test::More;
eval "use Test::Apocalypse 0.10";
if ( $@ ) {
	plan skip_all => 'Test::Apocalypse required for validating the distribution';
} else {
	require Test::NoWarnings; require Test::Pod; require Test::Pod::Coverage;	# lousy hack for kwalitee

	# Obviously, we disable the prereq checks because this is a fake module, ha!
	is_apocalypse_here( {
		deny => qr/ModuleUsed|Dependencies/,
	} );
}
