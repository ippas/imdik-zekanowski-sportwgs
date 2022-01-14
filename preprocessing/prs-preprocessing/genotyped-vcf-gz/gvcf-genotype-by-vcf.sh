#!/usr/bin/env bash

#SBATCH -A plgsportwgs2
#SBATCH -p plgrid
#SBATCH -t 72:0:0
#SBATCH --mem=2GB
#SBATCH --cpus-per-task=1
#SBATCH -C localfs
#SBATCH --output=/net/archive/groups/plggneuromol/matzieb/slurm-log/%j.out
#SBATCH --error=/net/archive/groups/plggneuromol/matzieb/slurm-log/%j.err

module load plgrid/tools/java11/11
export TOOLS_DIR="/net/archive/groups/plggneuromol/tools/"

sg plggneuromol -c 'java \
        -Dconfig.file=preprocessing/prs-preprocessing/genotyped-vcf-gz/cromwell.conf \
        -Djava.io.tmpdir=$SCRATCH_LOCAL \
        -jar $TOOLS_DIR/cromwell run \
                preprocessing/prs-preprocessing/genotyped-vcf-gz/gvcf-genotype-by-vcf.wdl \
                --inputs preprocessing/prs-preprocessing/genotyped-vcf-gz/inputs-gvcf-genotype-by-vcf.json \
                --options preprocessing/prs-preprocessing/genotyped-vcf-gz/options-gvcf-genotype-by-vcf.json'





