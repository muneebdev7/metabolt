include { METABAT2_JGISUMMARIZEBAMCONTIGDEPTHS } from '../../modules/nf-core/metabat2/jgisummarizebamcontigdepths/main'
include { METABAT2_METABAT2                    } from '../../modules/nf-core/metabat2/metabat2/main'

workflow BINNING {
    take:
    ch_contigs   // channel: [ val(meta), path(contigs) ]
    ch_bams      // channel: [ val(meta), path(bam) ]
    ch_bais      // channel: [ val(meta), path(bai) ]

    main:

    ch_versions = Channel.empty()

    /*
    ================================================================================
                            Contigs Depth Calculation
    ================================================================================
    */

    // Generate coverage depths for each contig
    ch_summarizedepth_input = ch_contigs
        .join(ch_bams, by: 0)
        .join(ch_bais, by: 0)
        .map { meta, _contigs, bam, bai ->
            [ meta, bam, bai ]
        }

    METABAT2_JGISUMMARIZEBAMCONTIGDEPTHS(
        ch_summarizedepth_input,
        ch_contigs
            .map { _meta, contigs ->
                contigs }
    )
    // Collect version information
    ch_versions = ch_versions.mix(METABAT2_JGISUMMARIZEBAMCONTIGDEPTHS.out.versions.first())

    /*
    ================================================================================
                                Genome Binning
    ================================================================================
    */

    // Prepare input for MetaBAT2
    ch_metabat2_input = ch_contigs
        .join(METABAT2_JGISUMMARIZEBAMCONTIGDEPTHS.out.depth, by: 0)
        .map { meta, contigs, depth ->
            [ meta, contigs, depth ]
        }

    // Run binning
    METABAT2_METABAT2(
        ch_metabat2_input
    )
    // Collect version information
    ch_versions = ch_versions.mix(METABAT2_METABAT2.out.versions.first())

    emit:
    bins = METABAT2_METABAT2.out.fasta
    unbinned = METABAT2_METABAT2.out.unbinned
    metabat2depths = METABAT2_JGISUMMARIZEBAMCONTIGDEPTHS.out.depth
    versions = ch_versions
}
