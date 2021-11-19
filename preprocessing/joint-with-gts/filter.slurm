#!/bin/bash

## slurm configuration
#SBATCH --partition plgrid-testing
#SBATCH -N 1
#SBATCH --mem=5gb
#SBATCH --time 01:00:00
#SBATCH --ntasks-per-node=1
#SBATCH --job-name hail-script
#SBATCH --output %J.txt
 
module load plgrid/apps/spark/2.4.5 
module load plgrid/tools/python/3.6.5
 
start_spark_cluster

python3 filter.py 4
