#!/usr/local/bin/perl

use strict;
use warnings;
use Getopt::Std;

#
# Name:        intersect_gene_lists.pl
#
# Purpose:     Takes two output lists of counts from htseq. The output
#              is two lists that contain only the counts that intersect
#              the two lists.  Sometimes gene_ids are different between 
#              reference genomes (ex. BRCA1 between hg19 and hg38).
#              Optionally, you can inclue a gtf file with gene_id and 
#              gene_name parameters in the 9th column.  The script will
#              Include records in the htseq-count file where the gene_ids
#              were different but the gene_name is the same (assuming the
#              gene_name in the gtf is associated with one gene_id).
#
#              Anything that doesn't match will not be printed out.
#
# Usage:       perl intersect_gene_lists.pl -o <old.ref.htseqcounts.txt>
#                                           -n <new.ref.htseqcounts.txt>
#                                           -g <old.gtf>
#                                           -G <new.gtf>
#
# Author:      David Jenkins
# Date:        20141210
# History:  
#
###########################################################################

my ($old_hts, $new_hts, $old_gtf, $new_gtf);

sub usage{
    die(qq/
Usage:    perl intersect_gene_lists.pl [OPTIONS]

Options: -o [FILE] htseq-count file from old genome
         -n [FILE] htseq-count file from new genome
         -g [OPTIONAL] GTF file from old genome
         -G [OPTIONAL] GTF file from new genome
\n/);
}

my %opts;
getopts('o:n:g:G:', \%opts);

if(exists $opts{o} && exists $opts{n}){
    ($old_hts, $new_hts) = ($opts{o}, $opts{n});
    if(exists $opts{g} && exists $opts{G}){
        ($old_gtf, $new_gtf) = ($opts{g}, $opts{G});
    }
}
else{
    print STDERR "\nERROR: submit all required files!\n";
    usage();
}

#load the old htseq-count file into a hash
open(my $hh, $old_hts) or die "Can't open $old_hts\n";
my %hash;
my $counter = 0;
while (my $line = <$hh>) {
	chomp $line;
	if ($line =~ /^#/){
		next;
	}
	my @fields = split /\t/, $line;
    die "DUPLICATE in $old_hts! $hash{$fields[0]} exists!\n" if defined $hash{$fields[0]};
    $hash{$fields[0]} = $fields[1];
} 
close $hh;

my %old_gtf_h;
my %old_gtf_n;
my %new_gtf_h;
my %new_gtf_n;
if (defined $old_gtf){
    #load the old gtf file into a hash
    open(my $gtf, $old_gtf) or die "Can't open $old_gtf\n";
    while(my $line = <$gtf>){
        chomp($line);
        next if $line =~ /^#/;
        my @fields = split /\t/, $line;
        next if $fields[2] ne "gene";
        my @lastfield = split(/;/, $fields[8]);
        die if $lastfield[0] !~ /gene_id/;
        $lastfield[0] =~ s/\s//g;
        my @geneid = split(/\"/,$lastfield[0]);
        foreach(@lastfield){
            $_ =~ s/\s//g;
            my @f = split(/\"/, $_);
            if ($f[0] eq "gene_name"){
                if(defined $old_gtf_n{$f[1]}){
                    $old_gtf_n{$f[1]} = 'bad_thing';
                    $old_gtf_h{$geneid[1]} = 'bad_thing';
                }
                else{
                    $old_gtf_h{$geneid[1]} = $f[1];
                    $old_gtf_n{$f[1]} = $geneid[1];
                }
            }
        }
    }
    close($gtf);
    #load the new gtf file into a hash
    open(my $ngtf, $new_gtf) or die "Can't open $new_gtf\n";
    while(my $line = <$ngtf>){
        chomp($line);
        next if $line =~ /^#/;
        my @fields = split /\t/, $line;
        next if $fields[2] ne "gene";
        my @lastfield = split(/;/, $fields[8]);
        die if $lastfield[0] !~ /gene_id/;
        $lastfield[0] =~ s/\s//g;
        my @geneid = split(/\"/,$lastfield[0]);
        foreach(@lastfield){
            $_ =~ s/\s//g;
            my @f = split(/\"/, $_);
            if ($f[0] eq "gene_name"){
                if(defined $new_gtf_n{$f[1]}){
                    $new_gtf_n{$f[1]} = 'bad_thing';
                    $new_gtf_h{$geneid[1]} = 'bad_thing';
                }
                else{
                    $new_gtf_h{$geneid[1]} = $f[1];
                    $new_gtf_n{$f[1]} = $geneid[1];
                }
            }
        }
    }
    close($ngtf);
}

open(OUTO, ">$old_hts.intersect");
open(OUTN, ">$new_hts.intersect");
open(my $fh, $new_hts) or die;

while (my $line = <$fh>) {
	chomp $line;
	my @fields = split /\t/, $line;
	if (defined $hash{$fields[0]}) {
		print OUTO "$fields[0]\t$hash{$fields[0]}\n";
		print OUTN "$fields[0]\t$fields[1]\n";
	}
    else {
        #if new gene name mapps to old geneid that isn't 0, its also a match!
        if(defined $new_gtf_h{$fields[0]} && defined $old_gtf_n{$new_gtf_h{$fields[0]}} && $old_gtf_n{$new_gtf_h{$fields[0]}} ne 'bad_thing' && $new_gtf_h{$fields[0]} ne 'bad_thing'){
            print OUTO "$new_gtf_h{$fields[0]}\t$hash{$old_gtf_n{$new_gtf_h{$fields[0]}}}\n";
            print OUTN "$new_gtf_h{$fields[0]}\t$fields[1]\n";
        }
	}
}

close $fh;
close OUTO;
close OUTN;
