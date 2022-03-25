#!/bin/bash
#SBATCH -A plgsportwgs2
#SBATCH -p plgrid
#SBATCH --mail-type=ALL
#SBATCH --mail-user=mateuszzieba97@gmail.com
#SBATCH --time=72:00:00
#SBATCH --mem=2GB
#SBATCH --cpus-per-task=1
#SBATCH -C localfs
#SBATCH --output=/net/archive/groups/plggneuromol/matzieb/slurm-log/%j.out
#SBATCH --error=/net/archive/groups/plggneuromol/matzieb/slurm-log/%j.err

module load plgrid/tools/bcftools/1.9

# annotate by allel frequency sportsmen-control.vcf.gz
bcftools annotate \
      -a data/prs-data/gnomad-sites-freqAF-v3.1.1.vcf.gz \
      -c INFO/nfe \
      data/prs-data/sportsmen-control.vcf.gz | 
  bgzip > data/prs-data/sportsmen-control-annotate-af.vcf.gz
