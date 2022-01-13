#!/bin/bash
#SBATCH -A plgsportwgs2
#SBATCH --mail-type=ALL
#SBATCH --mail-user=mateuszzieba97@gmail.com
#SBATCH -p plgrid
#SBATCH --time=48:0:0
#SBATCH --mem=4GB
#SBATCH --cpus-per-task=1
#SBATCH -C localfs
#SBATCH --output=/net/archive/groups/plggneuromol/matzieb/slurm-log/%j.out
#SBATCH --error=/net/archive/groups/plggneuromol/matzieb/slurm-log/%j.err

module load plgrid/tools/bcftools/1.9

# filtering samples for PRS analysis
bcftools view \
  -s $(cat data/prs-data/sportsmen-control-pheno.tsv | \
         cut -f1 | \
         grep -v sample | \
         tr "\n" "," | \
         sed 's/,$//') data/prs-data/1kg-sportsmen-merged.vcf.gz | \
  bgzip > data/prs-data/sportsmen-control.vcf.gz

# prepare tabix file for creating vcf file
tabix -p vcf data/prs-data/sportsmen-control.vcf.gz
