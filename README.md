# nextflow-fastp
A simple fastp-MultiQC nextflow pipeline

For a bunch of fastq files in a directory (PE or SE), run it with:

```
nextflow run main.nf --readsdir path/to/fastqfiles/
```

The pipeline executes [fastp](https://github.com/OpenGene/fastp), saves the filtered files in `results/fastp_trimmed`, and generates a [MultiQC](https://multiqc.info/) report in `results`. That's it!