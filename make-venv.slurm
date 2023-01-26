#!/bin/bash

#SBATCH --partition plgrid
#SBATCH --time 00:10:00

HAIL_VERSION=0.2.105

#module load plgrid/tools/python-intel/3.7.7
module load python/3.10.4-gcccore-11.3.0
python -m venv venv-hail-$HAIL_VERSION/

source venv-hail-$HAIL_VERSION/bin/activate
pip install --upgrade pip
pip install wheel
pip install hail==$HAIL_VERSION
pip install numpy pandas matplotlib notebook jupyterlab
