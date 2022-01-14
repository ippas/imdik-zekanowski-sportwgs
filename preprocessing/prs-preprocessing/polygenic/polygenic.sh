#!/bin/bash
#SBATCH -A plgsportwgs2
#SBATCH --mail-type=ALL
#SBATCH --mail-user=mateuszzieba97@gmail.com
#SBATCH -p plgrid-now
#SBATCH --time=12:00:00
#SBATCH --mem=2GB
#SBATCH --cpus-per-task=1
#SBATCH -C localfs
#SBATCH --output=/net/archive/groups/plggneuromol/matzieb/slurm-log/%j.out
#SBATCH --error=/net/archive/groups/plggneuromol/matzieb/slurm-log/%j.err

module load plgrid/tools/java11/11
module load plgrid/tools/singularity/stable

#export TOOLS_DIR="/net/archive/groups/plggneuromol/tools/"

ls -r data/models-prs/models-scratch | \
#   grep -vP "tmp|coronary|gbe" | \
   xargs -i bash -c 'singularity exec \
     --bind /net/archive/groups/plggneuromol/ \
     /net/archive/groups/plggneuromol/singularity-images/ubuntu_polygenic.sif \
     polygenic \
       --vcf data/prs-data/sportsmen-control.vcf.gz \
       --model data/models-prs/models-scratch/{} \
       --af data/prs-data/gnomad-sites-freqAF-v3.1.1.vcf.gz \
       --af-field nfe \
       -o results/prs-models-results/'




#sg plggneuromol -c 'java \
#        -Dconfig.file=preprocessing/polygenic/cromwell.conf \
#        -Djava.io.tmpdir=$SCRATCH_LOCAL \
#        -jar $TOOLS_DIR/cromwell run \
#                preprocessing/polygenic/polygenic.wdl \
#                -i preprocessing/polygenic/inputs-polygenic.json
#                -o preprocessing/polygenic/options-polygenic.json'



