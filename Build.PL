# copied from RJBS, thanks! :)
exit 0 if $ENV{AUTOMATED_TESTING};

# Build.PL
use strict; use warnings;
use Module::Build;

# CPANPLUS stuff we need
use CPANPLUS::Backend;
use CPANPLUS::Configure;

# silence CPANPLUS!
{
	no warnings 'redefine';
	sub Log::Message::Handlers::cp_msg { return };
	sub Log::Message::Handlers::cp_error { return };
}

# Okay, get all the distributions that are POE :)
# init the backend ( and set some options )
my $conf = CPANPLUS::Configure->new;
$conf->set_conf( 'verbose' => 0 );
$conf->set_conf( 'no_update' => 1 );

# ARGH, CPANIDX doesn't work well with this kind of search...
if ( $conf->get_conf( 'source_engine' ) =~ /CPANIDX/ ) {
	warn "Disabling CPANIDX for CPANPLUS";
	$conf->set_conf( 'source_engine' => 'CPANPLUS::Internals::Source::Memory' );
}

# search for matching modules/packages
my $cb = CPANPLUS::Backend->new( $conf );
my @mods = $cb->search( 'type' => 'module', 'allow' => [ qr/^POEx?::/ ] );
warn "Found " . scalar @mods . " dists";

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

# we need a recent perl
$seen{'perl'} = '5.006';

my $build = Module::Build->new(
	# look up Module::Build::API for the info!
	'dynamic_config'	=> 0,
	'module_name'		=> 'Task::POE::All',
	'license'		=> 'perl',

	'dist_abstract'		=> 'Installs all of the modules in the POE::* namespace',
	'dist_author'		=> 'Apocalypse <APOCAL@cpan.org>',

	'create_packlist'	=> 1,
	'create_makefile_pl'	=> 'traditional',
	'create_readme'		=> 1,
	'create_license'	=> 1,
	'sign'			=> 0,

	'test_files'		=> 't/*.t',

	# To actually build!
	'configure_requires'	=> {
		'CPANPLUS'	=> '0.90',
	},

	# All of POE's deps, ahahaha
	'requires'		=> \%seen,
);

# all done!
$build->create_build_script;
