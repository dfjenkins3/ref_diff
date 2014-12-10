#!/usr/local/bin/perl

use strict;
use warnings;

my $filename2= $ARGV[0];
my $filename1= $ARGV[1];

open(my $hh, $filename2) or die "Damn can't open $filename2\n";

my %hash;
my $counter = 0;
while (my $line = <$hh>) {
	chomp $line;
	if ($line =~ /^#/){
		next;
	}
	my @fields = split /\t/, $line;
    die "$hash{$fields[0]} exists!\n" if defined $hash{$fields[0]};
    $hash{$fields[0]} = $fields[1];
} 
close $hh;
#USE THE hash

open(OUT, ">merged.txt");
open(OUTsad, ">orphans.txt");
open(my $fh, $filename1) or die;

while (my $line = <$fh>) {
	chomp $line;
	my @fields = split /\t/, $line;
	if (defined $hash{$fields[0]}) {
		print OUT "$fields[0]\t$hash{$fields[0]}\t$fields[1]\n";
	}
    else {
		print OUTsad "$line\n";
	}
}

close $fh;
close OUT;
close OUTsad;

# changed $hash{$fields[1]} to $hash{$fields[0]."_"."$fields[1]
