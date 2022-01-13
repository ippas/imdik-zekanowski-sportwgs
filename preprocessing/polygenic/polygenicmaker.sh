#!/bin/bash
#SBATCH -A plgsportwgs2
#SBATCH -p plgrid
#SBATCH --time=12:00:00
#SBATCH --mail-type=ALL
#SBATCH --mail-user=mateuszzieba97@gmail.com
#SBATCH --mem=3GB
#SBATCH --cpus-per-task=1
#SBATCH -C localfs
#SBATCH --output=/net/archive/groups/plggneuromol/matzieb/slurm-log/%j.out
#SBATCH --error=/net/archive/groups/plggneuromol/matzieb/slurm-log/%j.err

module load plgrid/tools/bcftools/1.9
module load plgrid/tools/singularity/stable

# variable with singularity image with polygenic package
singularity_image=/net/archive/groups/plggneuromol/singularity-images/ubuntu_polygenic.sif

# create tabix file for gnomad-sites-freqAF-v3.1.1.vcf.gz
tabix -p vcf /net/archive/groups/plggneuromol/imdik-zekanowski-sportwgs/data/prs-data/gnomad-sites-freqAF-v3.1.1.vcf.gz

# createindexing file using polygenicmaker for gnomad-sites-freqAF-v3.1.1.vcf.gz
singularity exec \
  --bind /net/archive/groups/plggneuromol/ \
  $singularity_image \
    polygenicmaker vcf-index \
      --vcf /net/archive/groups/plggneuromol/imdik-zekanowski-sportwgs/data/prs-data/gnomad-sites-freqAF-v3.1.1.vcf.gz


# create indexing file using polygenicmaker for sportsmen-control.vcf.gz
singularity exec \
   --bind /net/archive/groups/plggneuromol/ \
  $singularity_image \
    polygenicmaker vcf-index \
      --vcf /net/archive/groups/plggneuromol/imdik-zekanowski-sportwgs/data/prs-data/sportsmen-control.vcf.gz



