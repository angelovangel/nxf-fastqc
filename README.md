[![Build Status](https://travis-ci.com/angelovangel/nextflow-fastp.svg?branch=master)](https://travis-ci.com/angelovangel/nextflow-fastp)
[![Nextflow](https://img.shields.io/badge/nextflow-%E2%89%A519.08.0-brightgreen.svg)](https://www.nextflow.io/)


# nextflow-fastp
A simple fastp-MultiQC pipeline, written in [nextflow](https://www.nextflow.io/).
For a bunch of fastq files in a directory (PE or SE), run it with:

```
nextflow run angelovangel/nextflow-fastp --readsdir path/to/fastqfiles/
```

The pipeline executes [fastp](https://github.com/OpenGene/fastp), saves the filtered files in `results-fastp/fastp_trimmed`, and generates a [MultiQC](https://multiqc.info/) report. That's it!

For all available options, try

```
nextflow run angelovangel/nextflow-fastp --help
```

If you have conda or docker, you can run the pipeline in a conda environment or in a docker container. Just add `-profile conda` or `-profile docker` to the nextflow command:
```
nextflow run angelovangel/nextflow-fastp --readsdir path/to/fastqfiles/ -profile conda
```

To run it with the included small test dataset
```bash
nextflow run angelovangel/nextflow-fastp -profile test 
# or combine profiles, e.g. -profile test,docker
```

If you don't have nextflow, [go get it!](https://www.nextflow.io/)