#!/usr/bin/env bash

#SBATCH -A plgsportwgs2
#SBATCH -p plgrid
#SBATCH --mail-type=ALL
#SBATCH --mail-user=mateuszzieba97@gmail.com
#SBATCH -t 72:0:0
#SBATCH --mem=100GB
#SBATCH --cpus-per-task=1
#SBATCH -C localfs
#SBATCH --output=/net/archive/groups/plggneuromol/matzieb/slurm-log/polygenic/%j.out
#SBATCH --error=/net/archive/groups/plggneuromol/matzieb/slurm-log/polygenic/%j.err


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
        -Dconfig.file=preprocessing/prs-preprocessing/polygenic/cromwell.conf \
        -Djava.io.tmpdir=$SCRATCH_LOCAL \
        -jar $TOOLS_DIR/cromwell run \
                preprocessing/prs-preprocessing/polygenic/polygenic.wdl \
                --inputs '"$inputs"''
                # --inputs preprocessing/prs-preprocessing/polygenic/inputs-polygenic.json'