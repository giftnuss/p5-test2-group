use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Test2::Group',
    license             => 'perl',
    dist_author         => q{Sebastian Knapp <sknpp@cpan.org>},
    dist_version_from   => 'lib/Test2/Group.pm',
    configure_requires => {
	'Module::Build' => 0.4 
    },
    build_requires => {
        'Test::More' => 0,
	'Test::Cmd' => 0,
	'Module::Build' => '0.40'
    },
    requires => {
        'perl' => 5.006,
	'Test2::API' => 0
    },
    add_to_cleanup      => [ 'Test2-Group-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
