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
