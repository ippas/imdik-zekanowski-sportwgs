#!/bin/bash

#SBATCH --partition plgrid-testing
#SBATCH --time 1:00:00
#SBATCH --output=create-venv-%j.out
#SBATCH --error=create-venv-%j.err


module load plgrid/tools/python-intel/3.7.7
python -m venv venv-hail-0.2.79/

source venv-hail-0.2.79/bin/activate
pip install --upgrade pip
pip install hail==0.2.79
pip install jupyterlab
