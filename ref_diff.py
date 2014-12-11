#!/usr/bin/env python

"""
Name:    ref_diff.py

Purpose: Use tophat and deseq to compare RNA-seq results from two reference
         genome versions and create ready to use read count lists for 
         downstream analysis. The tool is mainly designed to compare data
         from GRCh37/hg19 and GRCh38/hg38 but can be generalized with little
         effort.

Input:   -Previous bam alignment
         -Previous bam unmapped reads
         -Raw reads in fastq format
         -old indexed reference (bowtie2/tophat index)
         -old indexed transcript (bowtie2/tophat index)
         -new indexed reference (bowtie2/tophat index)
         -new indexed transcript (bowtie2/tophat index)

Output:  -New reference alignment
         -New reference unmapped bam
         -Differential analysis between previous reference and new reference
         -Read counts (input to DESeq) from hg38 alignment

Usage:   ref_diff.py [OPTIONS]
"""

import os
import re
import sys
import argparse
from subprocess import call

def main(fq1, fq2, tran_index, genome_index, out_dir, threads):
    run_tophat(fq1, fq2, tran_index, genome_index, out_dir, threads)

def run_tophat(fq1, fq2, transcript_index, genome_index, out_dir, threads):
    check_result(call(["tophat",
                       "--read-mismatches=3",
                       "--read-edit-dist=3",
                       "--max-multihits=20",
                       "--splice-mismatches=1",
                       "--output-dir=",out_dir,
                       "--transcriptome-index=",transcript_index,
                       "--coverage-search",
                       "--mate-inner-dist=50",
                       "--microexon-search",
                       "--mate-std-dev=50",
                       "--num-threads=",threads,
                       genome_index,
                       fq1,
                       fq2]))

def run_htseqcount(arg1,arg2):
    #do it
    pass

def run_deseq(arg1, arg2):
    #do it
    pass
    
def verify_file(file):
    if not os.path.isfile(file):
        raise IOError("The File %s does not exist!" % file)    

def check_result(ret_code):
    if ret_code != 0:
        raise RuntimeError("Subprocess failed %s" % ret_code)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description = "Use tophat and deseq to compare RNA-seq results from two reference genome versions and create ready to use read count lists for downstream analysis. The tool is mainly designed to compare data from GRCh37/hg19 and GRCh38/hg38 but can be generalized with little effort.")
    parser.add_argument('output_dir', help='Output directory')
    parser.add_argument('--oldbam', '-b', help='Previous bam alignment', required=True)
    parser.add_argument('--oldun','-o',help='Previous bam unmapped reads', required=True)
    parser.add_argument('--fq1', '-1',help='Fastq formatted reads, read 1', required=True)
    parser.add_argument('--fq2', '-2', help='Fastq formatted reads, read 2', required=True)
    parser.add_argument('--oldref', '-r', help='old indexed reference', required=True)
    parser.add_argument('--oldtrans', '-t', help='old indexed transcript', required=True)
    parser.add_argument('--newref', '-R', help='new indexed reference', required=True)
    parser.add_argument('--newtrans', '-T', help='new indexed transcript', required=True)
    parser.add_argument('--threads', help='number of threads for multithreaded steps [%(default)s]', default=1)
    args = parser.parse_args()
    os.mkdir(args.output_dir)
    verify_file(args.oldbam)
    verify_file(args.oldun)
    verify_file(args.fq1)
    verify_file(args.fq2)
    verify_file(args.fq1)
    main(args.fq1, args.fq2, args.newtrans, args.newref, args.output_dir, args.threads)
