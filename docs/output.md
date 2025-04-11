# MDL/metabolt: Output

## Introduction

This document describes the output produced by the pipeline. Most of the plots are taken from the MultiQC report, which summarises results at the end of the pipeline.

The directories listed below will be created in the results directory after the pipeline has finished. All paths are relative to the top-level results directory.

## Pipeline overview

The pipeline is built using [Nextflow](https://www.nextflow.io/) and processes data using the following steps:

- [Quality control](#quality-control) of input reads - trimming and contaminant removal
  - [FastQC](#fastqc) - Raw read QC
  - [fastp](#fastp) - Trimming raw reads
- [Assembly](#assembly) - Assembling trimmed reads into longer contigs
- [Mapping](#mapping) - Mapping preprocessed reads onto contigs
- [Binning](#binning) - Clustering contigs into bins representing individual genomes
- [MultiQC](#multiqc) - Aggregate report describing results and QC from the whole pipeline
- [Pipeline information](#pipeline-information) - Report metrics generated during the workflow execution

---

## Quality control

These steps trim away the adapter sequences present in input reads, trims away bad quality bases and, reads that are too short.
FastQC is run for visualising the general quality metrics of the sequencing runs before and after trimming.

### FastQC

[FastQC](http://www.bioinformatics.babraham.ac.uk/projects/fastqc/) gives general quality metrics about your sequenced reads. It provides information about the quality score distribution across your reads, per base sequence content (%A/T/G/C), adapter contamination and overrepresented sequences. For further reading and documentation see the [FastQC help pages](http://www.bioinformatics.babraham.ac.uk/projects/fastqc/Help/).

<details markdown="1">
<summary>Output files</summary>

- `fastqc/`
  - `[sample]_[1/2]_fastqc.html`: FastQC report, containing quality metrics for your untrimmed raw fastq files
  - `[sample].trimmed_[1/2]_fastqc.html`: FastQC report, containing quality metrics for trimmed and, if specified, filtered read files

</details>

### fastp

[fastp](https://github.com/OpenGene/fastp) is an all-in-one fastq preprocessor for read/adapter trimming and quality control. It is used in this pipeline for trimming adapter sequences and discarding low-quality reads. Its output is in the results folder and part of the MultiQC report.

<details markdown="1">
<summary>Output files</summary>

- `fastp/[sample]/`
  - `[sample/group]_trimmed_[1/2].fastp.fastq.gz`: Compressed preprocessed read file
  - `[sample/group]_trimmed.fastp.html`: Interactive report
  - `[sample/group]_trimmed.fastp.json`: Report in JSON format

</details>

## Assembly

Trimmed (short) reads are assembled with MEGAHIT.

### MEGAHIT

[MEGAHIT](https://github.com/voutcn/megahit) is a fast and memory-efficient assembler designed for assembling large and complex metagenomics datasets. It uses succinct de Bruijn graphs to assemble contigs from short reads.

<details markdown="1">
<summary>Output files</summary>

- `Assembly/`
  - `[sample/group]_assembled.contigs.fa.gz`: Compressed metagenome assembly in FASTA format
  - `[sample/group]_assembled.log`: Log file
  - `intermediate_contigs`: Compressed intermediate k-mers generated during the assembly process.

</details>

## Mapping

### BWA Index

[BWA Index](http://bio-bwa.sourceforge.net/) indexes the reference genome to prepare it for alignment. This step is essential for efficient read mapping.

<details markdown="1">
<summary>Output files</summary>

- `bwa_index/[sample]/`
  - `[sample]_indexed`: Indexed reference genome files

</details>

### BWA MEM

[BWA MEM](http://bio-bwa.sourceforge.net/) is a widely used tool for aligning sequencing reads to a reference genome. It is optimized for high-quality reads and supports paired-end alignment.

<details markdown="1">
<summary>Output files</summary>

- `bwa_align_sorted/[sample]/`
  - `[sample].bam`: Binary alignment map (BAM) file containing the mapped reads

</details>

### SAMTOOLS Index

[SAMTOOLS Index](http://www.htslib.org/) creates an index for BAM files, enabling efficient random access to alignments.

<details markdown="1">
<summary>Output files</summary>

- `samtools/indexed/[sample]/`
  - `[sample].bai`: BAM index file

</details>

## Binning

### MetaBAT2 JGI Summarize Bam Contig Depths

[MetaBAT2 JGI Summarize Bam Contig Depths](https://bitbucket.org/berkeleylab/metabat/src/master/) calculates the depth of coverage for each contig in a BAM file. This information is used for binning contigs into genome bins.

<details markdown="1">
<summary>Output files</summary>

- `metabat2/depths/`
  - `[sample]_depth.txt.gz`: Compressed depth information

</details>

### MetaBAT2

[MetaBAT2](https://bitbucket.org/berkeleylab/metabat/src/master/) is a tool for binning contigs into genome bins based on sequence composition and coverage depth. It is widely used for metagenomic binning.

<details markdown="1">
<summary>Output files</summary>

- `metabat2/bins/[sample]/`
  - `tooShort/*.tooShort.fa.gz`: Contigs too short for binning
  - `lowDepth/*.lowDepth.fa.gz`: Contigs with low depth
  - `unbinned/*.unbinned.fa.gz`: Unbinned contigs
  - `membership/*.tsv.gz`: Membership information
  - `bins/*.fa.gz`: Binned contigs

</details>

## MultiQC

[MultiQC](http://multiqc.info) is a visualization tool that generates a single HTML report summarising all samples in your project. Most of the pipeline QC results are visualised in the report, and further statistics are available in the report data directory.

<details markdown="1">
<summary>Output files</summary>

- `multiqc/`
  - `multiqc_report.html`: A standalone HTML file that can be viewed in your web browser.
  - `multiqc_data/`: Directory containing parsed statistics from the different tools used in the pipeline.
  - `multiqc_plots/`: Directory containing static images from the report in various formats.

</details>

## Pipeline information

<details markdown="1">
<summary>Output files</summary>

- `pipeline_info/`
  - Reports generated by Nextflow: `execution_report.html`, `execution_timeline.html`, `execution_trace.txt` and `pipeline_dag.dot`/`pipeline_dag.svg`.
  - Reports generated by the pipeline: `pipeline_report.html`, `pipeline_report.txt` and `software_versions.yml`. The `pipeline_report*` files will only be present if the `--email` / `--email_on_fail` parameter's are used when running the pipeline.
  - Parameters used by the pipeline run: `params.json`.

</details>

[Nextflow](https://www.nextflow.io/docs/latest/tracing.html) provides excellent functionality for generating various reports relevant to the running and execution of the pipeline. This will allow you to troubleshoot errors with the running of the pipeline, and also provide you with other information such as launch commands, run times and resource usage.
