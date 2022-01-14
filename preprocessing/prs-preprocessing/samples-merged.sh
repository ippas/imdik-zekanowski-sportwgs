#!/bin/bash
#SBATCH -A plgsportwgs2
#SBATCH -p plgrid
#SBATCH --time=72:00:00
#SBATCH --mem=2GB
#SBATCH --cpus-per-task=1
#SBATCH -C localfs
#SBATCH --output=/net/archive/groups/plggneuromol/matzieb/slurm-log/%j.out
#SBATCH --error=/net/archive/groups/plggneuromol/matzieb/slurm-log/%j.err

module load plgrid/tools/bcftools/1.9
module load plgrid/tools/java11/11

# create tabix file for	1kg.rsid.chr.vcf.gz
#tabix -p vcf /net/archive/groups/plggneuromol/imdik-zekanowski-sportwgs/data/prs-data/1kg.rsid.chr.vcf.gz


# merging genotyped vcf file 
bcftools merge $(ls data/genotyped-vcf-gz/*.vcf.gz) | bgzip -c > data/prs-data/tmp/sportsmen-merged.vcf.gz

# create tabix file for merged genotypes
tabix -p vcf /net/archive/groups/plggneuromol/imdik-zekanowski-sportwgs/data/prs-data/tmp/sportsmen-merged.vcf.gz


# mergind sportsmen-merged.vcf.gz with 1kg.rsid.chr.vcf.gz
bcftools merge $(ls data/prs-data/1kg.rsid.chr.vcf.gz \
                    data/prs-data/tmp/sportsmen-merged.vcf.gz) | 
      bgzip  > data/prs-data/tmp/1kg-sportsmen-merged.vcf.gz

# create tabix file for 1kg-sportsmen-merged.vcf.gz
tabix -p vcf data/prs-data/tmp/1kg-sportsmen-merged.vcf.gz


