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

// needed to pretty print read/bases counts
import java.text.DecimalFormat
df = new DecimalFormat("###,###") //TODO add symbols to fix US locale, http://tutorials.jenkov.com/java-internationalization/decimalformat.html#creating-a-decimalformat-for-a-specific-locale
//println df.format(10000000)

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

mqc_config = file(params.multiqc_config) // this is needed, otherwise the multiqc config file is not available in the docker image

if (params.help) {
    helpMessage()
    exit(0)
}

log.info """
        ===========================================
         F A S T P - M U L T I Q C   P I P E L I N E    

         Used parameters:
        -------------------------------------------
         --readsdir         : ${params.readsdir}
         --fqpattern        : ${params.fqpattern}
         --outdir           : ${params.outdir}
         --multiqc_config   : ${params.multiqc_config}
         --title            : ${params.title}

         Runtime data:
        -------------------------------------------
         Running with profile:   ${ANSI_GREEN}${workflow.profile}${ANSI_RESET}
         Running as user:        ${ANSI_GREEN}${workflow.userName}${ANSI_RESET}
         Launch dir:             ${ANSI_GREEN}${workflow.launchDir}${ANSI_RESET}
         Base dir:               ${ANSI_GREEN}${baseDir}${ANSI_RESET}
         """
         .stripIndent()

def helpMessage() {
log.info """
        ===========================================
         F A S T P - M U L T I Q C   P I P E L I N E
  
         Usage:
        -------------------------------------------
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
        file("${sample_id}_fastp.json") into fastp_ch2
        val seqmode into seqmode_ch


    script:
    def single = x instanceof Path // this is from Paolo: https://groups.google.com/forum/#!topic/nextflow/_ygESaTlCXg
    if ( !single ) {
        seqmode = "PE"
        """
        mkdir fastp_trimmed
        fastp -i ${x[0]} -I ${x[1]} \
        -o fastp_trimmed/trim_${x[0]} -O fastp_trimmed/trim_${x[1]} \
        -j ${sample_id}_fastp.json
        """
    } 
    else {
        seqmode = "SE"
        """
        mkdir fastp_trimmed
        fastp -i ${x} -o fastp_trimmed/trim_${x} \
        -j ${sample_id}_fastp.json
        """
    }

}
 
//=========================

/*
* This process reads the json files from fastp (using jq)
* sums the reads/bases from all read files!
* and sends the stdout in the channels total_reads and total_bases. The stdout is in this case a single value.
* These are used later in multiqc (via the --cl_config parameter)
* to add the numbers as section comments
*/

process summary {

    input:
        file x from fastp_ch2.collect()

    output:
        stdout into total_reads //the channel contains 4 values, sep by new line

    script:
    """
    jq '.summary.before_filtering.total_reads' $x | awk '{sum+=\$0} END{print sum}'
    jq '.summary.after_filtering.total_reads' $x | awk '{sum+=\$0} END{print sum}'
    jq '.summary.before_filtering.total_bases' $x | awk '{sum+=\$0} END{print sum}'
    jq '.summary.after_filtering.total_bases' $x | awk '{sum+=\$0} END{print sum}'
    """
}

//=========================
process multiqc {
    publishDir params.outdir, mode:'copy'
       
    input:
        file x from fastp_ch.collect()
        file mqc_config
        val y from total_reads // y is a string with 4 values sep by new line now
        val seqmode from seqmode_ch // PE or SE, see process fastp

    output:
        file('multiqc_report.html')

    // when using --title, make sure that the --filename is explicit, otherwise
    // multiqc uses the title string as output filename 
    script:

    // the whole thing here is to format the number of reads and bases from the total_reads channel
    def splitstring = y.split()

    def t_reads_before = df.format( splitstring[0].toInteger() )
    def t_reads_after  = df.format( splitstring[1].toInteger() )
    def t_bases_before = df.format( splitstring[2].toInteger() )
    def t_bases_after  = df.format( splitstring[3].toInteger() )
    """
    multiqc --force --interactive \
    --title "${params.title}" \
    --filename "multiqc_report.html" \
    --config $mqc_config \
    --cl_config "section_comments: 
                    { fastp: '*This is ${ seqmode } data *<br>
                              Total reads before filter: ** ${ t_reads_before } ** <br>
                              Total reads    after filter: ** ${ t_reads_after } ** <br><br>
                              Total bases before filter: ** ${ t_bases_before } ** <br>
                              Total bases    after filter: ** ${ t_bases_after } **'
                    }
                " \
    .
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