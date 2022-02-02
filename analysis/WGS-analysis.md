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
