#!/bin/bash
#SBATCH -A plgsportwgs2
#SBATCH -p plgrid-now
#SBATCH --time=12:00:00
#SBATCH --mem=60GB
#SBATCH --cpus-per-task=24
#SBATCH -C localfs
#SBATCH --output=/net/archive/groups/plggneuromol/matzieb/slurm-log/%j.out
#SBATCH --error=/net/archive/groups/plggneuromol/matzieb/slurm-log/%j.err


#  assigning arguments from flags to varibles
while test $# -gt 0; do
    case "$1" in
        --input_path)
            shift
            input_path=$1
            shift
            ;;
        --output)
            shift
            output=$1
            shift
            ;;
        *)
            echo "$1 is not a recognized flag!"                 
            break;
            ;;
    esac
done  


source ../../venv/bin/activate

python preprocessing/prs-preprocessing/polygenic/prepare-data-prs.py \
  --input_path $input_path \
  --output $output


# python preprocessing/prs-preprocessing/polygenic/prepare-data-prs.py --input_path data/prs-data/model-results/ --output data/prs-data/prs-score.tsv

