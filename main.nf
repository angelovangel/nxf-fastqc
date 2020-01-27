/* 
 * pipeline input parameters 
 */
params.readsdir = "$baseDir/testdata/"
params.fqpattern = "*_R{1,2}_001.fastq.gz"
params.outdir = "$baseDir/results"
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
         --title            : report title, default is "Summarized fastp report"
        ===========================================
         """
         .stripIndent()

}



//just in case trailing slash in readsdir not provided...
readsdir_repaired = "${params.readsdir}".replaceFirst(/$/, "/") 
//println(readsdir_repaired)

// build search pattern for fastq files in input dir
reads = readsdir_repaired + params.fqpattern

Channel 
    .fromFilePairs( reads, checkIfExists: true, size: -1 ) // default is 2, so set to -1 to allow any number of files
    .ifEmpty { error "Can not find any reads matching ${reads}" }
    .set{ read_pairs_ch }
    
Channel
    .fromPath(params.multiqc_config, checkIfExists: true)
    .set{ multiqc_config_ch }
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
    set sample_id, file(x) from read_pairs_ch
    
    output:
    set file("${sample_id}_fastp.json"), file('fastp_trimmed/trim_*') into fastp_ch
    

    script:
    def single = x instanceof Path // this is from Paolo: https://groups.google.com/forum/#!topic/nextflow/_ygESaTlCXg
    if ( !single ) {
        """
        mkdir fastp_trimmed
        fastp -i ${x[0]} -I ${x[1]} -o fastp_trimmed/trim_${x[0]} -O fastp_trimmed/trim_${x[1]} -j ${sample_id}_fastp.json
        """
    } 
    else {
        """
        mkdir fastp_trimmed
        fastp -i ${x} -o fastp_trimmed/trim_${x} -j ${sample_id}_fastp.json
        """
    }

}
 
//=========================

process multiqc {
    publishDir params.outdir, mode:'copy'
       
    input:
    file x from fastp_ch.collect()
    file y from multiqc_config_ch
    
    output:
    file('multiqc_report.html')
    
    //when using --title, make sure that the --filename is explicit, otherwise
    // multiqc uses the title string as output filename 
    script:
    """
    multiqc --force --interactive --title "${params.title}" --filename "multiqc_report.html" --config $y .
    """
} 

//=============================
workflow.onComplete {
	log.info ( workflow.success ? "\nDone! Open the report in your browser --> $params.outdir/multiqc_report.html\n" : "Finished with errors!" )
}