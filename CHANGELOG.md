# MDL/metabolt: Changelog

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## v1.0.0 - [2025-04-18]

### `Added`

- [#23](https://github.com/muneebdev7/metabolt/pull/23) - Pipeline sync to the latest nf-core template version 3.2.0
- [#22](https://github.com/muneebdev7/metabolt/pull/22) - Added `workflow diagram` and comprehensive documentation
  - Added detailed usage instructions and example configurations
  - Included complete pipeline description with all modules
- [#17](https://github.com/muneebdev7/metabolt/pull/17) - Updated test data sheet
- [#13](https://github.com/muneebdev7/metabolt/pull/13) - Extended main workflow for binning
- [#11](https://github.com/muneebdev7/metabolt/pull/11) - Added `MetaBAT2` & `jgi_summarize_bam_contig_depth` modules
- [#8](https://github.com/muneebdev7/metabolt/pull/8) - Extended main workflow upto Alignment and mapping
- [#7](https://github.com/muneebdev7/metabolt/pull/7) - Implemented main workflow upto MEGAHIT
- [#6](https://github.com/muneebdev7/metabolt/pull/6) - Implemented fastp adapter trimming and quality filtering

### `Changed`

- [#21](https://github.com/muneebdev7/metabolt/pull/21) - Modified fastp module logic for improved preprocessing
- [#17](https://github.com/muneebdev7/metabolt/pull/17) - Enhanced SAMtools workflow for more efficient BAM processing
- [#16](https://github.com/muneebdev7/metabolt/pull/16) - Restructured project directories for better organization
- [#11](https://github.com/muneebdev7/metabolt/pull/11) - `Updated modules` + `list of MEGAHIT k-mers` + `subworkflows`
- [#9](https://github.com/muneebdev7/metabolt/pull/9) - Updated the `publish.dir` & `ext.args` of the modules
- [#7](https://github.com/muneebdev7/metabolt/pull/7) - Optimized MEGAHIT parameters for metagenomic assembly

### `Fixed`

- [#22](https://github.com/muneebdev7/metabolt/pull/22) - Resolved issues with transparent workflow images in documentation
- [#17](https://github.com/muneebdev7/metabolt/pull/17) - Debugged Binning subworkflow
- [#16](https://github.com/muneebdev7/metabolt/pull/16) - Fixed Pipeline sync + pre-commit errors
- [#13](https://github.com/muneebdev7/metabolt/pull/13) - Resolved issues with GitHub Actions + Lint failures
- [#9](https://github.com/muneebdev7/metabolt/pull/9) - Bug fixes in I/O channelization in main workflow

### `Documentation`

- [#22](https://github.com/muneebdev7/metabolt/pull/22) - Updated docs `README.md`, `output.md` and `usage.md`
- [#16](https://github.com/muneebdev7/metabolt/pull/16) - Updated README.md
- [#7](https://github.com/muneebdev7/metabolt/pull/7) - Added ASCII art in nextflow.config
- [#6](https://github.com/muneebdev7/metabolt/pull/6) - Added module output documentation

## v0.6.0 - [2024/11/18]

### `Added`

- [#5](https://github.com/muneebdev7/metabolt/pull/5) - Integrated samtools for indexing.

### `Changed`

- Updated **CHANGELOG.md file** with versioned entries for tracking purpose.
- Updated **CITATIONS.md file** for proper citations.

## v0.5.0 - [2024/11/15]

### `Added`

- [#1](https://github.com/muneebdev7/metabolt/pull/1) - Integrated samtools for
- Tested branching strategies (By setting up dev branch).

## v0.4.0 - [2024/11/15]

### `Added`

- Added BWA modules: index and mem for sequence alignment.

## v0.3.0 - [2024/11/15]

### `Added`

- Integrated megahit module for metagenome assembly.

## v0.2.0 - [2024/11/15]

### `Added`

- Added fastp module for reads preprocessing.

## v0.1.0 - [2024/11/14]

Initial release of MDL/metabolt, created with the [nf-core](https://nf-co.re/) template.

### `Initial Setup`

- Initial template setup from nf-core/tools, version 3.0.2.

---
