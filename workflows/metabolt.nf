/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { MULTIQC                              } from '../modules/nf-core/multiqc/main'
include { paramsSummaryMap                     } from 'plugin/nf-schema'
include { paramsSummaryMultiqc                 } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { softwareVersionsToYAML               } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { methodsDescriptionText               } from '../subworkflows/local/utils_nfcore_metabolt_pipeline'

//
// MODULES: Installed directly from nf-core/modules
//
include { FASTQC                               } from '../modules/nf-core/fastqc/main'
include { FASTP                                } from '../modules/nf-core/fastp/main'
include { MEGAHIT                              } from '../modules/nf-core/megahit/main'
include { BWA_INDEX                            } from '../modules/nf-core/bwa/index/main'
include { BWA_MEM                              } from '../modules/nf-core/bwa/mem/main'
include { SAMTOOLS_INDEX                       } from '../modules/nf-core/samtools/index/main'
include { BINNING                              } from '../subworkflows/local/binning'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow METABOLT {

    take:
    ch_samplesheet // channel: samplesheet read in from --input
    main:

    ch_versions = Channel.empty()
    ch_multiqc_files = Channel.empty()

    /*
    ================================================================================
                                    QC Reports for reads
    ================================================================================
    */

    //
    // MODULE: Run FastQC
    //
    FASTQC (
        ch_samplesheet
    )
    ch_multiqc_files = ch_multiqc_files.mix(FASTQC.out.zip.collect{it[1]})
    // Collect version information
    ch_versions = ch_versions.mix(FASTQC.out.versions.first())

    //
    // MODULE: Run Fastp for trimming and filtering
    //
    FASTP (
        ch_samplesheet,
        params.adapter_fasta ?: [],
        params.discard_trimmed_pass ?: false,
        params.save_trimmed_fail ?: false,
        params.save_merged ?: false
    )

    // Prepare trimmed reads as input in bwa_mem module
    ch_clean_reads = FASTP.out.reads.map { meta, reads ->
        [meta, reads]
    }
    // Collect JSON files for MultiQC
    ch_multiqc_files = ch_multiqc_files.mix(FASTP.out.json.collect{it[1]})
    // Collect version information
    ch_versions = ch_versions.mix(FASTP.out.versions.first())

    /*
    ================================================================================
                                    Assembly
    ================================================================================
    */

    // Prepare FASTP output for MEGAHIT input
    ch_megahit_input = FASTP.out.reads.map { meta, reads ->
        def reads1 = meta.single_end ? reads : reads[0]
        def reads2 = meta.single_end ? [] : reads[1]
        [meta, reads1, reads2]
    }

    //
    // MODULE: Run MEGAHIT for assembly
    //
    MEGAHIT (
        ch_megahit_input
    )
    // Collect version information
    ch_versions = ch_versions.mix(MEGAHIT.out.versions.first())

    // Prepare assembled contigs for downstream analysis
    ch_assemblies = MEGAHIT.out.contigs.map { meta, contigs ->
        [meta, contigs]
    }

    /*
    ================================================================================
                                Mapping and Alignment
    ================================================================================
    */

    //
    // MODULE: Run BWA_INDEX on assembled contigs for indexing
    //
    BWA_INDEX(ch_assemblies)
    ch_index_for_bwamem = BWA_INDEX.out.index.map { meta, index ->
        [meta, index]
    }
    // Collect version information
    ch_versions = ch_versions.mix(BWA_INDEX.out.versions)

    //
    // MODULE: Run BWA_MEM for alignment of trimmed reads to indexed contigs
    //
    ch_bwamem_input = ch_clean_reads
        .join(ch_index_for_bwamem, by: 0)
        .join(ch_assemblies, by: 0)
        .map { meta, reads, index, contigs ->
            [meta, reads, index, contigs]
        }

    BWA_MEM(
        ch_bwamem_input.map { meta, reads, _index, _contigs -> [meta, reads] },
        ch_bwamem_input.map { meta, _reads, index, _contigs -> [meta, index] },
        ch_bwamem_input.map { meta, _reads, _index, contigs -> [meta, contigs] },
        true
    )
    // Collect version information
    ch_versions = ch_versions.mix(BWA_MEM.out.versions)

    // SAMTOOLS_INDEX
    SAMTOOLS_INDEX(BWA_MEM.out.bam)
    // Collect version information
    ch_versions = ch_versions.mix(SAMTOOLS_INDEX.out.versions)

    // Output channels for downstream use
    ch_sorted_bam = BWA_MEM.out.bam

    /*
    ================================================================================
                Contigs Depth Calculation & Genome Binning
    ================================================================================
    */

    //
    // MODULE: Run METABAT2
    //
    BINNING (
        ch_assemblies,
        ch_sorted_bam,
    )
    ch_versions = ch_versions.mix(BINNING.out.versions)

    //
    // Collate and save software versions
    //
    softwareVersionsToYAML(ch_versions)
        .collectFile(
            storeDir: "${params.outdir}/pipeline_info",
            name:  'metabolt_software_'  + 'mqc_'  + 'versions.yml',
            sort: true,
            newLine: true
        ).set { ch_collated_versions }

    /*
    ================================================================================
                                    MultiQC-Summary
    ================================================================================
    */

    //
    // MODULE: MultiQC
    //
    ch_multiqc_config        = Channel.fromPath(
        "$projectDir/assets/multiqc_config.yml",
        checkIfExists: true
    )
    ch_multiqc_custom_config = params.multiqc_config
        ? Channel.fromPath(params.multiqc_config, checkIfExists: true)
        : Channel.empty()
    ch_multiqc_logo          = params.multiqc_logo
        ? Channel.fromPath(params.multiqc_logo, checkIfExists: true)
        : Channel.empty()

    summary_params      = paramsSummaryMap(
        workflow, parameters_schema: "nextflow_schema.json"
    )
    ch_workflow_summary = Channel.value(paramsSummaryMultiqc(summary_params))
    ch_multiqc_files = ch_multiqc_files.mix(
        ch_workflow_summary.collectFile(name: 'workflow_summary_mqc.yaml')
    )
    ch_multiqc_custom_methods_description = params.multiqc_methods_description
        ? file(params.multiqc_methods_description, checkIfExists: true)
        : file("$projectDir/assets/methods_description_template.yml", checkIfExists: true)
    ch_methods_description                = Channel.value(
        methodsDescriptionText(ch_multiqc_custom_methods_description)
    )

    ch_multiqc_files = ch_multiqc_files.mix(ch_collated_versions)
    ch_multiqc_files = ch_multiqc_files.mix(
        ch_methods_description.collectFile(
            name: 'methods_description_mqc.yaml',
            sort: true
        )
    )

    ch_multiqc_files = ch_multiqc_files.mix(FASTQC.out.zip.collect { it[1] }.ifEmpty([]))

    MULTIQC (
        ch_multiqc_files.collect(),
        ch_multiqc_config.toList(),
        ch_multiqc_custom_config.toList(),
        ch_multiqc_logo.toList(),
        [],
        []
    )

    emit:
    multiqc_report = MULTIQC.out.report.toList() // channel: /path/to/multiqc_report.html
    versions       = ch_versions                 // channel: [ path(versions.yml) ]

}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
