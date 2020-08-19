# imdik-zekanowski-sportwgs
WGS of Polish sportsmen


1. All samples were checked with fastqc 0.11.9 with this command:
`docker run --rm -d -v $PWD:/data pegi3s/fastqc /data/{}`

2. A report was then generated with multiQC 1.9:
`docker run --rm -v $PWD:/data ewels/multiqc:latest multiqc -m fastqc --sample-names /data/analysis/samples_naming.tsv /data -o /data`

Sample list with naming scheme and summed numbers of reads is avaiable [here](), it was created with [this script](sample_naming.R)

3. Paired fq files were aligned with bwa-mem and piped through the following commands (samtools): samtools fixmate, sort, markdup

to generate file list:
```
#!/bin/bash

ls fastq/*/*_1.fq*gz | xargs -I {} basename {} | cut -d "_" -f 1-3 > file-list.txt
```
