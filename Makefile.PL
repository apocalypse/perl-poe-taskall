#!/usr/bin/perl

# Standard stuff to catch errors
use strict qw(subs vars refs);				# Make sure we can't mess up
use warnings FATAL => 'all';				# Enable warnings to catch errors

# CPANPLUS stuff we need
use CPANPLUS::Backend;
use CPANPLUS::Configure;

# Regular makefile stuff here
use ExtUtils::MakeMaker;

# Okay, get all the distributions that are POE :)
my $CPAN = CPANPLUS::Backend->new( CPANPLUS::Configure->new( 'conf' => { 'verbose' => 1 } ) );

my $search = $CPAN->search( 'type' => 'module', 'list' => [ "^POE::" ] );

# Okay, build the master list of packages to install
my %packages;
foreach my $module ( sort keys %$search ) {
	# Grab the package name
	my( $pkg, $ver ) = ( $search->{ $module }->package() =~ /^(.*?)-([0-9\.\_]+)(?:\.tar\.gz|\.tgz)$/ );

	# Skip malformed packages or whatnot
	if ( ! defined $pkg ) {
		print "[Bundle::POE::All] Skipping $module -> unable to parse it...\n";
		next;
	}

	# If it's POE, skip it :)
	if ( $pkg eq 'POE' ) { next }

	# Put this information in the master list
	if ( exists $packages{ $pkg } ) { next }
	$packages{ $pkg } = $search->{ $module };
}

# Now, write the All.pm
open( ALL, '>All.pm' ) or die( "Unable to overwrite All.pm - $!" );
print ALL "package Bundle::POE::All;\nuse vars qw( \$VERSION );\n\$VERSION = '1.02';\n1;\n__END__\n\n=head1 NAME\n\nBundle::POE::All - Installs all the modules in the POE::* namespace\n\n=head1 CONTENTS\n\n";

# Loop through the packages and add them to All.pm
foreach ( sort keys %packages ) {
	print ALL "$packages{ $_ }->{'module'}\n\n";
}

# Finish up All.pm
print ALL "=head1 AUTHOR\n\nApocalypse E<lt>apocal\@cpan.orgE<gt>\n\n=head1 COPYRIGHT AND LICENSE\n\nCopyright 2004 by Apocalypse\n\nThis library is free software; you can redistribute it and/or modify\nit under the same terms as Perl itself.\n\n=cut\n";

# Done!
close( ALL ) or die( "Unable to close All.pm - $!" );

# Write the makefile!
WriteMakefile(
	'NAME'		=> 'Bundle::POE::All',
	'VERSION_FROM'	=> 'All.pm', # finds $VERSION
);

# All done!
exit 0;
