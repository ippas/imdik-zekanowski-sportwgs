
# PRS documentation

Preprocessing on Cyfronet on Prometheus.

## I. Prepare models
##### Information about scripts
Script for prepare models [find here](https://github.com/ippas/imdik-zekanowski-sportwgs/tree/master/preprocessing/prs-preprocessing/prepare-models)

[prepare-models-resurrection.sh](https://github.com/ippas/imdik-zekanowski-sportwgs/blob/master/preprocessing/prs-preprocessing/prepare-models/prepare-models-resurrection.sh)
Is the main script which is responsible:
1. Run `resurrection-plink.sh` in the background
2. Prepare a proxy for `slurm`.
3. Run `prepare-models.sh` responsible for  resource allocation and run task-creating models
- -\-inputs - json file with phenotype features
- -\-resurrection-log - file with directory to save log from `resurrection-plink.sh`

[cromwell.conf](https://github.com/ippas/imdik-zekanowski-sportwgs/blob/master/preprocessing/prs-preprocessing/prepare-models/cromwell.conf)
Configuration file for cromwell

[resurrection-plink.sh](https://github.com/ippas/imdik-zekanowski-sportwgs/blob/master/preprocessing/prs-preprocessing/prepare-models/resurrection-plink.sh)
The script is responsible for checking if the `plink` run in individual tasks is working properly. Checks every hour the tasks that are running on `slurm` by [prepare-models.wdl](https://github.com/ippas/imdik-zekanowski-sportwgs/blob/master/preprocessing/prs-preprocessing/prepare-models/prepare-models.wdl). Performs a check to see if the task has not stopped. In the event of a halt plink, sends a kick command to keep it running (Is the SIGNIT command that terminates `plink` and allows the task to proceed further. In this case command does not kill all the tasks but allows to go next step.). After each check saves the information `.log` file about each task which stop working properly and create a summary how many tasks stopped.


[prepare-models.wdl](https://github.com/ippas/imdik-zekanowski-sportwgs/blob/master/preprocessing/prs-preprocessing/prepare-models/prepare-models.wdl)
Is the wdl script which is responsible for creating a genetic model for a phenotypic feature. When creating the model, the script uses the singularity image created based on the [docker](https://hub.docker.com/r/marpiech/polygenictk/tags). Creating a model starting with genetic variants a p-value threshold equal `1e-08`. Then it checks if the model has at least 15 genetic variants. If this is not the case, it prepares the model with the next p-value-threshold, up to the value `1e-05`.




##### Command

Prepare `.json` files for cromwell with models:
```
zcat data/prs-data/phenotype_manifest.tsv.gz | \
  cut -f2-4 | \
  sed 1d | \
  awk 'FNR <= n' n=$(zcat data/prs-data/phenotype_manifest.tsv.gz | \
    wc -l | \
    xargs -i bash -c 'expr {} / 2') | \
  sed 's/\t/\",\"/g; s/^/["/; s/$/"]/' | \
  tr "\n" "," | \
  sed 's/^/[/; s/,$/]\n}\n/; s/^/{\n\t"prepare_models.array_model_info"\: /' \
  > preprocessing/prs-preprocessing/prepare-models/inputs-prepare-models-part1.json


zcat data/prs-data/phenotype_manifest.tsv.gz | \
  cut -f2-4 | \
  sed 1d | \
  awk 'FNR > n' n=$(zcat data/prs-data/phenotype_manifest.tsv.gz | \
    wc -l | \
    xargs -i bash -c 'expr {} / 2') | \
  sed 's/\t/\",\"/g; s/^/["/; s/$/"]/' | \
  tr "\n" "," | \
  sed 's/^/[/; s/,$/]\n}\n/; s/^/{\n\t"prepare_models.array_model_info"\: /' \
  > preprocessing/prs-preprocessing/prepare-models/inputs-prepare-models-part2.json
```

To run script to prepare model for the first part model from biobankuk execute command:
```
bash preprocessing/prs-preprocessing/prepare-models/prepare-models-resurrection.sh \
  --inputs preprocessing/prs-preprocessing/prepare-models/inputs-prepare-models-part1.json \
  --resurrection-log ../../resurrection-log/prepare-models-resurrection-part1.log
``` 

To run a script to prepare the model for the second part of models from biobankuk execute the command:
```
bash preprocessing/prs-preprocessing/prepare-models/prepare-models-resurrection.sh \
  --inputs preprocessing/prs-preprocessing/prepare-models/inputs-prepare-models-part2.json \
  --resurrection-log ../../resurrection-log/prepare-models-resurrection-part2.log
```

For 7221 phenotype features prepare models:
 - 6953 models which have more or equal 15 genetics variant
   - 729 models with a threshold equal 1e-08
   - 207 models with a threshold equal 1e-07
   - 538 models with a threshold equal 1e-06
   - 5479 models with a threshold equal 1e-05 
 - 80 models which have less than 15 genetics variants
 - 188 not create models with the minimum threshold 1e-05

## II. Preparation of genotyped data

Prepare metadata to contain sportsmen and 1kg samples:
```
(cat data/prs-data/integrated_call_samples_v3.20130502.ALL.panel | 
     sed '1d' | 
     awk '{print $0"\t1kg"}' && 
cat data/external-data/sporstmen-pheno.csv | 
     sed '1d; s/"//g' | 
     awk '{print $4"\t"$2"\tsporstmen\tnone\tsportsman"}')  | 
sed '1i\\sample\tpop\tsuper_pop\tgender\tgroup' > data/prs-data/1kg-sportsmen-pheno.tsv
```

To prepare data for polygenic risk score (PRS) analysis execute genotyped gvcf file for sportsmen [using files](https://github.com/ippas/imdik-zekanowski-sportwgs/tree/master/preprocessing/prs-preprocessing/genotyped-vcf-gz) and to run script used command:
```
sbatch preprocessing/prs-preprocessing/genotyped-vcf-gz/gvcf-genotype-by-vcf.sh --inputs preprocessing/prs-preprocessing/genotyped-vcf-gz/inputs-psportsmen.json 
```

In the first step to prepare the control group, was merged all genotyped samples for the sportsmen and next connected with samples from 1000 genomes inside 1kg.rsid.chr.vcf.gz, to run the script which executes this use command which [uses files from](https://github.com/ippas/imdik-zekanowski-sportwgs/tree/master/preprocessing), which have two tasks first merge all sportsmen genotype, and second merge them with 1kg.rsid.vcf.gz:
```
sbatch preprocessing/samples-merged/samples-merged.sh
```

## III. Preparation control for sportsmen 


The next step was to execute using [prs-control-pca.ipynb]() which used python version 3.7.7 and 0.2.79 version of [hail package](https://hail.is/). Inside script merging all samples and preparing a metadata file was read and reduced the size of data by drawing rows from vcf file with a probability equal to 0.001 for each line, as a result of that was left about 80 thousand lines, also the value "inf" which are in sportsmen samples in the field QUAL was replaced to 50. To the data was added metadata information about belonging to the population, for 44 genotyped from 1kg.rsid.chr.vcf.gz had no information, so genotyped with a missing population was removed. On prepare the sample was run principal component analysis (PCA) with  [Hardy-Weinberg normalized genotype](https://hail.is/docs/0.2/methods/genetics.html#hail.methods.hwe_normalized_pca). The PC1 and PC2 plot was drawn and filtered genotypes based on median absolute deviation (MAD), where chose sample <img src="https://render.githubusercontent.com/render/math?math=\pm6MAD"> distance from median sportsmen for PC1 and PC2 respectively, for two samples of sportsmen (B502 and B506) were outliers so were not in this range and not included in further analysis. After filtering the 7 AMR genotypes were captured so they were removed before the next PCA

 <img src="https://latex.codecogs.com/svg.latex?\Large&space;MAD=median(|X_{i}-\tilde{X}|)">
 <img src="https://render.githubusercontent.com/render/math?math=\tilde{X}=median(X)">

On filtering data again was performed PCA with HW-normalized, and draw a plot but this time for PC2 and PC3, because PC1 and PC2 separated sportsmen from other genotyped so assessment of group control was impossible. In the drawing plot again was done filtering, but now takes genotyped in <img src="https://render.githubusercontent.com/render/math?math=\pm5MAD"> distance from a median of PC2 and PC3.


In the final remain, 100 sportsmen and 98 European genotyped. Was Prepare metadata file sportsmen-control-pheno.tsv.

Creating a file with sportsmen and control using the command:
```
sbach preprocessing/prs-preprocessing/samples-filter-vcf.sh
```

## IV. Preparation data for polish-control

Prepare metadata for polish control:
```
echo WGS_37b,WGS_37c,WGS_163d,WGS_7120,WGS_7142,WGS_7143,WGS_7152,WGS_7153,WGS_85b,WGS_147c,WGS_180b,WGS_185c,WGS_6819,S_7213,S_7227,S_7241,S_7246,S_7254,S_7274,S_7307,494,462,468,492,490 | 
  sed 's/,/\n/g' | 
  xargs -i bash  -c 'cat /net/archive/groups/plggneuromol/imdik-zekanowski-gts/data/pheno/GTS-coded-corrected-june-2021.csv | grep {}' | 
  cut -f1,3 -d "," | 
  sed 's/"//g' | 
  sed 's/,/\t/g' | 
  awk 'BEGIN { OFS="\t" }  {print $1, "none", "none", $2,  "polish_control"}' > polish-control-pheno.tsv
```

Conncat `sportsmen-control-pheno.tsv` and `poslish-control-pheno.tsv`:
```
cat \
  data/prs-data/sportsmen-control-pheno.tsv \
  data/prs-data/polish-control-pheno.tsv \
  > data/prs-data/sportsmen-control-polish-control-pheno.tsv
```

Set `Low quality` in header in gvcf to polish control:
```
sbatch preprocessing/prs-preprocessing/polish-control-modify-header.sh 
```

Prepare inputs file to genotype polish control samples:
```
(((cat data/prs-data/sportsmen-control-polish-control-pheno.tsv | \
  grep polish_control | \
  cut -f1 | \
  sed 's/^/"/; s/$/"/' | \
  tr "\n" "\t" | \
  sed 's/$/\n/'; \
cat data/prs-data/sportsmen-control-polish-control-pheno.tsv | \
  grep polish_control | \
  cut -f1 | \
  xargs -i bash -c 'ls /net/archive/groups/plggneuromol/imdik-zekanowski-gts/data/gvcf/{}*.gz' | \
  sed 's/^/"/; s/$/"/' | \
  grep lowqual | \
  tr "\n" "\t" | \
  sed 's/$/\n/'; \
cat data/prs-data/sportsmen-control-polish-control-pheno.tsv | \
  grep polish_control | \
  cut -f1 | \
  xargs -i bash -c 'ls /net/archive/groups/plggneuromol/imdik-zekanowski-gts/data/gvcf/{}*.tbi' | \
  sed 's/^/"/; s/$/"/' | \
  grep lowqual | \
  tr "\n" "\t" | \
  sed 's/$/\n/') | 
awk '
{
    for (i=1; i<=NF; i++)  {
        a[NR,i] = $i
    }
}
NF>p { p = NF }
END {
    for(j=1; j<=p; j++) {
        str=a[1,j]
        for(i=2; i<=NR; i++){
            str=str" "a[i,j];
        }
        print str
    }
}' |  \
  sed 's/ /,/g; s/^/[/; s/$/]/' | \
  tr "\n" "," | \
  sed 's/,$//; s/,/, /g; s/^/[/;  s/$/]\n/; s/^/    "gvcf_genotype_by_vcf_workflow.array_sample_info": /' | \
  sed 's/$/,/') && \
(cat preprocessing/prs-preprocessing/genotyped-vcf-gz/inputs-gvcf-genotype-by-vcf.json | \
  head -7 | \
  tail -5)) | \
sed  '1 i\{' | sed  -e '$a}' \
  > preprocessing/prs-preprocessing/genotyped-vcf-gz/inputs-polish-control.json
```

Genotyping gvcf for polish control:
```
sbatch preprocessing/prs-preprocessing/genotyped-vcf-gz/gvcf-genotype-by-vcf.sh \
  --inputs preprocessing/prs-preprocessing/genotyped-vcf-gz/inputs-polish-control.json 
```

Merging samples for polish control together, and next merge with `sportsmen-control.vcf.gz`:
```
sbatch preprocessing/prs-preprocessing/polish-control-merged.sh 
```

## V. PRS analysis
Prepare `.json` file with inputs to prs analysis. To reduce number run tasks models was gather to groups on basis size of models.
 - $\lt$ 100 genetic variants gather to 50 models per task
 - $\geq$ 100 and $\lt$ 500 genetic variants gather to 10 models per task
 - $\geq$ 500 and $\lt$ 1000 genetic variants gather to 3 models per task
 - $\geq$ 1000 genetic variants run 1 model per task
```
(cat data/prs-models/*tsv | 
  awk '{if ($2 < 100) print $0}' | 
  cut -f1 | 
  xargs -n50 | 
  sed 's/^/"/; s/$/"/' && 
cat data/prs-models/*tsv | 
  awk '{if ($2 >= 100 && $2 <500) print $0}' | 
  cut -f1 | 
  xargs -n10 | 
  sed 's/^/"/; s/$/"/' && 
cat data/prs-models/*tsv | 
  awk '{if ($2 >= 500 && $2 < 1000) print $0}' | 
  cut -f1 | 
  xargs -n3 | 
  sed 's/^/"/; s/$/"/' && 
cat data/prs-models/*tsv | 
  awk '{if ($2 >= 1000) print $0}' | 
  cut -f1 | 
  sed 's/^/"/; s/$/"/') | 
  tr "\n" "," | 
  sed 's/,$/\n/' | 
  sed 's/^/[/; s/$/],/' | 
  sed 's/^/"prs_analysis.array_model_files"\: /; s/$/\n"prs_analysis.polygenic.model_path"\: "\/net\/archive\/groups\/plggneuromol\/imdik-zekanowski-sportwgs\/data\/prs-models\/",\n"prs_analysis.polygenic.output_path"\: "\/net\/archive\/groups\/plggneuromol\/imdik-zekanowski-sportwgs\/data\/prs-data\/model-results\/",\n"prs_analysis.polygenic.vcf_file"\: "\/net\/archive\/groups\/plggneuromol\/imdik-zekanowski-sportwgs\/data\/prs-data\/sportsmen-control-polish-control.vcf.gz"/' | 
  sed 's/^/    /' | 
  sed  '1 i\{' | 
  sed  -e '$a}' > preprocessing/prs-preprocessing/polygenic/inputs-polygenic.json 
```

 Command to execute PRS analysis for all samples inside `sportsmen-control-polish-control.vcf.gz`:
```
sbatch preprocessing/prs-preprocessing/polygenic/polygenic.sh \
  --inputs preprocessing/prs-preprocessing/polygenic/inputs-polygenic.json
```

Create table with results from PRS analysis:
```
sbatch preprocessing/prs-preprocessing/polygenic/prepare-data-prs.sh \
  --input_path data/prs-data/model-results/ \
  --output data/prs-data/prs-score.tsv
```

The analysis in R found technical differences in data for sportsmen and control from 1000 Genomes. To remove this difference was made remove alternate loci.


## VI. Remove alternate loci

[Alternate-locus aware variant calling in whole genome sequencing. Genome Medicine 8:139](https://genomemedicine.biomedcentral.com/articles/10.1186/s13073-016-0383-z)

Download file with alternate loci variant:
```
wget \
  -O data/prs-data/tmp-all-alt-scaffold-placement-GRCh38.p14.txt \
  ftp://ftp.ncbi.nlm.nih.gov/genomes/all/annotation_releases/9606/110/GCF_000001405.40_GRCh38.p14/GCF_000001405.40_GRCh38.p14_assembly_structure/all_alt_scaffold_placement.txt 
```

Create `.bed` file for alternate-locus:
```
cat data/prs-data/all-alt-scaffold-placement-GRCh38.p14.txt | \
  grep -v PATCHES | \
  awk 'BEGIN { OFS = "\t" } ; {print "chr"$7, $13, $14, $1, $4, $5, $8}' | \
  sed '1d' \
  > data/prs-data/all-alt-scaffold-placement-GRCh38.p14.bed
```

Remove alternate loci from `.vcf` file using:
```
sbatch preprocessing/prs-preprocessing/remove-alternate-loci.sh
```


## VII. PRS analysis without alternate loci

Prepare `.json` file with inputs without alternate loci to prs analysis using a command (remove `biobankuk-30100-both_sexes--mean_platelet_thrombocyte_volume-EUR-1e-08.yml` because is a too big task, it's run separately):
```
cat preprocessing/prs-preprocessing/polygenic/inputs-polygenic.json | \
  sed 's/sportsmen-control-polish-control.vcf.gz/sportsmen-control-polish-control-rm-alternate-loci.vcf.gz/; s/model\-results/model\-results\-rm\-alternate\-loci/' | 
  sed 's/\"biobankuk\-30100\-both_sexes\-\-mean_platelet_thrombocyte_volume\-EUR\-1e\-08\.yml\",//' \
  > preprocessing/prs-preprocessing/polygenic/inputs-polygenic-rm-alternate-loci.json
```


Command to execute PRS analysis for `.vcf` file with remove alternate loci:
```
sbatch preprocessing/prs-preprocessing/polygenic/polygenic.sh \
  --inputs preprocessing/prs-preprocessing/polygenic/inputs-polygenic-rm-alternate-loci.json
```

Create a table with results from PRS analysis with remove alternate loci:
```
sbatch preprocessing/prs-preprocessing/polygenic/prepare-data-prs.sh \
  --input_path data/prs-data/model-results-rm-alternate-loci/ \
  --output data/prs-data/prs-score-rm-alternate-loci.tsv
```
