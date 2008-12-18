# copied from RJBS, thanks! :)
exit 0 if $ENV{AUTOMATED_TESTING};

# Build.PL
use Module::Build;
use strict;
use warnings;

# CPANPLUS stuff we need
use CPANPLUS::Backend;
use CPANPLUS::Configure;

# Okay, get all the distributions that are POE :)
# init the backend ( and set some options )
my $conf = CPANPLUS::Configure->new;
$conf->set_conf( 'verbose' => 0 );
$conf->set_conf( 'no_update' => 1 );
my $cb = CPANPLUS::Backend->new( $conf );

# search for matching modules/packages
my @mods = $cb->search( 'type' => 'module', 'allow' => [ qr/^POE::/ ] );

# collate the data
my %seen;
foreach my $m ( @mods ) {
	# is the module version == package version?
	if ( $m->version eq $m->package_version ) {
		$seen{ $m->package_name } = $m;
		next;
	}

	# is the module name == package name?
	my $pkg = $m->package_name; $pkg =~ s/-/::/g;
	if ( $m->name eq $pkg ) {
		$seen{ $m->package_name } = $m;
		next;
	}

	if ( exists $seen{ $m->package_name } ) {
		# is this module "shorter" in length?
		if ( length( $seen{ $m->package_name }->module ) > length( $m->module ) ) {
			# do a sane version compare
			if ( $cb->_vcmp( $m->version, 0 ) ) {
				$seen{ $m->package_name } = $m;
			}
		}
	} else {
		# first hit!
		$seen{ $m->package_name } = $m;
	}
}

# invert the sense of the hash to prepare for prereq
%seen = map { $_->module => $_->version } values %seen;

my $build = Module::Build->new(
	# look up Module::Build::API for the info!
	'dynamic_config'	=> 0,
	'module_name'		=> 'Task::POE::All',
	'license'		=> 'perl',

	'dist_abstract'		=> 'Installs all of the modules in the POE::* namespace',
	'dist_author'		=> 'Apocalypse <APOCAL@cpan.org>',

	'create_packlist'	=> 1,
	'create_readme'		=> 1,

	'test_files'		=> 't/*.t',

	'add_to_cleanup'	=> [ 'META.yml', 'README' ],	# automatically generated

	# FIXME this throws a warning, but is harmless
	'configure_requires'	=> {
		'Module::Build'		=> 0,
		'CPANPLUS'		=> '0.84',
	},

	'requires'		=> \%seen,
);

# all done!
$build->create_build_script;
