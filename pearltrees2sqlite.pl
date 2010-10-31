#!/usr/bin/env perl

use warnings;
use strict;

package Bookmarks::Schema;
use base 'DBIx::Class::Schema';

__PACKAGE__->load_namespaces();

package Bookmarks::Schema::Result::Article;
use base 'DBIx::Class';

__PACKAGE__->load_components(qw/ Core /);
__PACKAGE__->table('article');

__PACKAGE__->add_columns(
    'artID' => {
        'data_type'         => 'bigint',
        'is_auto_increment' => 1,
        'default_value'     => undef,
        'is_foreign_key'    => 0,
        'name'              => 'artID',
        'is_nullable'       => 0,
        'size'              => '20'
    },
    'URL' => {
        'data_type'         => 'text',
        'is_auto_increment' => 0,
        'default_value'     => undef,
        'is_foreign_key'    => 0,
        'name'              => 'URL',
        'is_nullable'       => 0,
    },
    'Title' => {
        'data_type'         => 'text',
        'is_auto_increment' => 0,
        'default_value'     => undef,
        'is_foreign_key'    => 0,
        'name'              => 'Title',
        'is_nullable'       => 0,
    },
);

__PACKAGE__->set_primary_key( 'artID' );

package Bookmarks::Schema::Result::Tag;
use base 'DBIx::Class';

__PACKAGE__->load_components(qw/ Core /);
__PACKAGE__->table('tag');

__PACKAGE__->add_columns(
    'tagID' => {
        'data_type'         => 'bigint',
        'is_auto_increment' => 1,
        'default_value'     => undef,
        'is_foreign_key'    => 0,
        'name'              => 'tagID',
        'is_nullable'       => 0,
        'size'              => '20'
    },
    'Tag' => {
        'data_type'         => 'text',
        'is_auto_increment' => 0,
        'default_value'     => undef,
        'is_foreign_key'    => 0,
        'name'              => 'Tag',
        'is_nullable'       => 0,
    },
);

__PACKAGE__->set_primary_key( 'tagID' );

package Bookmarks::Schema::Result::TagLinks;
use base 'DBIx::Class';

__PACKAGE__->load_components(qw/ Core /);
__PACKAGE__->table('taglinks');

__PACKAGE__->add_columns(
    'tagID' => {
        'data_type'         => 'bigint',
        'is_auto_increment' => 0,
        'default_value'     => undef,
        'is_foreign_key'    => 0,
        'name'              => 'tagID',
        'is_nullable'       => 0,
        'size'              => '20'
    },
    'artID' => {
        'data_type'         => 'bigint',
        'is_auto_increment' => 0,
        'default_value'     => undef,
        'is_foreign_key'    => 1,
        'name'              => 'artID',
        'is_nullable'       => 0,
        'size'              => '20'
    },
);

package main;

use XML::LibXML;
use Data::Dump;

use Class::DBI;
use DBD::SQLite;
use LWP::Simple;
use Getopt::Long;
use Pod::Usage;

my $config = {
    input => './pearltrees.rdf',
    database => './bookmarks.db',
};

GetOptions( $config, 'input=s', 'database=s', 'help' ) or pod2usage(2);

pod2usage(1) if $config->{help};
pod2usage(1) if not exists $config->{input} and not exists $config->{database};

my $xml = XML::LibXML->new();
my $root = $xml->parse_file( $config->{input} )
  or die "Can't read file : $!\n";

my @ptrees = $root->getElementsByTagName('pt:tree');
my %ptree;

foreach my $ptree (@ptrees) {

    my @pturl = $ptree->getAttribute('rdf:about');
    foreach my $pturl (@pturl) {
        $pturl =~ s!^.*/(\d+)/!$1!;
    }

    my @ptname = $ptree->findvalue('dc:title');

    @ptree{@pturl} = @ptname;
}

my @pearls = $root->getElementsByTagName('pt:pearl');
my ( %pearl, %taggedpearl );

foreach my $pearl (@pearls) {
    my @title = $pearl->findvalue('dc:title');

    my @links = $pearl->getElementsByTagName('owl:sameAs');
    my @url;
    foreach my $link (@links) {
        @url = $link->getAttribute('rdf:resource');
    }

    my @parents = $pearl->getElementsByTagName('pt:parentTree');
    my @tag;
    foreach my $parent (@parents) {
        @tag = $parent->getAttribute('rdf:resource');
        foreach my $tag (@tag) {
            $tag =~ s!^.*/(\d+)/!$1!;
        }
    }
    @pearl{@url}       = @title;
    @taggedpearl{@url} = @tag;
}

my $deploy = -e $config->{database} ? 0 : 1;
my $schema = Bookmarks::Schema->connect( 'dbi:SQLite:dbname=' . $config->{database}, { AutoCommit => 1 } );
$schema->deploy() if $deploy;

my $i = 0;
my %sites;
foreach my $site ( keys(%pearl) ) {
    $i++;
    if ( $site =~ m!^http://www\.pearltrees\.com/.*$! ) { next; }

    elsif ( $site =~ m!^.*(\.pdf|\.asp|\.jpg|\.png)$! ) {
        my $addSite = Bookmarks::Article->insert(
            {
                artID => "$i",
                URL   => "$site",
                Title => "$pearl{$site}"
            }
        );
    }

    else {
        my $addSite = Bookmarks::Article->insert(
            {
                artID => "$i",
                URL   => "$site",
                Title => "$pearl{$site}"
            }
        );
        $sites{$i} = $site;
    }
}

# my $fts3 = DBI->connect( "dbi:SQLite:dbname=$dbfile", "", "" );
# $fts3->do(<<"") or die DBI::errstr;
# CREATE VIRTUAL TABLE webpage USING fts3 (pgContent TEXT, artID INTEGER NOT NULL REFERENCES article.artID)

# foreach my $artID ( keys(%sites) ) {
#     my $link = LWP::Simple::get("$sites{$artID}");
#     if ( defined($link) ) {
#         my $insert =
#           $fts3->prepare("INSERT INTO webpage(pgContent) VALUES (?)");
#         my $newdata  = $insert->execute($link);
#         my $insert2  = $fts3->prepare("INSERT INTO webpage(artID) VALUES (?)");
#         my $newdata2 = $insert2->execute($artID);
#     }
#     else {
#         open OUT, '>>', "error";
#         print( OUT "Error : Unable to reach $sites{$artID} \n" );
#         close(OUT);
#     }
# }

foreach my $tag ( sort keys(%ptree) ) {
    my $addTag = Bookmarks::Tag->insert(
        {
            tagID => "$tag",
            Tag   => "$ptree{$tag}"
        }
    );
}

$i = 0;
foreach my $taggedpearl ( keys(%taggedpearl) ) {
    $i++;
    my $addTagLink = Bookmarks::Taglinks->insert(
        {
            artID => "$i",
            tagID => "$taggedpearl{$taggedpearl}"
        }
    );
}

__END__

=pod

=head1 NAME

pearltrees2sqlite.pl - Perl script used to convert the export file from
www.pearltrees.com (pearltrees_export.rdf) into an SQLite database

=head1 SYNOPSIS

pearltrees2sqlite.pl --database bookmarks.db --input pearltrees_export.rdf [--help]

=cut
