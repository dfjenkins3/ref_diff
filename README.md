ref_diff
========

ref_diff is a pipeline to compare reference genome versions through
differential expression. When upgrading to a new reference genome
version, it's important to understand how changes to the underlying
reference genome sequence will affect differential expression analysis.
This pipeline takes old alignment data, realigns the data to a new
reference genome, and performs differential analysis between the two.

Tools in this pipeline may take a long time to run on large files and
large genomes. For human samples, this process can take a few days, so
we encourage use of multithreading and high performance computing 
clusters if available.

### Software Dependencies

If using this tool on a cluster such as Boston University's
[SCC](http://www.bu.edu/tech/support/research/computing-resources/scc/), 
all of the required software is likely available through a 
[module](http://www.bu.edu/tech/support/research/software-and-programming/software-and-applications/modules/) 
framework. The following modules are required:

```
module load boost
module load samtools/samtools-0.1.19_gnu446
module load bowtie2
module load tophat
module load python2.7/Python-2.7.3_gnu446
module load htseq/0.6.1p1
```

Alternatively, install the tools listed above and put them in your 
$PATH.

### Reference Genomes

To run the differential expression, you must provide a [GTF](http://genome.ucsc.edu/FAQ/FAQformat.html#format4)
file of genome features for both the old and new reference genomes.
For comparison of hg19 and hg38, download and unzip the following files:

hg38: <ftp://ftp.sanger.ac.uk/pub/gencode/Gencode_human/release_21/gencode.v21.annotation.gtf.gz>
hg19: <ftp://ftp.sanger.ac.uk/pub/gencode/Gencode_human/release_19/gencode.v19.annotation.gtf.gz>

_Important Note_:

For the analysis to work properly, the genomic annotations must contain the
same names for the same features.

You will also need a reference fasta file for the new genome version.
For hg38, download and unzip the following file:

<http://hgdownload.cse.ucsc.edu/goldenPath/hg38/bigZips/hg38.fa.gz>

Use tophat to create an index for the reference fasta file for the new
genome version. For hg38, run the following command:

```
bowtie-build hg38.fa hg38 
```

### Running ref_diff

After your computing environment has been set up with all of the required software packages, you can
run the pipeline by running the python script

```
python ref_diff.py \
    --oldbam   <old_alignment.bam \
    --fq1      <reads_1.fastq.gz> \
    --fq2      <reads_2.fastq.gz> \
    --oldgtf   <old_genome_gtf_file> \
    --newref   <new_genome_ref_index> \
    --newtrans <new_genome_transcipt_index> \
    --threads  <number_of_threads> \
    test_out
```

When the script completes the results of all the tools will be written to the output directory that you
specified in the script.  The output directory contains all of the typical files that result from
a tophat run plus additional files created by the pipeline:


| Name | Description |
|-----------|-------------|
| DEseq2.results.annotated.csv | DESeq2 results annotated with raw count, chromosome, and gene name |
| DESeq2.results.csv | DESeq2 results |
| DESeq2.results.png | Plot of log fold change in expression between old and new genomes |
| accepted_hits.bam | alignment file from new genome |
| accepted_hits.name.bam | name sorted alignment file for new genome |
| accepted_hits.name.counts.txt | count file produced by htseq-count for new bam file |
| accepted_hits.name.counts.txt.intersect | count file of all features found in both old and new genome |
| align_summary.txt | Summary of tophat alignment |
| deletions.bed | bed file of predicted deletions |
| insertions.bed | bed file of predicted insertions |
| junctions.bed | bed file of predicted junctions |
| logs | directory of logs |
| prep_reads.info | Read metric information created by tophat |
| previous.bam | softlink to previous bam file location |
| previous.name.bam | name sorted previous bam file |
| previous.name.counts.txt | count file produced by htseq-count for old bam file |
| previous.name.counts.txt.intersect | count file of all features found in both old and new genome |
| unmapped.bam | bam alignment file containing all unmapped reads |
