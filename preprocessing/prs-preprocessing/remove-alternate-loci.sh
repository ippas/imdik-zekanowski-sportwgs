#!/bin/bash
#SBATCH -A plgsportwgs2
#SBATCH -p plgrid
#SBATCH --time=48:00:00
#SBATCH --mem=10GB
#SBATCH --cpus-per-task=1
#SBATCH -C localfs
#SBATCH --output=/net/archive/groups/plggneuromol/matzieb/slurm-log/%j.out
#SBATCH --error=/net/archive/groups/plggneuromol/matzieb/slurm-log/%j.err

module load plgrid/tools/bcftools/1.9
module load plgrid/tools/bedtools/2.30.0

singularity_image=/net/archive/groups/plggneuromol/singularity-images/polygenic.sif

intersectBed \
  -v \
  -a data/prs-data/sportsmen-control-polish-control.vcf.gz \
  -b data/prs-data/all-alt-scaffold-placement-GRCh38.p14.bed -header | \
    bgzip \
    > data/prs-data/sportsmen-control-polish-control-rm-alternate-loci.vcf.gz


tabix -p vcf data/prs-data/sportsmen-control-polish-control-rm-alternate-loci.vcf.gz

# create indexing file using polygenicmaker for sportsmen-control.vcf.gz
singularity exec \
   --bind /net/archive/groups/plggneuromol/ \
  $singularity_image \
    polygenicmaker vcf-index \
      --vcf /net/archive/groups/plggneuromol/imdik-zekanowski-sportwgs/data/prs-data/sportsmen-control-polish-control-rm-alternate-loci.vcf.gz