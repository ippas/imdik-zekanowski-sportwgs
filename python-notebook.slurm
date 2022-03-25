#!/bin/bash

## slurm configuration
#SBATCH --partition plgrid-now
#SBATCH -N 1
#SBATCH -C localfs
#SBATCH --time 12:00:00
#SBATCH --mem=30gb
#SBATCH --ntasks-per-node=1
#SBATCH -c 20
#SBATCH --job-name jupyter-hail
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

module load plgrid/tools/java8
source /net/archive/groups/plggneuromol/imdik-zekanowski-sportwgs/preprocessing/joint-with-gts/venv/bin/activate

jupyter-notebook --no-browser --port=$ipnport --ip=$ipnip
