include { METABAT2_JGISUMMARIZEBAMCONTIGDEPTHS } from '../../modules/nf-core/metabat2/jgisummarizebamcontigdepths/main'
include { METABAT2_METABAT2                    } from '../../modules/nf-core/metabat2/metabat2/main'

workflow BINNING {
    take:
    ch_contigs   // channel: [ val(meta), path(contigs) ]
    ch_bams      // channel: [ val(meta), path(bam) ]

    main:

    ch_versions = Channel.empty()

    /*
    ================================================================================
                            Contigs Depth Calculation
    ================================================================================
    */

    // Join all input channels by sample ID
    ch_jgi_input = ch_contigs
        .join(ch_bams, by: 0)
        .map { meta, contigs, bam ->
            [ meta, contigs, bam ]
        }

    // Dump the joined input channel
    ch_jgi_input.dump(tag: 'joined_input')

    METABAT2_JGISUMMARIZEBAMCONTIGDEPTHS(
        ch_jgi_input.map { meta, _contigs, bam -> [ meta, bam ] },
        ch_jgi_input.map { meta, contigs, _bam -> [ meta, contigs ] }
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
