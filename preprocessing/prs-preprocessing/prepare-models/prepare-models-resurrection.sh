#!/bin/bash

# assigning arguments from flags to varibles
while test $# -gt 0; do
    case "$1" in
        --inputs)
            shift
            inputs=$1
            shift
            ;;
        --resurrection-log)
            shift
            resurrection_log=$1
            shift
            ;;
        *)
            echo "$1 is not a recognized flag!"                 
            break;
            ;;
    esac
done  


# run in screen;
# script monitoring the working taks and checking if they work well
screen -d -m -S resurrection bash -c 'preprocessing/prs-preprocessing/prepare-models/resurrection-plink.sh '$resurrection_log''

# command to prepare proxy needed for slurm
export SINGULARITY_CACHEDIR=$SCRATCH
proxy="`cat /tmp/x509up_u113073 | base64 | tr -d '\n'`"
export proxy

# run script to prepare models
sbatch preprocessing/prs-preprocessing/prepare-models/prepare-models.sh --inputs $inputs


