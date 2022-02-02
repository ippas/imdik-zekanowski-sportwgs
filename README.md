# imdik-zekanowski-sportwgs
#### WGS of 102 Polish sportsmen

## Methods

---------------------------------

This sections should be a description of preprocessing and analysis ready to be included in the publication (to fill in later)

-----------------------------------------


## Preprocessing

### WGS preprocessing

1. All samples were checked with fastqc 0.11.9 with this command:

2. A report was then generated with multiQC 1.9
*note: available on io*

3. Each sample was passed through Intelliseq Germline Pipeline (ver 1.8.3) up to the variant calling modules [see wdl here](https://raw.githubusercontent.com/gosborcz/workflows/master/iseq_germline_wgs_1.8.3.wdl).

### Analyses

1. [WGS analysis (burden test etc.)](analysis/WGS-analysis.md)
2. [PRS analysis](analysis/PRS-analysis.md)


*notes:
#### Sample naming (!)


Fastq sample names have two parts and both form the ID. For example, sample B156 has the following fastqs:
`DP8400011742BL_L01_579_1.fq.gz  DP8400011742BL_L01_579_2.fq.gz`
While sample B522 has the following fastqs:
`DP8400011021BR_L01_579_1.fq.clean.fq.gz  FP100001057TR_L01_579_1.fq.clean.fq.gz
DP8400011021BR_L01_579_2.fq.clean.fq.gz  FP100001057TR_L01_579_2.fq.clean.fq.gz`
(Both have the 579 id!)

The original location of each fastq and thus assignment to samples is avaliable in the `md5.txt` file in the `data/fastq` folder on io. This file does not contain the B539 sample as it was sequenced separately and has its own md5.txt file.

## Data localisation + info (missing samples, mistakec etc): 

1. io:
  - two example bams
  - fastqs
  - fastqc files with multiqc report
  - all vcfs
  - joint vcf with GTS

2. cyfronet (Prometheus):
  - all bams
  - gvcfs
  - vcfs
  - external-data (gene lists used in the analyses and database of allele frequencies from 900 Polish genomes for reference) 
  - hail-mts (intermediate files in hail format, easily exportable as vcfs)
  - joint-vcf

