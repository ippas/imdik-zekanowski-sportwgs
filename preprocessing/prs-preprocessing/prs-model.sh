#!/usr/bin/env bash

#SBATCH -A plgsportwgs2
#SBATCH -p plgrid
#SBATCH -t 3:0:0
#SBATCH --mem=2GB
#SBATCH --cpus-per-task=1
#SBATCH -C localfs
#SBATCH --output=/net/archive/groups/plggneuromol/matzieb/slurm-log/%j.out
#SBATCH --error=/net/archive/groups/plggneuromol/matzieb/slurm-log/%j.err

module load plgrid/tools/singularity/stable


singularity exec \
  --bind /net/archive/groups/plggneuromol/ \
  /net/scratch/people/plgmatzieb/polygenictk@sha256_08f235a180c5468981abee10b75b33123f2878f07d8f402e919793d529854d86.sif \
    pgstk model-biobankuk \
      --code '46' \
      --sex 'both_sexes' \
      --coding '' \
      --output-directory /net/archive/groups/plggneuromol/matzieb/projects/imdik-zekanowski-sportwgs/data/models-prs/tmp-test2/ \
      --variant-metrics-file data/models-prs/full_variant_qc_metrics.txt.gz \
      --index-file data/models-prs/biobankuk_phenotype_manifest.tsv \
      --clumping-vcf /eur.phase3.biobank.set.vcf.gz \
      --source-ref-vcf /dbsnp155.grch37.norm.vcf.gz \
      --target-ref-vcf /dbsnp155.grch38.norm.vcf.gz \
      --gene-positions /ensembl-genes.104.tsv 






#singularity exec \
#  --bind $neuromol \
#  /net/scratch/people/plgmatzieb/polygenictk@sha256_08f235a180c5468981abee10b75b33123f2878f07d8f402e919793d529854d86.sif
#  /net/scratch/people/plgmatzieb/polygenictk@sha256_a16f3aed4dea1a41894cb301657495b20279ecb499aa63e0afabb5ec4bc0fdd2.sif \
#    pgstk model-biobankuk \
#      --code '46' \
#      --sex 'both_sexes' \
#      --coding '' \
#      --index-file /net/archive/groups/plggneuromol/matzieb/projects/imdik-zekanowski-sportwgs/data/models-prs/biobankuk_phenotype_manifest.tsv \
#      --variant-metric-file /net/archive/groups/plggneuromol/matzieb/projects/imdik-zekanowski-sportwgs/data/models-prs/full_variant_qc_metrics.txt \
#      --output-directory /data/models-prs/tmp-test/ \
#      --clumping-vcf /eur.phase3.biobank.set.vcf.gz \
#      --source-ref-vcf /dbsnp155.grch37.norm.vcf.gz \
#      --target-ref-vcf /dbsnp155.grch38.norm.vcf.gz \
#      --gene-positions /ensembl-genes.104.tsv
