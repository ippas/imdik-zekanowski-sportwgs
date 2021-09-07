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
  - all vcfs (7 vcfs are larger as they contain non-variant sites - to correct)
  - joint vcf with GTS (7 samples are incorrect, part 1 is split into 5 parts)

2. cyfronet (Prometheus):
  - all bams (five bams were accidentally deleted: B435, B438, B466, B482, B495 and should be recreated from fastq files)
  - gvcfs (all)
  - vcfs (all)
  - external-data (gene lists used in the analyses and database of allele frquencies from 900 Polish genomes for reference) 
  - hail-mts (intermediate files in hail format, easily exportable as vcfs)
  - joint-vcf (with 7 incorrect samples)
  
## Correction info 

7 bams had to be additionally filtered and vcfs, gvcfs and joint vcfs had to be updated as they included (by mistake) extra reads:
these are the following samples:

- B522
- B506
- B507
- B508
- B509
- B523
- B478

```
# 1. DP8400011742BL_L01_573 <- B506 is contaminated with reads with this in the read group (from B24)
# DP8400011021BR_L01_573 and FP100001057TR_L01_573 are the good reads

samtools view -h B506_filtered.bam | grep -v "RG:Z:@DP8400011742BL" | samtools view -bS -o B506_corrected.bam -s

# 2. B522 
# DP8400011742BL - these reads are to be excluded
# DP8400011021BR and FP100001057TR are to be kept

samtools view -h B522_filtered.bam | grep -v "RG:Z:@DP8400011742BL" | samtools view -bS -o B522_corrected.bam -s

# 3. B507
# out - DP8400011742BL
# in - DP8400011021BR & FP100001057TR

samtools view -h B507_filtered.bam | grep -v "RG:Z:@DP8400011742BL" | samtools view -bS -o B507_corrected.bam -s

# 4. B508
# DP8400011742BL - out

samtools view -h B508_filtered.bam | grep -v "RG:Z:@DP8400011742BL" | samtools view -bS -o B508_corrected.bam -s

# 5. B509
# DP8400011742BL - out

samtools view -h B509_filtered.bam | grep -v "RG:Z:@DP8400011742BL" | samtools view -bS -o B509_corrected.bam -s

# 6. B523
# DP8400011742BL -out

samtools view -h B523_filtered.bam | grep -v "RG:Z:@DP8400011742BL" | samtools view -bS -o B523_corrected.bam -s

# 7. B478
# DP8400011738BL - out

samtools view -h B478_filtered.bam | grep -v "RG:Z:@DP8400011738BL" | samtools view -bS -o B478_corrected.bam -s
```


IMPORTANT - the samples were then not YET subjected to joint genotyping again. Therefore the joint vcf with GTS contains samples with WRONG genotypes.


