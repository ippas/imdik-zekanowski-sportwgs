#!/bin/bash

#SBATCH -A plgsportwgs2
#SBATCH --partition plgrid-now
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=24  # has to be defined explicitly
# #SBATCH --cpus-per-task=24
#SBATCH --mem=120GB
#SBATCH --time 12:00:00
#SBATCH -C localfs
#SBATCH --job-name jupyter-notebook

JUPYTER="jupyter-lab"

# start spark
module load plgrid/apps/spark/3.1.2
export SPARK_LOCAL_DIRS=$SCRATCH_LOCAL/
export SPARK_WORKER_DIR=$SCRATCH_LOCAL/work
start_spark_cluster

# source python virtual environment
source venv-hail-0.2.79/bin/activate

## get tunneling info
XDG_RUNTIME_DIR=""
ipnport=$(shuf -i8000-9999 -n1)
ipnport_local=$ipnport
ipnip=$(hostname -i)

# start an ipcluster instance and launch jupyter server
$JUPYTER --no-browser --port=$ipnport --ip=$ipnip &

# wait for a kernel to start
counter=0

while :
do
    sleep 1
    ((counter=counter+1))

    jupyter_servers=$($JUPYTER list | sed -r 's/[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/localhost/')

    if [[ "$jupyter_servers" =~ "localhost" ]]
    then
        break
    elif [[ $counter -ge 20 ]]
    then
        jupyter_servers="Can't retrieve server URL"
        break
    fi
done

# print tunneling instructions
echo -e "
Copy/Paste this in your local terminal to ssh tunnel with remote
-----------------------------------------------------------------
ssh -o ServerAliveInterval=300 -N -L $ipnport_local:$ipnip:$ipnport ${USER}@pro.cyfronet.pl
-----------------------------------------------------------------

Then open a browser on your local machine to the following address
------------------------------------------------------------------
$jupyter_servers
------------------------------------------------------------------
"
sleep infinity
