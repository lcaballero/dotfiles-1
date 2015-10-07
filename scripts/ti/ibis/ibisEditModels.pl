#!/usr/bin/perl
#===============================================================================
#
#         FILE:  ibisAddAttributes.pl
#
#        USAGE:  ./ibisAddAttributes.pl  
#
#  DESCRIPTION:  
#
#      OPTIONS:  ---
# REQUIREMENTS:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Gowtham M (A0393528), g-m@ti.com
#      COMPANY:  Texas Instruments, India
#      VERSION:  1.0
#      CREATED:  04/19/10 09:02:08
#     REVISION:  ---
#===============================================================================

use strict;
use warnings;

BEGIN
{
    use FindBin qw/ $Bin /;
    use File::Basename;

    my $dir = dirname $Bin;
    push @INC, (
         '/sp/turbochar/Gowtham/temporary_installations/IBIS_parser/latest',
         '/proj/cloc/Public/Patches/ldk_5.2.0/CUI_rhel40u4/overrides',
         '/apps/dad/ldk/lib/cui',
         '/apps/dad/ldk/tools/turbochar/integration/perlmods/Pyramid/Custom',
         $dir,
         );
}

use strict;
use warnings;
use Data::Dumper;
use CUI;
use IBIS;
use Clone qw/ clone /;

my %modelSpecAttributes = (
        D_OVERSHOOT_HIGH => 1,
        D_OVERSHOOT_LOW => 1,
        S_OVERSHOOT_HIGH => 1,
        S_OVERSHOOT_LOW => 1,
        D_OVERSHOOT_TIME => 1,
        );

my $inIbis = shift;
my $csv = shift;
my $newIbis = shift;

if( not defined $inIbis or
    not defined $csv or
    not defined $newIbis )
{
    usage();
    exit 1;
}

CUIinfo "Parsing CSV $csv ...";
my $csvHRef = parseCsv( $csv );
CUIinfo "Parsing IBIS file $inIbis ...";
my $ibis = new IBIS( $inIbis );
my $clonedIbis = clone $ibis;
addAttrs( $clonedIbis, $csvHRef );
CUIinfo "Writing new IBIS file $newIbis ...";
$clonedIbis->writeIbis( $newIbis );
exit CUIerrors;


sub addAttrs
{
    my ( $ibis, $hRef ) = @_;

    foreach my $modelName ( keys %{ $hRef || {} } )
    {
        print "  Model Name: $modelName\n";
        my @models;

        if( $modelName eq 'ALL' )
        {
            @models = $ibis->getAllIBISModels();
        }
        else
        {
            my $model = $ibis->getModel( $modelName );
            if( not defined $model )
            {
                CUIerr "Model $modelName not found in IBIS file";
                next;
            }
            @models = ( $modelName );
        }

        foreach my $model ( @models )
        {
            CUIinfo "Model $model";

            my $modelObj = $ibis->getModel( $model );
            if( not defined $modelObj )
            {
                CUIerr "Could not find model $model in the input ibis file";
                next;
            }

            my $modelSpecObj = $ibis->getKeywordGeneric( $model, 'model spec' );
            if( not defined $modelSpecObj )
            {
                CUIerr "Could not find [model spec] for $model in input ibis file";
                next;
            }
            foreach my $attr ( sort keys %{ $hRef->{$modelName} || {} } )
            {
                my $val = $hRef->{$modelName}{$attr};
                CUIinfo "\t$attr = $val";

                if( exists $modelSpecAttributes{ uc $attr } )
                {
                    push @{ $modelSpecObj->{stuff} }, "$attr $val\n";
                }
                else
                {
                    push @{ $modelObj->{stuff} }, "$attr $val\n";
                }
            }
        }
    }
}
sub parseCsv
{
    my $csv = shift;

    my %hash;

    my $CSV;

    unless( open $CSV, '<', $csv )
    {
        CUIfatal "Failed to read $csv : $!";
    }

    my $header = <$CSV>;
    chomp $header;

    my @header = split /\s*,\s*/, $header;

    foreach ( @header ) { s/"//g; }

    while( my $line = <$CSV> )
    {
        chomp $line;
        next if $line =~ m/^\s*$/;

        my @line = split /\s*,\s*/, $line;
        foreach ( @line ) { s/"//g; }

        if( scalar @line != scalar @header )
        {
            CUIerr "Invalid line [$line]\n";
            next;
        }
        my $model = $line[0];
        for( my $i = 1; $i < scalar @header; $i++ )
        {
            my $name = $header[$i];
            my $val = $line[$i];
            $hash{$model}{$name} = $val;
        }
    }
    close $CSV;
    return \%hash;
}

sub usage
{
    print "Script to add attributes to IBIS model.

Usage:

$0 <input ibis> <csv> <output ibis>

";
}
