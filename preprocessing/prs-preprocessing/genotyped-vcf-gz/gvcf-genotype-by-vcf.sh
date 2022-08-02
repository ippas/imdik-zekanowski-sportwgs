#!/usr/bin/env bash

#SBATCH -A plgsportwgs2
#SBATCH -p plgrid
#SBATCH -t 72:0:0
#SBATCH --mem=8GB
#SBATCH --cpus-per-task=1
#SBATCH -C localfs
#SBATCH --output=/net/archive/groups/plggneuromol/matzieb/slurm-log/%j.out
#SBATCH --error=/net/archive/groups/plggneuromol/matzieb/slurm-log/%j.err

module load plgrid/tools/java11/11
export TOOLS_DIR="/net/archive/groups/plggneuromol/tools/"


while test $# -gt 0; do
    case "$1" in
        --inputs)
            shift
            inputs=$1
            shift
            ;;
        *)
            echo "$1 is not a recognized flag!"                 
            break;
            ;;
    esac
done 

sg plggneuromol -c 'java \
        -Dconfig.file=preprocessing/prs-preprocessing/genotyped-vcf-gz/cromwell.conf \
        -Djava.io.tmpdir=$SCRATCH_LOCAL \
        -jar $TOOLS_DIR/cromwell run \
                preprocessing/prs-preprocessing/genotyped-vcf-gz/gvcf-genotype-by-vcf.wdl \
                --inputs '"$inputs"' \
                --options preprocessing/prs-preprocessing/genotyped-vcf-gz/options-gvcf-genotype-by-vcf.json'





