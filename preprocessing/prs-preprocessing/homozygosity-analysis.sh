#!/bin/bash
#SBATCH -A plgsportwgs2
#SBATCH -p plgrid-long
#SBATCH --time=168:00:00
#SBATCH --mem=10GB
#SBATCH --cpus-per-task=1
#SBATCH -C localfs
#SBATCH --output=/net/archive/groups/plggneuromol/matzieb/slurm-log/%j.out
#SBATCH --error=/net/archive/groups/plggneuromol/matzieb/slurm-log/%j.err

module load plgrid/tools/bcftools/1.9
module load plgrid/tools/vcftools/0.1.16

# Change inside header fileformat from 4.3 to 4.2 using command:

bcftools view --header-only data/prs-data/sportsmen-control-polish-control.vcf.gz | \
  sed 's/^##fileformat=VCFv4.3/##fileformat=VCFv4.2/' \
  > data/homozygosity/prs-data-scpc-header4.2.txt

# Create .vcf.gz whit new header

bcftools reheader -h data/homozygosity/prs-data-scpc-header4.2.txt data/prs-data/sportsmen-control-polish-control.vcf.gz > data/homozygosity/scpc-4.2.vcf.gz


# Remove indels form sportsmen-control-4.2.vcf.gz indels:

vcftools \
  --gzvcf data/homozygosity/scpc-4.2.vcf.gz \
  --remove-indels \
  --recode \
  --recode-INFO-all \
  --stdout | bgzip -c > data/homozygosity/noindels-scpc-4.2.vcf.gz


# Remove multiallelic variants from noindels-sc-4.2.vcf.gz file:

vcftools \
  --gzvcf data/homozygosity/noindels-scpc-4.2.vcf.gz \
  --max-alleles 2 \
  --recode \
  --recode-INFO-all \
  --stdout | bgzip -c > data/homozygosity/biallelic-noindels-scpc-4.2.vcf.gz 


# Remove missing from biallelic-noindels-sc-4.2.vcf.gz:

vcftools \
  --gzvcf data/homozygosity/biallelic-noindels-scpc-4.2.vcf.gz \
  --max-missing 0.98 \
  --recode \
  --recode-INFO-all \
  --stdout | bgzip -c > data/homozygosity/filtmissing-biallelic-noindels-scpc-4.2.vcf.gz
