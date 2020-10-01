# imdik-zekanowski-sportwgs
WGS of Polish sportsmen


1. All samples were checked with fastqc 0.11.9 with this command:
`docker run --rm -d -v $PWD:/data pegi3s/fastqc /data/{}`

2. A report was then generated with multiQC 1.9:
`docker run --rm -v $PWD:/data ewels/multiqc:latest multiqc -m fastqc --sample-names /data/analysis/samples_naming.tsv /data -o /data`

Sample list with naming scheme and summed numbers of reads is avaiable [here](http://149.156.177.112/projects/imdik-zekanowski-sportwgs/analysis/samples_naming.tsv), it was created with [this script](sample_naming.R)

3. Each sample was passed through Intelliseq Germline Pipeline (ver 1.7.3) [see wdl here]()

To generate inputs (example for 3 samples):
```
ls */B3*/*_1.fq.gz | xargs -i bash -c 'BASENAME=$(echo {} | cut -d "/" -f 2,3,4 | cut -d "_" -f 1,2,3); BASENAME2=$(echo $BASENAME | cut -d "/" -f 1); echo $BASENAME $BASENAME2'
```

