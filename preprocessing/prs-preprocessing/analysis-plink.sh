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

bcftools view \
  -i 'AN>=3' \
  -Oz data/prs-data/sportsmen-control-annotate-af.vcf.gz  > data/prs-data/sportsmen-control-annotAF-filterAN.vcf.gz

