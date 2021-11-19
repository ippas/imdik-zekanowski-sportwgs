#!/bin/bash

## slurm configuration
#SBATCH --partition plgrid
#SBATCH -A plgsportwgs2
#SBATCH -N 1
#SBATCH --cpus-per-task=24
#SBATCH --mem=100gb
#SBATCH --time 3-00:00:00
#SBATCH --ntasks-per-node=1
#SBATCH --job-name hail-script
#SBATCH --output=%J.txt
#SBATCH --error=%J.err

module load plgrid/tools/java8
 
source venv/bin/activate

python genotype-sportsmen.py
