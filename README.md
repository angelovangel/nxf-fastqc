[![Build Status](https://travis-ci.com/angelovangel/nxf-fastqc.svg?branch=master)](https://travis-ci.com/angelovangel/nxf-fastqc)
[![Nextflow](https://img.shields.io/badge/nextflow-%E2%89%A519.08.0-brightgreen.svg)](https://www.nextflow.io/)


# nxf-fastqc
A simple pipeline for QC of fastq files, written in [nextflow](https://www.nextflow.io/).
For a bunch of fastq files in a directory (Illumina PE or SE, Nanopore), run it with:

```
nextflow run angelovangel/nxf-fastqc --readsdir path/to/fastqfiles/
```

For Nanopore reads, add `-profile ont` to the command.

The pipeline executes [fastp](https://github.com/OpenGene/fastp), saves the filtered files in `results-fastp/fastp_trimmed`, and generates a [MultiQC](https://multiqc.info/) report ([example report](https://angelovangel.github.io/nxf-fastqc/multiqc_report.html)). Some more detailed fastq file statistics are provided in an additional html report, using the [faster](https://github.com/angelovangel/faster) and [fastkmers](https://github.com/angelovangel/fastkmers) programs ([example Illumina](https://angelovangel.github.io/nxf-fastqc/fastq-stats-report.html), [example Nanopore](https://angelovangel.github.io/nxf-fastqc/fastq-stats-report-ont.html)).

For all available pipeline options, try

```
nextflow run angelovangel/nxf-fastqc --help
```

If you have conda or docker, you can run the pipeline in a conda environment or in a docker container. Just add `-profile conda` or `-profile docker` to the nextflow command:
```
nextflow run angelovangel/nxf-fastqc --readsdir path/to/fastqfiles/ -profile conda
```

To run it with the included small test dataset
```bash
nextflow run angelovangel/nxf-fastqc -profile test 
# or combine profiles, e.g. -profile test,docker
```

If you don't have nextflow, [go get it!](https://www.nextflow.io/)
