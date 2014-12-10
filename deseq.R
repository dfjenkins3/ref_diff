###DESeq Analysis
source("http://bioconductor.org/biocLite.R")
biocLite("DESeq2")
library("DESeq2")


directory <- commandArgs(trailingOnly=TRUE)[1]
sampleFiles <- c(commandArgs(trailingOnly=TRUE)[2],commandArgs(trailingOnly=TRUE)[3])
sample_name <- commandArgs(trailingOnly=TRUE)[4]

sampleCondition <- c("hg19", "hg38")
sampleTable <- data.frame(sampleName = sampleFiles,
                          fileName = sampleFiles,
                          condition = sampleCondition)
ddsHTSeq <- DESeqDataSetFromHTSeqCount(sampleTable = sampleTable,
                                       directory = directory,
                                       design= ~ condition)

dds <- DESeq(ddsHTSeq)
res <- results(dds)

png(paste("DESeq2", sample_name, "png", sep="."),width=700,height=500, res=130)
plotMA(res, main="DESeq2")
dev.off()

resOrdered <- res[order(res$pvalue),]

write.csv(as.data.frame(resOrdered),
          file=paste("DESeq2", sample_name, "csv", sep="."))
