#!/bin/bash
#SBATCH -A plgsportwgs2
#SBATCH -p plgrid-long
#SBATCH --time=168:00:00
#SBATCH --mem=10GB
#SBATCH --cpus-per-task=1
#SBATCH -C localfs
#SBATCH --output=/net/archive/groups/plggneuromol/matzieb/slurm-log/%j.out
#SBATCH --error=/net/archive/groups/plggneuromol/matzieb/slurm-log/%j.err

model_path=/net/archive/groups/plggneuromol/imdik-zekanowski-sportwgs/data/prs-models
data_path=/net/archive/groups/plggneuromol/imdik-zekanowski-sportwgs/data/prs-data
output_path=/net/archive/groups/plggneuromol/imdik-zekanowski-sportwgs/data/prs-data/model-results-supplement

# singularity exec \
# --bind /net/archive/groups/plggneuromol/ \
# /net/archive/groups/plggneuromol/singularity-images/polygenic.sif pgstk pgs-compute \
#     --vcf $data_path/sportsmen-control-polish-control.vcf.gz \
#     --model $model_path/biobankuk-30100-both_sexes--mean_platelet_thrombocyte_volume-EUR-1e-08.yml \
#     --af $data_path/gnomad.3.1.vcf.gz \
#     --af-field AF_nfe \
#     -o $output_path

# run supplement task for remove alterante loci
output_path=/net/archive/groups/plggneuromol/imdik-zekanowski-sportwgs/data/prs-data/model-results-supplement-rm-alternate-loci/

singularity exec \
--bind /net/archive/groups/plggneuromol/ \
/net/archive/groups/plggneuromol/singularity-images/polygenic.sif pgstk pgs-compute \
    --vcf $data_path/sportsmen-control-polish-control-rm-alternate-loci.vcf.gz \
    --model $model_path/biobankuk-30100-both_sexes--mean_platelet_thrombocyte_volume-EUR-1e-08.yml \
    --af $data_path/gnomad.3.1.vcf.gz \
    --af-field AF_nfe \
    -o $output_path