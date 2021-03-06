#!/bin/bash -l

# . /etc/bashrc

#$ -pe omp 8
#$ -cwd
#$ -N ref_diff

###############################################################################
# A example of a wrapping script for use on BU's scc sun grid engine based
# high performance computing cluster
###############################################################################

module load boost
module load samtools/samtools-0.1.19_gnu446
module load bowtie2
module load tophat
module load python2.7/Python-2.7.3_gnu446
module load htseq/0.6.1p1
ln -s /share/apps/6.0/python/Python-2.7.3_gnu446_x86_64/bin/python2.7 ./python
PATH=.:$PATH

python ~/ref_diff/ref_diff.py \
    --oldbam   /restricted/projectnb/mlpd/mRNA/alignment/hg38/C_0002/subset/hg19/accpeted_hits_chr21.hg19.bam \
    --fq1      /restricted/projectnb/mlpd/mRNA/alignment/hg38/C_0002/subset/C_0002_chr21_1.fastq.gz \
    --fq2      /restricted/projectnb/mlpd/mRNA/alignment/hg38/C_0002/subset/C_0002_chr21_2.fastq.gz \
    --oldgtf   /restricted/projectnb/mlhd/tmp_index/transcriptome_data/hg19_transcriptome.gff \
    --newref   /restricted/projectnb/mlpd/annot/bowtie2/hg38 \
    --newtrans /restricted/projectnb/mlpd/mRNA/alignment/hg38/gencode.v21.annotation \
    --threads  8 \
    test_out
