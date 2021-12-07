#!/bin/bash
#SBATCH -A plgsportwgs2
#SBATCH -p plgrid-now
#SBATCH --time=12:00:00
#SBATCH --mem=2GB
#SBATCH --cpus-per-task=1
#SBATCH -C localfs
#SBATCH --output=/net/archive/groups/plggneuromol/matzieb/slurm-log/%j.out
#SBATCH --error=/net/archive/groups/plggneuromol/matzieb/slurm-log/%j.err

module load plgrid/tools/java11/11
export TOOLS_DIR="/net/archive/groups/plggneuromol/tools/"


sg plggneuromol -c 'java \
        -Dconfig.file=preprocessing/polygenic/cromwell.conf \
        -Djava.io.tmpdir=$SCRATCH_LOCAL \
        -jar $TOOLS_DIR/cromwell run \
                preprocessing/polygenic/polygenic.wdl \
                -i preprocessing/polygenic/inputs-polygenic.json
                -o preprocessing/polygenic/options-polygenic.json'



