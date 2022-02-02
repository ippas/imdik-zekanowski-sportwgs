### Joint genotyping, initial filtering and annotations

1. The g.vcf's that were returned from the Intelliseq germline pipeline were joint genotyped with Hail 0.2.64 with samples from the GTS project and 1000Genomes project

2. Quality filtering was applied (each group had to pass the filters):

repeatmasker track (+/- 2 bp from the edges)
gnomad coverage (90% of samples with DP > 1)
mean DP > 5 - to keep high quality variants only
mean GQ > 50 - to keep high quality variants only
max 3 samples with DP < 3
max 3 samples with GQ < 30

3. MatrixTable was annotated with vep, gnomAD and CADD

### Analyses

1. Burden tests for various genes and gene lists

*note : Single-variant analyses were also performed but produced no meaningful results.

Additionally: on request from the collaborators a vcf with genes from mitocarta 3.0 was exported.


## Sample naming (!)

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
  - all vcfs (7 vcfs are larger as they contain non-variant sites)
  - joint vcf with GTS

2. cyfronet (Prometheus):
  - all bams
  - gvcfs
  - vcfs
  - external-data (gene lists used in the analyses and database of allele frequencies from 900 Polish genomes for reference) 
  - hail-mts (intermediate files in hail format, easily exportable as vcfs)
  - joint-vcf
