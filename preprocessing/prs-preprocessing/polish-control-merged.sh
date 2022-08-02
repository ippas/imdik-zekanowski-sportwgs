#!/bin/bash
#SBATCH -A plgsportwgs2
#SBATCH -p plgrid
#SBATCH --time=72:00:00
#SBATCH --mem=2GB
#SBATCH --cpus-per-task=1
#SBATCH -C localfs
#SBATCH --output=/net/archive/groups/plggneuromol/matzieb/slurm-log/%j.out
#SBATCH --error=/net/archive/groups/plggneuromol/matzieb/slurm-log/%j.err

module load plgrid/tools/bcftools/1.9




# # merging genotyped vcf file 
# bcftools merge $(ls /net/archive/groups/plggneuromol/imdik-zekanowski-sportwgs/data/genotyped-vcf-gz/polish-control/*.vcf.gz) | \
#   bgzip -c >  data/prs-data/polish-control-merged.vcf.gz

# # create tabix file for merged genotypes
# tabix -p vcf data/prs-data/polish-control-merged.vcf.gz


# bcftools merge $(ls data/prs-data/sportsmen-control.vcf.gz \
#                     data/prs-data/polish-control-merged.vcf.gz) | 
#       bgzip -c > data/prs-data/sportsmen-control-polish-control.vcf.gz


# tabix -p vcf data/prs-data/sportsmen-control-polish-control.vcf.gz


singularity exec \
        --bind /net/archive/groups/plggneuromol/ \
        /net/archive/groups/plggneuromol/singularity-images/polygenic.sif polygenicmaker vcf-index \
        --vcf data/prs-data/sportsmen-control-polish-control.vcf.gz