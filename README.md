# imdik-zekanowski-sportwgs
WGS of Polish sportsmen


1. All samples were checked with fastqc 0.11.9 with this command:
`docker run --rm -d -v $PWD:/data pegi3s/fastqc /data/{}`

2. A report was then generated with multiQC 1.9:
`docker run --rm -v $PWD:/data ewels/multiqc:latest multiqc -m fastqc --sample-names /data/analysis/samples_naming.tsv /data -o /data`

Sample list with naming scheme and summed numbers of reads is avaiable [here](http://149.156.177.112/projects/imdik-zekanowski-sportwgs/analysis/samples_naming.tsv), it was created with [this script](sample_naming.R)

3. Paired fq files were aligned with bwa-mem and piped through the following commands (samtools): samtools fixmate, sort, markdup

to generate file list:
```
#!/bin/bash

ls fastq/*/*_1.fq*gz | xargs -I {} basename {} | cut -d "_" -f 1-3 > file-list.txt
```

slurm script to run bwa-mem (161 alignments parallel)

```
#!/bin/sh
#SBATCH --job-name=Bwa_Mem
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=24
#SBATCH --time=48:00:00
#SBATCH --partition=plgrid
#SBATCH --mem=120gb
#SBATCH --output=BwaMem.%J.out
#SBATCH --error=BwaMem.%J.err
#SBATCH --array=1-161

module load plgrid/apps/bwa
module load plgrid/tools/samtools

#get file and sample name
file=`cat file-list.txt | head -n $SLURM_ARRAY_TASK_ID | tail -n 1`
sample=`find ./*/* -name "$file*" | head -1 | cut -d "/" -f 3`


#extract read group
zcat -f fastq/${sample}/${file}_1.fq.gz | head -1 | cut -d ':' -f 3,4 | sed 's/:/\./g' > rg_id_$SLURM_ARRAY_TASK_ID
RG_ID=`cat rg_id_$SLURM_ARRAY_TASK_ID`
RG_PU="${RG_ID}.${sample}"
RG_LB="$sample.library"
RG_SM="$sample"
RG_PL="bgi"


bwa mem -t 24 -R "@RG\tID:""$RG_ID""\tPU:""$RG_PU""\tPL:${RG_PL}\tLB:""$RG_LB""\tSM:""$RG_SM" Hg38/Homo_sapiens_assembly38.fa fastq/$sample/${file}_1.fq.gz fastq/$sample/${file}_2.fq.gz | samtools fixmate -m -@24 - - | samtools sort -@24 -O bam - | samtools markdup -@24 - bam/$file.bam
```

script to index bam's:

```
#!/bin/sh
#SBATCH --job-name=gatk-hc
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=24
#SBATCH --time=04:00:00
#SBATCH --partition=plgrid
#SBATCH --mem=120gb
#SBATCH --output=bam-index.%J.out
#SBATCH --error=bam-index.%J.err
#SBATCH --array=1-161

file=`cat file-list.txt | head -n $SLURM_ARRAY_TASK_ID | tail -n 1`

module load plgrid/tools/samtools

samtools index -@ 24 bam/$file.bam 
```
