#!/bin/bash
#SBATCH -A plgsportwgs3-cpu
#SBATCH --mail-type=ALL
#SBATCH --mail-user=mateuszzieba97@gmail.com
#SBATCH -p plgrid-now
#SBATCH --time=12:0:0
#SBATCH --mem=4GB
#SBATCH --cpus-per-task=1
#SBATCH -C localfs
#SBATCH --output=/net/pr2/projects/plgrid/plggneuromol/matzieb/slurm-log/%j.out
#SBATCH --error=/net/pr2/projects/plgrid/plggneuromol/matzieb/slurm-log/%j.err

# load bcftools
module load bcftools/1.14-gcc-11.2.0

# filtering samples for PRS analysis
python3 preprocessing/prs-preprocessing/r-analysis/dimensionality-analysis/prepare-rsid.py 

# variable with path to dimensionality-analysis directory
dim_analysis_dir="data/prs-data/dimensionality-data"


#########################################
# 1. prepare vcf file with all variatns #
#########################################

# filtering samples for PRS analysis
zcat data/prs-data/sportsmen-control-polish-control-rm-alternate-loci.vcf.gz | \
  grep -f $dim_analysis_dir/rsid-significant-models.txt | \
  bgzip > $dim_analysis_dir/all-samples-id-signif-models.vcf.gz

# prepare tabix file for creating vcf file
tabix -p vcf $dim_analysis_dir/all-samples-id-signif-models.vcf.gz


# filtering samples for PRS analysis
bcftools view \
  -s $(cat data/prs-data/sportsmen-control-polish-control-pheno.tsv | \
  grep sportsmen | \
  cut -f1 | \
  tr "\n" "," | \
  sed 's/,$//') $dim_analysis_dir/all-samples-id-signif-models.vcf.gz | \
  bgzip > $dim_analysis_dir/sportsmen-id-signif-models.vcf.gz

# prepare tabix file for creating vcf file
tabix -p vcf $dim_analysis_dir/sportsmen-id-signif-models.vcf.gz


##################################################################
# 2. prepare vcf file for variants with impact grather than 0.25 #
##################################################################

zcat $dim_analysis_dir/all-samples-id-signif-models.vcf.gz | \
  grep -f $dim_analysis_dir/rsid-impact-0.25.txt | \
  bgzip > $dim_analysis_dir/sportsmen-id-impact-0.25.vcf.gz