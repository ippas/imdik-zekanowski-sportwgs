#!/usr/bin/env bash

#SBATCH -A plgsportwgs2
#SBATCH -p plgrid
#SBATCH --mail-type=ALL
#SBATCH --mail-user=mateuszzieba97@gmail.com
#SBATCH -t 72:00:0
#SBATCH --mem=40GB
#SBATCH --cpus-per-task=1
#SBATCH -C localfs
#SBATCH --output=/net/archive/groups/plggneuromol/matzieb/slurm-log/prepare-models/%j.out
#SBATCH --error=/net/archive/groups/plggneuromol/matzieb/slurm-log/prepare-models/%j.err

# assigning arguments from flags to varibles
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

module load plgrid/tools/java11/11
export TOOLS_DIR="/net/archive/groups/plggneuromol/tools/"

sg plggneuromol -c 'java \
        -Dconfig.file=preprocessing/prs-preprocessing/prepare-models/cromwell.conf \
        -Djava.io.tmpdir=$SCRATCH_LOCAL \
        -jar $TOOLS_DIR/cromwell run \
                preprocessing/prs-preprocessing/prepare-models/prepare-models.wdl \
                --inputs '"$inputs"''




