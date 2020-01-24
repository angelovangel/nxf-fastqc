/* 
 * pipeline input parameters 
 */
params.readsdir = "$baseDir/fastq"
params.fqpattern = "*_R{1,2}_001.fastq.gz"

params.outdir = "results"
params.multiqc_config = "$baseDir/assets/multiqc_config.yaml" //custom config mainly for sample names

log.info """\
         F A S T P - M U L T I Q C   P I P E L I N E    
         ===========================================
         
         --readsdir     : ${params.readsdir}
         --fqpattern    :${params.fqpattern}
         --outdir       : ${params.outdir}
         """
         .stripIndent()

// build search pattern for fastq files in input dir
reads = params.readsdir + params.fqpattern

Channel 
    .fromFilePairs( reads, checkIfExists: true, size: -1 ) // default is 2, so set to -1 to allow any number of files
    .ifEmpty { error "Can not find any reads matching ${reads}" }
    .set{ read_pairs_ch }
    
Channel
    .fromPath(params.multiqc_config, checkIfExists: true)
    .set{ multiqc_config_ch }
//===============================
// some extra features
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
    def single = x instanceof Path // this is from https://groups.google.com/forum/#!topic/nextflow/_ygESaTlCXg
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
     
    script:
    """
    multiqc --force --interactive --config $y .
    """
} 

//=============================