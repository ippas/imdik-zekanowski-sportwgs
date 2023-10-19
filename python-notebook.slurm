#!/bin/bash

## slurm configuration
#SBATCH --partition plgrid-now
#SBATCH -N 1
#SBATCH --time 12:00:00
#SBATCH --mem=50gb
#SBATCH --ntasks-per-node=1
#SBATCH -c 30
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

module add java/11.0.2
module load python/3.10.4-gcccore-11.3.0

# source python virtual environment
source venv-hail-0.2.109/bin/activate

jupyter lab --no-browser --port=$ipnport --ip=$ipnip
