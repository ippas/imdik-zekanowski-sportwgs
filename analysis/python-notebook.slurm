#!/bin/bash

## slurm configuration
#SBATCH --partition plgrid
#SBATCH -N 1
#SBATCH --time 07:00:00
#SBATCH --mem=10gb
#SBATCH --ntasks-per-node=1
#SBATCH -c 6
#SBATCH --job-name jupyter-hail-sport
#SBATCH --output job-log--%J.txt
 
## get tunneling info
XDG_RUNTIME_DIR=""
ipnport=$(shuf -i8000-9999 -n1)
ipnip=$(hostname -i)
user=$USER
 
## print tunneling instructions to jupyter-log-{jobid}.txt
echo -e "
    Copy/Paste this in your local terminal to ssh tunnel with remote
    -----------------------------------------------------------------
    ssh -o ServerAliveInterval=300 -N -L $ipnport:$ipnip:$ipnport ${user}@pro.cyfronet.pl
    -----------------------------------------------------------------
 
    Then open a browser on your local machine to the following address
    ------------------------------------------------------------------
    localhost:$ipnport  (prefix w/ https:// if using password)
    ------------------------------------------------------------------
    "

module load plgrid/apps/spark/2.4.3 
module load plgrid/tools/python/3.6.5
 
start_spark_cluster

## start an ipcluster instance and launch jupyter server
jupyter-notebook --no-browser --port=$ipnport --ip=$ipnip
