// FASTP-MULTIQC pipeline

/*
NXF ver 19.08+ needed because of the use of tuple instead of set
*/
if( !nextflow.version.matches('>=19.08') ) {
    println "This workflow requires Nextflow version 19.08 or greater and you are running version $nextflow.version"
    exit 1
}

/*
* ANSI escape codes to color output messages, get date to use in results folder name
*/
ANSI_GREEN = "\033[1;32m"
ANSI_RED = "\033[1;31m"
ANSI_RESET = "\033[0m"

// date needed to prefix results dir
DATE = new java.util.Date()
sdf = new java.text.SimpleDateFormat("yyyy-MM-dd")
fdate = sdf.format(DATE)
//println sdf.format(DATE)

/* 
 * pipeline input parameters 
 */
params.readsdir = ""
params.fqpattern = "*_R{1,2}_001.fastq.gz"
params.outdir = "$workflow.launchDir/$fdate-results"
//params.threads = 2 //makes no sense I think, to be removed
params.multiqc_config = "$baseDir/multiqc_config.yml" //custom config mainly for sample names
params.title = "Summarized fastp report"
params.help = ""


if (params.help) {
    helpMessage()
    exit(0)
}

log.info """
        ===========================================
         F A S T P - M U L T I Q C   P I P E L I N E    
        
         --readsdir         : ${params.readsdir}
         --fqpattern        : ${params.fqpattern}
         --outdir           : ${params.outdir}
         --multiqc_config   : ${params.multiqc_config}
         --title            : ${params.title}
        ===========================================
        Running with profile:   ${ANSI_GREEN}${workflow.profile}${ANSI_RESET}
        Running as user:        ${ANSI_GREEN}${workflow.userName}${ANSI_RESET}
        Launch dir:             ${ANSI_GREEN}${workflow.launchDir}${ANSI_RESET}
        Base dir:               ${ANSI_GREEN}${baseDir}${ANSI_RESET}
         """
         .stripIndent()

def helpMessage() {
log.info """
        ===========================================
         U S A G E   
         
         --readsdir         : directory with fastq files, default is "fastq"
         --fqpattern        : regex pattern to match fastq files, default is "*_R{1,2}_001.fastq.gz"
         --outdir           : where results will be saved, default is "results"
         --multiqc_config   : config file for MultiQC, default is "multiqc_config.yml"
         --title            : MultiQC report title, default is "Summarized fastp report"
        ===========================================
         """
         .stripIndent()

}



//just in case trailing slash in readsdir not provided...
readsdir_repaired = "${params.readsdir}".replaceFirst(/$/, "/") 
//println(readsdir_repaired)

// build search pattern for fastq files in input dir
reads = readsdir_repaired + params.fqpattern

// get counts of found fastq files
readcounts = file(reads)
//println readcounts.size()

Channel 
    .fromFilePairs( reads, checkIfExists: true, size: -1 ) // default is 2, so set to -1 to allow any number of files
    .ifEmpty { error "Can not find any reads matching ${reads}" }
    .set{ read_pairs_ch }

//===============================
// some extra features, but too slow
//myDir = file(params.reads).getLast().getParent() //ugly way to get dir out of params.reads
/*
myDir = file(params.readsdir)
myDir.eachFile { item ->
    if( item.getName() =~ /fastq.gz$/) {
        println "${ item.getName() } has ${ item.countFastq() } reads"
    }
    
}
*/
//=========================

// fastp trimmed files are published, json are only sent in the channel and used only by multiqc
process fastp {

    tag "fastp on $sample_id"
    //echo true
    publishDir params.outdir, mode: 'copy', pattern: 'fastp_trimmed/*' // publish only trimmed fastq files
    
    input:
    tuple sample_id, file(x) from read_pairs_ch
    
    output:
    tuple file("${sample_id}_fastp.json"), file('fastp_trimmed/trim_*') into fastp_ch
    

    script:
    def single = x instanceof Path // this is from Paolo: https://groups.google.com/forum/#!topic/nextflow/_ygESaTlCXg
    if ( !single ) {
        """
        mkdir fastp_trimmed
        fastp -i ${x[0]} -I ${x[1]} \
        -o fastp_trimmed/trim_${x[0]} -O fastp_trimmed/trim_${x[1]} \
        -j ${sample_id}_fastp.json
        """
    } 
    else {
        """
        mkdir fastp_trimmed
        fastp -i ${x} -o fastp_trimmed/trim_${x} \
        -j ${sample_id}_fastp.json
        """
    }

}
 
//=========================

process multiqc {
    publishDir params.outdir, mode:'copy'
       
    input:
    file x from fastp_ch.collect()
    
    output:
    file('multiqc_report.html')
    
    // when using --title, make sure that the --filename is explicit, otherwise
    // multiqc uses the title string as output filename 
    script:
    """
    multiqc --force --interactive \
    --title "${params.title}" \
    --filename "multiqc_report.html" \
    --config ${params.multiqc_config} .
    """
} 

//=============================
workflow.onComplete {
    if (workflow.success) {
        log.info """
            ===========================================
            ${ANSI_GREEN}Finished in ${workflow.duration}
            Processed ${ readcounts.size() } fastq files
            See the report here ==> ${ANSI_RESET}$params.outdir/multiqc_report.html
            """
            .stripIndent()
    }
    else {
        log.info """
            ===========================================
            ${ANSI_RED}Finished with errors!${ANSI_RESET}
            """
            .stripIndent()
    }
}