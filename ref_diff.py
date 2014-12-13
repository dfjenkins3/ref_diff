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

def main(fq1, fq2, tran_index, genome_index, out_dir, threads, old_bam, old_trans):
    #softlink old bam to results directory
    os.symlink(old_bam, out_dir + "/previous.bam")
    old_bam_link = out_dir + "/previous.bam"
    #run tophat alignment with new bam and ref
    new_bam = run_tophat(fq1, fq2, tran_index, genome_index, out_dir, threads)
    #name sort old alignment
    sorted_old = sort_bam(old_bam_link, threads)
    #name sort new alignment
    sorted_new = sort_bam(new_bam, threads)
    #htseq-count old alignment
    old_counts = run_htseqcount(sorted_old, old_trans)
    #htseq-count new alignment
    new_counts = run_htseqcount(sorted_new, tran_index+'.gtf')
    #run intersect counts script
    old_i,new_i = intersect_counts(old_counts, new_counts, old_trans, tran_index+'.gtf')
    #run deseq script
    deseq_result = run_deseq(old_i, new_i, out_dir)
    #run annotation script
    annotate_result(deseq_result, old_i, new_i, tran_index+'.gtf')

def run_tophat(fq1, fq2, transcript_index, genome_index, out_dir, threads):
    check_result(call(["tophat",
                       "--read-mismatches=3",
                      "--read-edit-dist=3",
                      "--max-multihits=20",
                      "--splice-mismatches=1",
                      "--output-dir="+out_dir,
                      "--transcriptome-index="+transcript_index,
                      "--coverage-search",
                      "--mate-inner-dist=50",
                      "--microexon-search",
                      "--mate-std-dev=50",
                      "--num-threads="+str(threads),
                      genome_index,
                      fq1,
                      fq2]))
    return out_dir+'/accepted_hits.bam'

def run_htseqcount(bam, gtf):
    counts = os.path.splitext(bam)[0] + '.counts.txt'
    count_fh = open(counts, 'w')
    check_result(call(["htseq-count","-f","bam","-s","no","-r","name", bam, gtf], stdout=count_fh))
    count_fh.close()
    return counts

def run_deseq(old, new, out_dir):
    deseq_script = os.path.dirname(os.path.abspath(__file__)) + '/deseq.R'
    check_result(call(["Rscript",deseq_script,out_dir,old,new,"results"]))
    return out_dir + '/DESeq2.results.csv'

def intersect_counts(old, new, o_i, n_i):
    intersect_script = os.path.dirname(os.path.abspath(__file__)) + '/intersect_gene_lists.pl'
    check_result(call([intersect_script,"-o",old,"-n",new,"-g",o_i,"-G",n_i]))
    return old + '.intersect', new + '.intersect'

def annotate_result(deseq, old, new, gtf):
    annotate_script = os.path.dirname(os.path.abspath(__file__)) + '/intersect_results_annotate.pl'
    output = os.path.splitext(deseq)[0] + '.annotated.csv'
    out_fh = open(output, 'w')
    check_result(call([annotate_script,"-d",deseq,"-h",old,"-H",new,"-G",gtf], stdout=out_fh))
    out_fh.close()

def sort_bam(bam, threads):
    sort_prefix = os.path.splitext(bam)[0] + '.name'
    check_result(call(["samtools","sort","-n","-@",str(threads),bam,sort_prefix]))
    return sort_prefix+'.bam'
    
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
    parser.add_argument('--fq1', '-1',help='Fastq formatted reads, read 1', required=True)
    parser.add_argument('--fq2', '-2', help='Fastq formatted reads, read 2', required=True)
    parser.add_argument('--oldgtf', '-t', help='old transcriptome gtf file', required=True)
    parser.add_argument('--newref', '-R', help='new indexed reference', required=True)
    parser.add_argument('--newtrans', '-T', help='new indexed transcript', required=True)
    parser.add_argument('--threads', help='number of threads for multithreaded steps [%(default)s]', default=1)
    args = parser.parse_args()
    os.mkdir(args.output_dir)
    verify_file(args.oldbam)
    verify_file(args.fq1)
    verify_file(args.fq2)
    verify_file(args.oldgtf)
    verify_file(args.newtrans+'.gtf')
    main(args.fq1, args.fq2, args.newtrans, args.newref, args.output_dir,
         args.threads, args.oldbam, args.oldgtf)
