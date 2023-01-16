
# PRS documentation

Preprocessing on Cyfronet on Prometheus.

## I. Prepare models
##### Information about scripts
Scripts for prepare models [find here](https://github.com/ippas/imdik-zekanowski-sportwgs/tree/master/preprocessing/prs-preprocessing/prepare-models)

[prepare-models-resurrection.sh](https://github.com/ippas/imdik-zekanowski-sportwgs/blob/master/preprocessing/prs-preprocessing/prepare-models/prepare-models-resurrection.sh)
Is the main script which is responsible:
1. Run `resurrection-plink.sh` in the background
2. Prepare a proxy for `slurm`.
3. Run `prepare-models.sh` responsible for  resource allocation and run task-creating models
- -\-inputs - json file with phenotype features
- -\-resurrection-log - file with directory to save log from `resurrection-plink.sh`

[cromwell.conf](https://github.com/ippas/imdik-zekanowski-sportwgs/blob/master/preprocessing/prs-preprocessing/prepare-models/cromwell.conf)
Configuration file for cromwell.

[resurrection-plink.sh](https://github.com/ippas/imdik-zekanowski-sportwgs/blob/master/preprocessing/prs-preprocessing/prepare-models/resurrection-plink.sh)
The script is responsible for checking if the `plink` run in individual tasks is working properly. Checks every hour the tasks that are running on `slurm` by [prepare-models.wdl](https://github.com/ippas/imdik-zekanowski-sportwgs/blob/master/preprocessing/prs-preprocessing/prepare-models/prepare-models.wdl). Performs a check to see if the task has not stopped. In the event of a halt plink, sends a kick command to keep it running (Is the SIGNIT command that terminates `plink` and allows the task to proceed further. In this case command does not kill all the tasks but allows to go next step.). After each check saves the information `log` file about each task which stop working properly and create a summary how many tasks stopped.

##### Commands

Download  `phenotype_manifest.tsv.gz` using:
```
curl https://pan-ukb-us-east-1.s3.amazonaws.com/sumstats_release/phenotype_manifest.tsv.bgz > data/prs-data/phenotype_manifest.tsv.gz
```

[prepare-models.wdl](https://github.com/ippas/imdik-zekanowski-sportwgs/blob/master/preprocessing/prs-preprocessing/prepare-models/prepare-models.wdl)
Is the `wdl` script in charge of developing a genetic representation of a phenotypic trait. The script utilizes the singularity image made based on the docker while building the [docker](https://hub.docker.com/r/marpiech/polygenictk/tags). Creating a model starting with genetic variants a p-value threshold equal `1e-08`. Then it checks if the model has at least 15 genetic variants. If this is not the case, it prepares the model with the next p-value-threshold, up to the value `1e-05`.

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
##### Information about scripts
[gvcf-genotype-by-vcf.sh](https://github.com/ippas/imdik-zekanowski-sportwgs/blob/master/preprocessing/prs-preprocessing/genotyped-vcf-gz/gvcf-genotype-by-vcf.sh)
The script prepares the resources for the job and runs `gvcf-getnotype-by-vcf.wdl`

[gvcf-genotype-by-vcf.wdl](https://github.com/ippas/imdik-zekanowski-sportwgs/blob/master/preprocessing/prs-preprocessing/genotyped-vcf-gz/gvcf-genotype-by-vcf.wdl)
The scripts is responsible for genotypes samples.

[inputs-polish-control.json](https://github.com/ippas/imdik-zekanowski-sportwgs/blob/master/preprocessing/prs-preprocessing/genotyped-vcf-gz/inputs-polish-control.json) and [inputs-sportsmen.json](https://github.com/ippas/imdik-zekanowski-sportwgs/blob/master/preprocessing/prs-preprocessing/genotyped-vcf-gz/inputs-sportsmen.json)
Input files containing parameters for genotyping polish control and sportsmen respectively.


[options-gvcf-genotype-by-vcf.json](https://github.com/ippas/imdik-zekanowski-sportwgs/blob/master/preprocessing/prs-preprocessing/genotyped-vcf-gz/options-gvcf-genotype-by-vcf.json)
File with options for cromvell.

[cromwell.conf](https://github.com/ippas/imdik-zekanowski-sportwgs/blob/master/preprocessing/prs-preprocessing/genotyped-vcf-gz/cromwell.conf)
Configuration file for cromwell.

##### Commands
Prepare metadata to contain sportsmen and 1kg samples:
```
(cat data/prs-data/integrated_call_samples_v3.20130502.ALL.panel | 
     sed '1d' | 
     awk '{print $0"\t1kg"}' && 
cat data/external-data/sportsmen-pheno.csv | 
     sed '1d; s/"//g' | 
     awk '{print $4"\t"$2"\tsportsmen\tnone\tsportsman"}')  | 
sed '1i\\sample\tpop\tsuper_pop\tgender\tgroup' > data/prs-data/1kg-sportsmen-pheno.tsv
```

Prepare `inputs-sportsman.json` file using command:
```
((cat data/prs-data/1kg-sportsmen-pheno.tsv | \
  grep sportsman | \
  cut -f1 | \
  sed 's/^/"/; s/$/"/' | \
  tr "\n" "\t" | \
  sed 's/$/\n/'; \
cat data/prs-data/1kg-sportsmen-pheno.tsv | \
  grep sportsmen | \
  cut -f1 | \
  xargs -i bash -c 'ls /net/archive/groups/plggneuromol/imdik-zekanowski-sportwgs/data/gvcf/{}.g.vcf.gz' | \
  sed 's/^/"/; s/$/"/' | \
  tr "\n" "\t" | \
  sed 's/$/\n/'; \
cat data/prs-data/1kg-sportsmen-pheno.tsv | \
  grep sportsmen | \
  cut -f1 | \
  xargs -i bash -c 'ls /net/archive/groups/plggneuromol/imdik-zekanowski-sportwgs/data/gvcf/{}.g.vcf.gz.tbi' | \
  sed 's/^/"/; s/$/"/' | \
  tr "\n" "\t" |   \
  sed 's/$/\n/') | \
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
}' | \
  sed 's/ /,/g; s/^/[/; s/$/]/' |   \
  tr "\n" "," | \
  sed 's/,$//; s/,/, /g; s/^/[/;  s/$/]\n/; s/^/    "gvcf_genotype_by_vcf_workflow.array_sample_info": /' |   sed 's/$/,/')  | sed 's/$/\n  "gvcf_genotype_by_vcf_workflow.gvcf_genotype_by_vcf.docker_image": "intelliseqngs\/gatk-4.1.7.0-hg38:1.0.1",\n  "gvcf_genotype_by_vcf_workflow.gvcf_genotype_by_vcf.genotype_gvcfs_java_options": "-Xmx5g -Xms5g",\n  "gvcf_genotype_by_vcf_workflow.gvcf_genotype_by_vcf.interval_vcf_gz": "\/net\/archive\/groups\/plggneuromol\/imdik-zekanowski-sportwgs\/data\/prs-data\/1kg.rsid.chr.vcf.gz",\n  "gvcf_genotype_by_vcf_workflow.gvcf_genotype_by_vcf.interval_vcf_gz_tbi": "\/net\/archive\/groups\/plggneuromol\/imdik-zekanowski-sportwgs\/data\/prs-data\/1kg.rsid.chr.vcf.gz.tbi",\n  "gvcf_genotype_by_vcf_workflow.gvcf_genotype_by_vcf.merge_annotations": true/' | \
  sed  '1 i\{' | sed  -e '$a}' \
  > preprocessing/prs-preprocessing/genotyped-vcf-gz/inputs-sportsmen.json 
```


To prepare data for polygenic risk score (PRS) analysis execute genotyped gvcf file for sportsmen [using files](https://github.com/ippas/imdik-zekanowski-sportwgs/tree/master/preprocessing/prs-preprocessing/genotyped-vcf-gz) and to run script used command:
```
sbatch preprocessing/prs-preprocessing/genotyped-vcf-gz/gvcf-genotype-by-vcf.sh \
  --inputs preprocessing/prs-preprocessing/genotyped-vcf-gz/inputs-psportsmen.json 
```

In the first step to prepare the control group, was merged all genotyped samples for the sportsmen and next connected with samples from 1000 genomes inside 1kg.rsid.chr.vcf.gz, to run the script which executes this use command which [uses files from](https://github.com/ippas/imdik-zekanowski-sportwgs/tree/master/preprocessing), which have two stage. First merge all sportsmen genotype, and second merge them with 1kg.rsid.vcf.gz:
```
sbatch preprocessing/samples-merged/samples-merged.sh
```

## III. Preparation control using 1000 Genomes Project
##### quillBot
The following stage was running [prs-control-pca.ipynb](https://github.com/ippas/imdik-zekanowski-sportwgs/blob/master/preprocessing/prs-preprocessing/prs-control/prs-control-pca.ipynb), which made use of [hail package](https://hail.is/) version 0.2.79 and Python version 3.7.7. In the script, all samples sportsmen (n = 102) and 1000 Genomes Project (n = 2548) was require, but in order to reduced number variants with probability 0.001 was drawn, leaving about 80 thousand genetic variants. Additionally, the value "inf" that appears in sportsmen samples in the field QUAL of `vcf` was changed to 50. Metadata information regarding population membership was added to the data, and since 44 genotypes from `1kg.rsid.chr.vcf.gz` lacked this information, so they were eliminated. Principal componen analysis (PCA) with [Hardy-Weinberg normalized](https://hail.is/docs/0.2/methods/genetics.html#hail.methods.hwe_normalized_pca) genotype was performed after sample preparation. The PC1 and PC2 plots were created and genotypes were filtered based on [median absolute deviation (MAD)](https://en.wikipedia.org/wiki/Median_absolute_deviation), were sample distance from the <img src="https://render.githubusercontent.com/render/math?math=\pm6MAD"> sportsmen was chosen for PC1 and PC2. Because two sporsmen sample sets (B502 and B506) were outside of this range, they were excluded from further analysis. The 7 AMR genotypes were identified after filtering, and the were eliminated before the second PCA. 

 <img src="https://latex.codecogs.com/svg.latex?\Large&space;MAD=median(|X_{i}-\tilde{X}|)">
 <img src="https://render.githubusercontent.com/render/math?math=\tilde{X}=median(X)">

After filtering the data once more, PCA with HW-normalized was done, and a plot was drawn, but this time for PC2 and PC3, because PC1 and PC2 separated sportsmen from other genotyped such that it was impossible to assess group control. Filtering was done, but this time it used genotypes in relation to a PC2 and PC3 <img src="https://render.githubusercontent.com/render/math?math=\pm5MAD"> distance.

In the final remain, 100 sportsmen and 98 European genotyped, was prepare metadata file sportsmen-control-pheno.tsv.

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

Genotyping `gvcf` for polish control:
```
sbatch preprocessing/prs-preprocessing/genotyped-vcf-gz/gvcf-genotype-by-vcf.sh \
  --inputs preprocessing/prs-preprocessing/genotyped-vcf-gz/inputs-polish-control.json 
```

Merging samples for polish control together, and next merge with `sportsmen-control.vcf.gz`:
```
sbatch preprocessing/prs-preprocessing/polish-control-merged.sh 
```

After this step was executing homozygosity analysis, and the documention can find [here](https://github.com/ippas/imdik-zekanowski-sportwgs/blob/master/analysis/homozygosity-analysis.md).

## V. PRS analysis
##### Information about scripts
[polygenicmaker.sh](https://github.com/ippas/imdik-zekanowski-sportwgs/blob/master/preprocessing/prs-preprocessing/polygenic/polygenicmaker.sh)
The script responsbile for creating `idx.db` files for each sample.

[polygenic.sh](https://github.com/ippas/imdik-zekanowski-sportwgs/blob/master/preprocessing/prs-preprocessing/polygenic/polygenic.sh)
The script for prepare resources and run `polygenic.wdl`.

[polygenic.wdl](https://github.com/ippas/imdik-zekanowski-sportwgs/blob/master/preprocessing/prs-preprocessing/polygenic/polygenic.wdl)

[inputs-polygenic.json](https://github.com/ippas/imdik-zekanowski-sportwgs/blob/master/preprocessing/prs-preprocessing/polygenic/inputs-polygenic.json) and [inputs-polygenic-rm-alternate-loci.json](https://github.com/ippas/imdik-zekanowski-sportwgs/blob/master/preprocessing/prs-preprocessing/polygenic/inputs-polygenic-rm-alternate-loci.json)
Files contain parameters and path to files for calculate PRS.

[cromwell.conf](https://github.com/ippas/imdik-zekanowski-sportwgs/blob/master/preprocessing/prs-preprocessing/polygenic/cromwell.conf)
Configuration file for cromwell.

[prepare-data-prs.sh](https://github.com/ippas/imdik-zekanowski-sportwgs/blob/master/preprocessing/prs-preprocessing/polygenic/prepare-data-prs.sh)
The script responsible for prepare resorces and run `prepare-data-prs.py`.

[prepare-data-prs.py](https://github.com/ippas/imdik-zekanowski-sportwgs/blob/master/preprocessing/prs-preprocessing/polygenic/prepare-data-prs.py)
Script responsible for prepare dataframe from results PRS.


Prepare `json` file with inputs to prs analysis. To reduce number run tasks models was gather to groups on basis size of models.
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

Create `bed` file for alternate-locus:
```
cat data/prs-data/all-alt-scaffold-placement-GRCh38.p14.txt | \
  grep -v PATCHES | \
  awk 'BEGIN { OFS = "\t" } ; {print "chr"$7, $13, $14, $1, $4, $5, $8}' | \
  sed '1d' \
  > data/prs-data/all-alt-scaffold-placement-GRCh38.p14.bed
```

Remove alternate loci from `vcf` file using:
```
sbatch preprocessing/prs-preprocessing/remove-alternate-loci.sh
```


## VII. PRS analysis without alternate loci

Prepare `json` file with inputs without alternate loci to prs analysis using a command (remove `biobankuk-30100-both_sexes--mean_platelet_thrombocyte_volume-EUR-1e-08.yml` because is a too big task, it is run separately):
```
cat preprocessing/prs-preprocessing/polygenic/inputs-polygenic.json | \
  sed 's/sportsmen-control-polish-control.vcf.gz/sportsmen-control-polish-control-rm-alternate-loci.vcf.gz/; s/model\-results/model\-results\-rm\-alternate\-loci/' | 
  sed 's/\"biobankuk\-30100\-both_sexes\-\-mean_platelet_thrombocyte_volume\-EUR\-1e\-08\.yml\",//' \
  > preprocessing/prs-preprocessing/polygenic/inputs-polygenic-rm-alternate-loci.json
```

Command to execute PRS analysis for `vcf` file with remove alternate loci:
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

## VIII. Statistical analysis - r-analysis - to correct
A methodology for statistics was established and applied to PRS scores using scripts created in R version 4.0.3. Beginning with alternate loci, statistics were run for PRS scores. But because of significant differences between 1000 Genomes Project genotyping samples and sportsmen, this region was removed from vcf files in stage VI: Remove Alternate Loci.

When statistics were calculated, phenotypes made up of variants with a statistical threshold of 1e-08 and at least 2000 subjects were selected to identify the phenotype. After this filtration, there were still 729 and 645 phenotypes, respectively. When the p-value from the test in the surveyed group was less than 0.05, phenotypes were then excluded based on the Shapiro-Wilk test, leaving 311 phenotypes. Student's t-test was performed to determine the differences between the groups for two thresholds, 0.05 and 0.01, but the latter was chosen for the second investigation. At the on statics from the 287 Origin Categories created by Biobank UK, only 10 phenotypic categories were ultimately selected.

The PRS scores from control from 1000 Genomes Project and prepared polish control were only use to background in visualization.
No FDR correction was applied to the t-test results because the variants were assigned to more than one phenotype, making them similar as indicated by the correlation results.

The categories were chosen from 287 Origin Categories:
- Health-related outcomes
- Hospital inpatient
- Verbal interview
- Biological samples
- Blood assays
- Blood biochemistry
- Physical measures
- Eye measures
- Primary care
- Blood count

Statics was performed in some comparisios:
 - endurance vs speed: using [endurance-vs-speed.R](https://github.com/ippas/imdik-zekanowski-sportwgs/blob/master/preprocessing/prs-preprocessing/r-analysis/endurance-vs-speed.R), where six phenotypes are found to be significant with a p-value of less than 0.01; however, the phenotypes "colchicine", and "xantihine oxidase inhibitor anti gout agent" are removed because they have correlation that is less than  0.98 with allopurinol and the "anit-gout agent microtubule polymerization inhibitor" respectively. The visualized results can be found at [endurance-hist-box-p.0.01.html](https://rawcdn.githack.com/ippas/imdik-zekanowski-sportwgs/47b5099a90398c23724f241b9131c096405a6e9a/analysis/reports-prs/endurance-speed-hist-box-p.0.01.html). Additionally, a report with a p-value threshold of 0.05 [endurance-speed-hist-box-p.0.05.html](https://rawcdn.githack.com/ippas/imdik-zekanowski-sportwgs/47b5099a90398c23724f241b9131c096405a6e9a/analysis/reports-prs/endurance-speed-hist-box-p.0.05.html) was created
  - swim vs sporsmen using [swim-vs-sporsmen.R](https://github.com/ippas/imdik-zekanowski-sportwgs/blob/master/preprocessing/prs-preprocessing/r-analysis/swim-vs-sportsmen.R). For this comparison, only the "forced expiratory volume in 1 second fev1" phenotype with a p-value of 0.01 was significant. The report with a threshold p = 0.01[swim-sportsman-hist-box-p.0.01.html](https://rawcdn.githack.com/ippas/imdik-zekanowski-sportwgs/47b5099a90398c23724f241b9131c096405a6e9a/analysis/reports-prs/swim-sportsman-hist-box-p.0.01.html) and the p = 0.05 [swim-sportsman-hist-box-p.0.05.html](https://rawcdn.githack.com/ippas/imdik-zekanowski-sportwgs/47b5099a90398c23724f241b9131c096405a6e9a/analysis/reports-prs/swim-sportsman-hist-box-p.0.05.html) was created
  - swim vs weights using [swim-vs-weights.R](https://github.com/ippas/imdik-zekanowski-sportwgs/blob/master/preprocessing/prs-preprocessing/r-analysis/swim-vs-weights.R), 
where the t-test threshold of p-value = 0.01 finds three phenotypes to be significant. Inside [swim-weights-hist-box-p.0.01.html](https://rawcdn.githack.com/ippas/imdik-zekanowski-sportwgs/47b5099a90398c23724f241b9131c096405a6e9a/analysis/reports-prs/swim-weights-hist-box-p.0.01.html) and [swim-weight-hist-box-p.0.05.html](https://rawcdn.githack.com/ippas/imdik-zekanowski-sportwgs/47b5099a90398c23724f241b9131c096405a6e9a/analysis/reports-prs/swim-weights-hist-box-p.0.05.html) are the results with threshold of 0.05.
 - weights vs sportsmen using [weights-vs-sportsmen.R](https://github.com/ippas/imdik-zekanowski-sportwgs/blob/master/preprocessing/prs-preprocessing/r-analysis/weights-vs-sportsmen.R), but for this comparision only find phenotypes with a p-value of 0.05 which are saved to [weights-sportsman-hist-box-p.0.05.html](https://github.com/ippas/imdik-zekanowski-sportwgs/blob/master/analysis/reports-prs/weights-sportsman-hist-box-p.0.05.html)

Additionally, a comparison was executed between all samples using the script [endurance-vs-control.R](https://github.com/ippas/imdik-zekanowski-sportwgs/blob/master/preprocessing/prs-preprocessing/r-analysis/sportsmen-vs-control.R), and a report [sportsman-control-hist-box-p.0.01.html](https://rawcdn.githack.com/ippas/imdik-zekanowski-sportwgs/18a0f9a06afe4d9dbf2131036a2891ba14df494a/analysis/reports-prs/sportsman-control-hist-box-p.0.01.html) was generated. In this statistical comparison, there were some differences in the statistical analysis. In this case, the Shapiro-Wilk test was used to filter data for three groups: sportsmen, an external control from 1000 Genomes Project, and prepared Polish control. Additionally, a stage of filtering was added for phenotypes that do not differ significantly between the two prepared controls on the Studnet's t-test threshold of 0.05 and phenotypes that differ significantly between sportsmen and the Polish control on the weaker Student's t-test threshold of 0.1. Following this filtration, there were still five phenotypes, but two of them -- "trunk  predicted mass" and "gout and other crystal arthropathies" -- were eliminated because they had a correlation of higher than 0.98 with the "trunk fat-free mass" and "gout" phenotypes, respectively.
In further, this comparison was discontinued since both provided controls proved to be insufficient. Polish control sample size was too small for accurate comparisons (n = 25). While the external control from 1000 Genomes Project (Preparation of Control from 1000 Genomes Project) despite was composed of individuals with sportsmen-like genetics, but no members of the Polish population were included in the project. Checking the homozygosity ([homozygosity documentation](https://github.com/ippas/imdik-zekanowski-sportwgs/blob/master/analysis/homozygosity-analysis.md)) revealed the disparities between the two groups, however this impact really reflects the high degree of homozygosity in the Polish population.

[functions-biobank.R](https://github.com/ippas/imdik-zekanowski-sportwgs/blob/master/preprocessing/prs-preprocessing/r-analysis/functions-biobank.R)
This script contains the functions needed to require data about available phenotypes from Biobank UK by using URL. The functions combine phenotypes from [Pan Biobank UK](https://pan.ukbb.broadinstitute.org/) and [Biobank Uk](https://biobank.ndph.ox.ac.uk/showcase/search.cgi) for the purpose of category description. A file concerning ICD9 and ICD10 from the documentation on [GitHub](https://github.com/atgu/ukbb_pan_ancestry)  was utilized to correctly integrate these two projects because there were several instances where the names of phenotypes varied. A unique category was created for the few dozen phenotypes that were produced as a result of combining multiple phenotypes from Biobank Uk but were not included there. The scipt also includes tools for preparing data and displaying results.

[read-prepare-data.R](https://github.com/ippas/imdik-zekanowski-sportwgs/blob/master/preprocessing/prs-preprocessing/r-analysis/read-prepare-data.R)
The script is responsible for rading metadata, results of prs scores read file with icd9, icd10, download information about phenotypes from Biobank UK, and prepared data to statistics.

## IX. Dimensiontality analysis on PRS scores.
The analysis was based on PRS scores from nine models that were deemed significant at stage VIII Statistical Analysis. The goal of the analysis was to reconstruct the athletes belonging to the group of endurance and speed athletes based on PRS scores. The process was conducted using the [dimensional-analysis.R](http://io/matprojects/imdik-zekanowski-sportwgs/preprocessing/prs-preprocessing/r-analysis/dimensionality-analysis/dimensional-analysis.R) script, which performed the following tasks:
1. Required needed packages and functions are located in the [dimensioanal-analysis-class.R](https://github.com/ippas/imdik-zekanowski-sportwgs/blob/master/preprocessing/prs-preprocessing/r-analysis/dimensionality-analysis/dimensional-analysis-class.R)
2. Prepared a data frame with the nine significant models.
3. Removed any similar models based on correlation (with a threshold of 0.98), leading to the removal of "xanthine oxidase inhibitor anti-gout agent" and "colchicine" phenotypes.
4. Conducted PCA analysis on the PRS scores.
5. Carried out a t-test on each PC for "speed" versus "endurance".
6. Selected the PC with the strongest p-value.
7. Using the two significant PCs, carried out [Linear Discriminant Analysis (LDA)](https://en.wikipedia.org/wiki/Linear_discriminant_analysis) to predict the group to which the athletes belong to either "endurance" or "speed"
8. Summarized the LDA model.
9. Created a summary plots of the model, which included a confusion matrix, histogram of a group, ROC curve, and a plot showing the classification of observations based on LDA.
10. Conducted a t-test between the values of endurance and speed.
11. To test the results, carried out 1000 permutations on random data, drawing samples from both endurance and speed athletes' groups.
12. On the random sets, statics were calculated in the same way as described in point VIII Statistical Analysis.
13. During permutation of sets, the terminal p-value may vary as follows:
 - if there was no significant phenotype, the p-value of the analysis would be equal to 1
 - if there was only one significant phenotype, just that p-value would be described in the results of dimensional analysis
 - if there was only one significant PC, just that p-value would be described in the results of dimensional analysis
 - if there were two significant PCs (with a p-value threshold of 0.001), LDA would be calculated and a p-value would be obtained from the t-test between endurance and speed

 
## IX. Dimensionality analysis on variants.
Additionally, a dimensionality analysis is executed on variants from nine significant phenotypes to check if it is possible to classify using single variants for endurance and speed athletes. The first step is to prepare the `vcf` files for analysis using the script [preprare-vcf-dimensionality-variants.sh](https://github.com/ippas/imdik-zekanowski-sportwgs/blob/master/preprocessing/prs-preprocessing/r-analysis/dimensionality-analysis/prepare-vcf-dimensionality-variants.sh), which is run using the command:
```
sbach preprocessing/prs-preprocessing/r-analysis/dimensionality-analysis/prepare-vcf-dimensionality-variants.sh 
```

The script performs the following steps which are prepared on the basis of example [part1](https://rpubs.com/WyattK1/982025) and [part2](https://rpubs.com/rohanrajiv1112/984215):
1. [prepare-rsid.py](https://github.com/ippas/imdik-zekanowski-sportwgs/blob/master/preprocessing/prs-preprocessing/r-analysis/dimensionality-analysis/prepare-rsid.py) is executed, which is responsible for:
 - isolating `rsid.txt` of variants from significant models and obtaining unique variants (number of variants: 10668)
 - Additionally, `rsid` with an impact on the phenotype greater than 0.25 are chosen to check that only a part of variants have an impact on the belonging to a group of athletes
 2. Filtering variants from the `vcf` file
  - for all significant models: n = 8763
  - for variants with an impact greater than 0.25: n = 95

On the prepared `vcf` file, dimensionality analysis was executed using [dimensionality-analysis-variants.R](https://github.com/ippas/imdik-zekanowski-sportwgs/blob/master/preprocessing/prs-preprocessing/r-analysis/dimensionality-analysis/dimensionality-analysis-variants.R), which performs the following tasks:
- requiring the prepared vcf file
- recording genotype from text to a number based on the codomination model (./. = NA, 0/0 = 0, 0/1 = 1, 1/1 = 2, 0/2 = 1, 1/2 = etc.)
- finding NA values and removing variants if more than 50% of the values are missing (no such variants were found)
- executing PCA analysis on the scaled and centered data
- creating visualizations for the first PCs
- additionally, the analysis can be calculated for variants with an impact on the phenotype greater than 0.25
- results of dimensionality analysis on PRS scores and all variants was saved to [html report](https://rawcdn.githack.com/ippas/imdik-zekanowski-sportwgs/47b5099a90398c23724f241b9131c096405a6e9a/analysis/reports-prs/report-dimensional-analysis.html) 
