#!/usr/local/bin/perl

use strict;
use warnings;
use Getopt::Std;

#
# Name:        intersect_results_annotate.pl
#
# Purpose:     Take the result from DESeq and annotate it with
#              gene name, chromosome, raw counts.
#
# Usage:       perl intersect_results_annotate -d <deseq.out>
#                                           -h <old.ref.htseqcounts.txt>
#                                           -H <new.ref.htseqcounts.txt
#                                           -G <new.gtf>
#
# Author:      David Jenkins
# Date:        20141210
# History:  
#
###########################################################################

my ($deseq, $old_htseq, $new_htseq, $gtf_f);

sub usage{
    die(qq/
Usage:    perl intersect_results_annotate.pl [OPTIONS]

Options: -d [FILE] Output with DESeq
         -h [FILE] htseq-count file from old genome
         -H [FILE] htseq-count file from new genome
         -G [FILE] GTF file from new genome
\n/);
}

my %opts;
getopts('d:h:H:G:', \%opts);

if(exists $opts{d} && exists $opts{h} && exists $opts{H} && exists $opts{G}){
    ($deseq, $old_htseq, $new_htseq, $gtf_f) = ($opts{d}, $opts{h}, $opts{H}, $opts{G});
}
else{
    print STDERR "\nERROR: submit all required files!\n";
    usage();
}

#HASH the htseq-counts into a hash for intersection
open(my $hh, $old_htseq) or die "Damn can't open $old_htseq\n";
my %hash;
while (my $line = <$hh>) {
	chomp $line;
	if ($line =~ /^#/){
		next;
	}
	my @fields = split /\t/, $line;
    die "$hash{$fields[0]} exists!\n" if defined $hash{$fields[0].'1'};
    $hash{$fields[0].'1'} = $fields[1];
} 
close $hh;

open(my $hn, $new_htseq) or die "Damn can't open $new_htseq\n";
while (my $line = <$hn>) {
	chomp $line;
	if ($line =~ /^#/){
		next;
	}
	my @fields = split /\t/, $line;
    die "$hash{$fields[0]} exists!\n" if defined $hash{$fields[0].'2'};
    $hash{$fields[0].'2'} = $fields[1];
}
close $hn;

#GTF ANNOTATIONS HASH
open(my $gtf, $gtf_f) or die "Damn can't open $gtf_f\n";
my %hash_gtf;
while (my $line = <$gtf>) {
	chomp $line;
	if ($line =~ /^#/){
		next;
	}
	my @fields = split /\t/, $line;
    my @lastfield = split(/;/, $fields[8]);
    die if $lastfield[0] !~ /gene_id/;
    $lastfield[0] =~ s/\s//g;
    my @geneid = split(/\"/,$lastfield[0]);
    foreach(@lastfield){
        $_ =~ s/\s//g;
        my @f = split(/\"/, $_);
        $hash_gtf{$geneid[1]}{$f[0]} = $f[1];
    }
    $hash_gtf{$geneid[1]}{'chr'} = $fields[0];
    foreach(@lastfield){
        $_ =~ s/\s//g;
        my @f = split(/\"/, $_);
        $hash_gtf{$hash_gtf{$geneid[1]}{'gene_name'}}{$f[0]} = $f[1];
    }
    $hash_gtf{$hash_gtf{$geneid[1]}{'gene_name'}}{'chr'} = $fields[0];
} 
close $gtf;

#INTERSECT the DESEQ results 
open(my $fh, $deseq) or die;
my $header = <$fh>; 
chomp($header);
print $header;
print "old_count,new_count,chr,gene_type,gene_name\n";
while (my $line = <$fh>) {
	chomp $line;
	my @fields = split /,/, $line;
    $fields[0] =~ s/\"//g;
	if (defined $hash{$fields[0].'1'} && defined $hash_gtf{$fields[0]}{'chr'}) {
		print  "$line,",$hash{$fields[0].'1'},",",$hash{$fields[0].'2'},",",$hash_gtf{$fields[0]}{'chr'},",",$hash_gtf{$fields[0]}{'gene_type'},",",$hash_gtf{$fields[0]}{'gene_name'},"\n";
	}
    else {
		die("ERROR MISSING AN ANNOTATION!\n");
	}
}
close $fh;
