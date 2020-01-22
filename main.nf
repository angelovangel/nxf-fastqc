/* 
 * pipeline input parameters 
 */
params.readsdir = "fastq"
params.fqpattern = "*_R{1,2}_001.fastq.gz"

params.outdir = "results"
params.multiqc_config = "$baseDir/assets/multiqc_config.yaml" //custom config mainly for sample names

log.info """\
         F A S T P - M U L T I Q C   P I P E L I N E    
         ===========================================
         
         --readsdir    : ${params.readsdir}
         --outdir       : ${params.outdir}
         """
         .stripIndent()

// build search pattern for fastq files in input dir
reads = params.readsdir + params.fqpattern

Channel 
    .fromFilePairs( reads, checkIfExists: true )
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
    set file("${sample_id}_fastp.json"), file('fastp_trimmed/*') into fastp_ch
    

    script:
    """
    mkdir fastp_trimmed
    fastp -i ${x[0]} -I ${x[1]} -o fastp_trimmed/${x[0]} -O fastp_trimmed/${x[1]} -j ${sample_id}_fastp.json
    """

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