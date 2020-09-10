#!/usr/bin/env Rscript
#============
#
# this just renders the fastq-stats-report.Rmd file, passing the fastq files as params
# everything else is done there
#
#============
require(rmarkdown)

args <- commandArgs(trailingOnly = T)

# render the rmarkdown, using fastq-report.Rmd as template
rmarkdown::render(input = "fastq-stats-report.Rmd", 
									output_file = "fastq-stats-report.html", 
									output_dir = getwd(), # important when knitting in docker 
									knit_root_dir = getwd(), # important when knitting in docker 
									params = list(fqfiles = args))

# this solved the seqfault error
# https://github.com/cgpu/gel-gwas/commit/2c5a4e5e216478c4a0cbe869c8b4e437b333b787#diff-3254677a7917c6c01f55212f86c57fbf
