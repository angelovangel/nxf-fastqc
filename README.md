# nextflow-fastp
A simple fastp-MultiQC nextflow pipeline

For a bunch of fastq files in a directory (for now, paired-end only), run it with:

```
nextflow run main.nf --readsdir path/to/fastqfiles/
```

The pipeline executes [fastp](), saves the filtered files in `results/fastp_trimmed`, and generates a [MultiQC]() report in `results`. That's it!