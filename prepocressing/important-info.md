## Sample naming (!)

Fastq sample names have two parts and both form the ID. For example, sample B156 has the following fastqs:
`DP8400011742BL_L01_579_1.fq.gz  DP8400011742BL_L01_579_2.fq.gz`
While sample B522 has the following fastqs:
`DP8400011021BR_L01_579_1.fq.clean.fq.gz  FP100001057TR_L01_579_1.fq.clean.fq.gz
DP8400011021BR_L01_579_2.fq.clean.fq.gz  FP100001057TR_L01_579_2.fq.clean.fq.gz`
(Both have the 597 id!)

The original location of each fastq and thus assignment to samples is avaliable in the `md5.txt` file in the `data/fastq` folder on io. This file does not contain the B539 sample as it was sequenced separately and has its own md5.txt file.

## Data localisation + info (missing samples, mistakec etc): 

1. io:
  - two example bams
  - fastqs
  - fastqc files with multiqc report
  - all vcfs (correct, the corrected vcfs also contain non-variant sites and are thus larger)
  - joint vcf with GTS (7 samples are incorrect, part 1 is split into 5 parts)

2. cyfronet (Prometheus):
  - all bams (five bams were accidentally deleted: B435, B438, B466, B482, B495 and should be recreated from fastq files)


################## start here ####################


7 bams had to be additionally filtered as they included (by mistake) extra reads:
these are the following samples:

X B522
X B506
X B507
X B508
X B509
X B523
X B478


1. DP8400011742BL_L01_573 <- B506 is contaminated with these reads (from B24)
DP8400011021BR_L01_573 and are the good reads  FP100001057TR_L01_573

samtools view -h B506_filtered.bam | grep -v "RG:Z:@DP8400011742BL" | samtools view -bS -o B506_corrected.bam -s

2. B522 

DP8400011742BL - these reads are to be excluded
DP8400011021BR and FP100001057TR are to be kept

samtools view -h B522_filtered.bam | grep -v "RG:Z:@DP8400011742BL" | samtools view -bS -o B522_corrected.bam -s

3. B507

out - DP8400011742BL
in - DP8400011021BR & FP100001057TR

samtools view -h B507_filtered.bam | grep -v "RG:Z:@DP8400011742BL" | samtools view -bS -o B507_corrected.bam -s

4. B508

DP8400011742BL - out

samtools view -h B508_filtered.bam | grep -v "RG:Z:@DP8400011742BL" | samtools view -bS -o B508_corrected.bam -s

5. B509

DP8400011742BL - out

samtools view -h B509_filtered.bam | grep -v "RG:Z:@DP8400011742BL" | samtools view -bS -o B509_corrected.bam -s

6. B523


DP8400011742BL -out


samtools view -h B523_filtered.bam | grep -v "RG:Z:@DP8400011742BL" | samtools view -bS -o B523_corrected.bam -s


7. B478

DP8400011738BL - out

samtools view -h B478_filtered.bam | grep -v "RG:Z:@DP8400011738BL" | samtools view -bS -o B478_corrected.bam -s

missing bams:

B435
B438
B466
B482
B495

IMPORTANT - the samples were then not subjected to joint genotyping again (as these genotypes were already in the joint genotyping, but were added to the existing vcf of the cohort)

Therefore the joint vcf with GTS contains samples with WRONG genotypes that need to be replaced with correct vcfs (available in this folder)


