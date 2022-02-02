#!/usr/bin/env bash

#SBATCH -A plgsportwgs2
#SBATCH -p plgrid-testing
#SBATCH -t 1:0:0
#SBATCH --mem=24GB
#SBATCH --cpus-per-task=1
#SBATCH -C localfs
#SBATCH --output=/net/archive/groups/plggneuromol/matzieb/slurm-log/%j.out
#SBATCH --error=/net/archive/groups/plggneuromol/matzieb/slurm-log/%j.err

module load plgrid/tools/singularity/stable

singularity exec \
    --bind /net/archive/groups/plggneuromol,/net/scratch/people/plgmatzieb \
    /net/archive/groups/plggneuromol/singularity-images/polygenictk-2.1.0.sif \
    pgstk model-biobankuk \
      --code 'S66' \
      --sex 'both_sexes' \
      --coding '' \
      --output-directory /net/scratch/people/plgmatzieb/models-prs/tmp-test-singularity \
      --pvalue-threshold "1e-05" \
      --clumping-vcf /eur.phase3.biobank.set.vcf.gz \
      --source-ref-vcf /dbsnp155.grch37.norm.vcf.gz \
      --target-ref-vcf /dbsnp155.grch38.norm.vcf.gz \
      --gene-positions /ensembl-genes.104.tsv  

