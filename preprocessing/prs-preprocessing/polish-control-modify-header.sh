#!/bin/bash
#SBATCH -A plgsportwgs2
#SBATCH -p plgrid-now
#SBATCH --time=12:00:00
#SBATCH --mem=6GB
#SBATCH --cpus-per-task=1
#SBATCH -C localfs
#SBATCH --output=/net/archive/groups/plggneuromol/matzieb/slurm-log/%j.out
#SBATCH --error=/net/archive/groups/plggneuromol/matzieb/slurm-log/%j.err

module load plgrid/tools/bcftools/1.9

path=/net/archive/groups/plggneuromol/imdik-zekanowski-gts/data/gvcf

# create modify header
# create new gvcf with new header
# remove tmp header
# tabix created gvcf
cat data/prs-data/sportsmen-control-polish-control-pheno.tsv | \
  grep polish_control | \
  cut -f1 | \
  xargs -i bash -c 'bcftools view --header-only '$path'/{}.g.vcf.gz | \
    sed -E "s/##FILTER=<ID=PASS,Description=\"All filters passed\">/##FILTER=<ID=LowQual,Description=\"Low quality\">/" > '$path'/gts-header.txt && \
  bcftools reheader -h '$path'/gts-header.txt '$path'/{}.g.vcf.gz > '$path'/{}-lowqual.g.vcf.gz && \
  rm '$path'/gts-header.txt && \
  tabix -p vcf '$path'/{}-lowqual.g.vcf.gz' 