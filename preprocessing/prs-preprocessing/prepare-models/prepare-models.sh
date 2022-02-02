#!/usr/bin/env bash

#SBATCH -A plgsportwgs2
#SBATCH -p plgrid-testing
#SBATCH -t 1:0:0
#SBATCH --mem=24GB
#SBATCH --cpus-per-task=1
#SBATCH -C localfs
#SBATCH --output=/net/archive/groups/plggneuromol/matzieb/slurm-log/%j.out
#SBATCH --error=/net/archive/groups/plggneuromol/matzieb/slurm-log/%j.err

module load plgrid/tools/java11/11
export TOOLS_DIR="/net/archive/groups/plggneuromol/tools/"

sg plggneuromol -c 'java \
        -Dconfig.file=preprocessing/prs-preprocessing/prepare-models/cromwell.conf \
        -Djava.io.tmpdir=$SCRATCH_LOCAL \
        -jar $TOOLS_DIR/cromwell run \
                preprocessing/prs-preprocessing/prepare-models/prepare-models.wdl \
                --inputs preprocessing/prs-preprocessing/prs-preprocessing/prepare-models/inputs-prepare-models.json'




