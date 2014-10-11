#!/usr/bin/perl

use strict;
use warnings;
use utf8;
use locale;
use autodie qw(:all);
use Template;
use Template::Stash;
use XML::Simple;
use File::Copy;
use File::Copy::Recursive qw(dircopy);
use File::Path qw(make_path);
use File::Basename;
use Locale::TextDomain ( 'ptable' ,  './locale/' );
use POSIX qw (setlocale LC_ALL LC_COLLATE);
use Locale::Messages qw (nl_putenv);
use Encode;
Locale::Messages->select_package ('gettext_pp');

$Template::Stash::ROOT_OPS->{ 'l' }    = sub {
	return decode('UTF-8', __(shift));
};

my $OUT = "app";

my @langs = get_langs();

my $xml = new XML::Simple;

my $categories = $xml->XMLin("src/xml/categories.xml");

my $groups = $xml->XMLin("src/xml/groups.xml");

my $periods = $xml->XMLin("src/xml/periods.xml");

my $state = $xml->XMLin("src/xml/state.xml");

my $appname = 'Periodic Table';

my $languages = $xml->XMLin("src/xml/languages.xml");

my @tableview = ();

my $version = '1.8';

my $t = Template->new({
		INCLUDE_PATH => 'src',
		ENCODING => 'utf8',
});

foreach my $lang (@langs){

	nl_putenv("LANGUAGE=$lang.UTF-8");
	nl_putenv("LANG=$lang.UTF-8");
	nl_putenv("LC_COLLATE=$lang");
	setlocale(LC_ALL, $lang.".UTF-8");
	setlocale(LC_COLLATE, $lang.".UTF-8");
	if( ! -d "$OUT/$lang" ){
		make_path("$OUT/$lang");
	}

	my $locappname = __($appname);
	my @elements;

	for my $category (@{$categories->{category}}){

		my $data = $xml->XMLin("src/xml/$category->{'filename'}.xml");
	  my @sorted = sort {$a->{anumber} <=> $b->{anumber}} @{$data->{element}};

		$t->process('category.html',
			{ 'elements' => [@sorted],
				'cur' => $category->{'filename'},
				'cur_l' => $category->{'fullname'},
				'title' => $locappname,
		  	'elementname' => "name_$lang",
				'categories' => $categories->{category}
			},
			"$OUT/$lang/$category->{'filename'}.html",
			{ binmode => ':utf8' }) or die $t->error;

		for my $element (@{$data->{element}}){
		 $element->{category} = $category;
		 $tableview["$element->{x}"]["$element->{y}"] = $element;
		 $t->process('element.html',
			 { 'element' => $element,
				 'elementname' => "name_$lang",
				 'state' => $state->{'state'},
				 'cur' => $category->{'filename'},
				 'cur_l' => $category->{'fullname'},
				 title => $locappname
			 },
			 "$OUT/$lang/".lc($element->{'name_Latin'}).".html",
			 { binmode => ':utf8' }) or die $t->error;

		 push(@elements,$element);
		}

	}

	my @sortedbyname = sort {$a->{"name_$lang"} cmp $b->{"name_$lang"}} @elements;
	my @sortedbyanumber = sort {$a->{anumber} <=> $b->{anumber}} @elements;
	my @sortedbyln = sort {$a->{name_Latin} cmp $b->{name_Latin}} @elements;
	my @sortedbyam = sort {$a->{atomicmass} =~ s/,/./r <=> $b->{atomicmass} =~ s/,/./r} @elements;

	for my $group (@{$groups->{group}}){

		$t->process('group.html',
			{ 'elements' => [@sortedbyanumber],
				'cur' => $group->{'filename'},
				'cur_l' => $group->{'fullname'},
				'title' => $locappname,
		  	'elementname' => "name_$lang",
				'groups' => $groups->{group}
			},
			"$OUT/$lang/$group->{'filename'}.html",
			{ binmode => ':utf8' }) or die $t->error;
	}

	$t->process('index-name.html',
		{ 'elements' => [@sortedbyname],
			'title' => $locappname,
		  'elementname' => "name_$lang",
			'nohomelink' => 'true'
		},
		"$OUT/$lang/index.html",
		{ binmode => ':utf8' }) or die $t->error;

	$t->process('index-an.html',
		{ 'elements' => [@sortedbyanumber],
			'title' => 'Atomic number',
		  'elementname' => "name_$lang",
		},
		"$OUT/$lang/index-an.html",
		{ binmode => ':utf8' }) or die $t->error;

	$t->process('index-ln.html',
		{ 'elements' => [@sortedbyln],
			'title' => 'Latin name',
		  'elementname' => "name_$lang",
		},
		"$OUT/$lang/index-ln.html",
		{ binmode => ':utf8' }) or die $t->error;

	$t->process('index-am.html',
		{ 'elements' => [@sortedbyam],
			'title' => 'Atomic mass',
		  'elementname' => "name_$lang",
		},
		"$OUT/$lang/index-am.html",
		{ binmode => ':utf8' }) or die $t->error;

	$t->process('menu.html',
		{
			'title' => 'Menu',
			'nomenulink' => 'true'
		},
		"$OUT/$lang/menu.html",
		{ binmode => ':utf8' }) or die $t->error;

	for my $period (@{$periods->{period}}){
		$t->process('period.html',
			{ 'elements' => [@sortedbyanumber],
				'periods' => $periods->{period},
				'period' => $period->{'number'},
		  	'elementname' => "name_$lang",
				'title' => $locappname
			},
			"$OUT/$lang/p$period->{'number'}.html",
			{ binmode => ':utf8' }) or die $t->error;
	}

	$t->process('period.html',
		{ 'periods' => $periods->{period},
			'title' => $locappname,
		  'elementname' => "name_$lang",
		},
		"$OUT/$lang/p.html",
		{ binmode => ':utf8' }) or die $t->error;

	$t->process('category.html',
		{	'title' => $locappname,
		  'elementname' => "name_$lang",
			'categories' => $categories->{category}
		},
		"$OUT/$lang/category.html",
		{ binmode => ':utf8' }) or die $t->error;

	$t->process('group.html',
		{	'title' => $locappname,
			'groups' => $groups->{group}
		},
		"$OUT/$lang/group.html",
		{ binmode => ':utf8' }) or die $t->error;

	$t->process('about.html',
		{	'title' => $locappname,
			'version' => $version,
		},
		"$OUT/$lang/about.html",
		{ binmode => ':utf8' }) or die $t->error;

	$t->process('mohs.html',
		{	'title' => 'Mohs scale',
		},
		"$OUT/$lang/mohs.html",
		{ binmode => ':utf8' }) or die $t->error;

	$t->process('language.html',
		{	'title' => 'Language',
			'languages' => $languages->{lang},
		},
		"$OUT/$lang/language.html",
		{ binmode => ':utf8' }) or die $t->error;

	$t->process('tableview.html',
		{	'title' => $locappname,
		  'elements' => [@tableview],
		},
		"$OUT/$lang/tableview.html",
		{ binmode => ':utf8' }) or die $t->error;
}

$t->process('index.html',
	{ 
			'languages' => $languages->{lang}
	},
	"$OUT/index.html",
	{ binmode => ':utf8' }) or die $t->error;

$t->process('index.js',
	{
			'languages' => $languages->{lang}
	},
	"$OUT/index.js",
	{ binmode => ':utf8' }) or die $t->error;

$t->process('tableview.js', {},
	"$OUT/tableview.js",
	{ binmode => ':utf8' }) or die $t->error;

$t->process('language.js',
	{
		'languages' => $languages->{lang},
	},
	"$OUT/language.js",
	{ binmode => ':utf8' }) or die $t->error;


$t->process('manifest.webapp',
	{ 
			'languages' => $languages->{lang},
			'version' => $version,
	},
	"$OUT/manifest.webapp",
	{ binmode => ':utf8' }) or die $t->error;

foreach my $dir (('css', 'img', 'font')){
	foreach my $file (glob("src/$dir/*")){
		my ($name,$path) = fileparse($file);
		copy("$path$name", "$OUT/$name");
	}
}

dircopy('app-icons', $OUT);

sub get_langs{
	my @langs = ();
	my @files = glob("po/*.po");
	foreach my $foo(@files){
		push(@langs, basename($foo, ('.po')));
	}
	return @langs;
}