# PRS analysis
Preprocessing on Cyfronet on Prometheus.

To prepare data for polygenic risk score (PRS) analysis execute genotyped gvcf file for sportsmen [using files](https://github.com/ippas/imdik-zekanowski-sportwgs/tree/master/preprocessing) and to run script used command:

```
sbatch preprocessing/samples-merged/gvcf-genotype-by-vcf.sh
```

Before choosing the control population prepare a table with metadata about sportsmen using sportsmen-pheno.csv and connect this with integrated_call_samples_v3.20130502.ALL.panel file which contains information about 1000 genomes. To prepare a file with metadata was execute a command:

```
(cat data/prs-data/integrated_call_samples_v3.20130502.ALL.panel | 
     sed '1d' | 
     awk '{print $0"\t1kg"}' && 
cat data/external-data/sporstmen-pheno.csv | 
     sed '1d; s/"//g' | 
     awk '{print $4"\t"$2"\tsporstmen\tnone\tsportsman"}')  | 
sed '1i\\sample\tpop\tsuper_pop\tgender\tgroup' > data/prs-data/1kg-sportsmen-pheno.tsv

```
In the first step to prepare the control group, was merged all genotyped samples for the athlete and next connected with samples from 1000 genomes inside 1kg.rsid.chr.vcf.gz, to run the script which executes this use command which [uses files from](https://github.com/ippas/imdik-zekanowski-sportwgs/tree/master/preprocessing), which have two tasks first merge all sportsmen genotype, and second merge them with 1kg.rsid.vcf.gz:

```
sbatch preprocessing/samples-merged/samples-merged.sh
```

The next step was to execute using [prs-control-pca.ipynb]() which used python version 3.7.7 and 0.2.79 version of [hail package](https://hail.is/). Inside script merging all samples and preparing a metadata file was read and reduced the size of data by drawing rows from vcf file with a probability equal to 0.001 for each line, as a result of that was left about 80 thousand lines, also the value "inf" which are in sportsmen samples in the field QUAL was replaced to 50. To the data was added metadata information about belonging to the population, for 44 genotyped from 1kg.rsid.chr.vcf.gz had no information, so genotyped with a missing population was removed. On prepare sample was run principal component analysis (PCA) with  [Hardy-Weinberg normalized genotype](https://hail.is/docs/0.2/methods/genetics.html#hail.methods.hwe_normalized_pca). The PC1 and PC2 plot was drawn and filtered genotypes based on median absolute deviation (MAD), where chose sample <img src="https://render.githubusercontent.com/render/math?math=\pm6MAD"> distance from median sportsmen for PC1 and PC2 respectively, for two samples of sportsmen (B502 and B506) were outliers so were not in this range and not included in further analysis. After filtering the 7 AMR genotypes were captured so they were removed before the next PCA

 <img src="https://latex.codecogs.com/svg.latex?\Large&space;MAD=median(|X_{i}-\tilde{X}|)">
 <img src="https://render.githubusercontent.com/render/math?math=\tilde{X}=median(X)">

     Figure. 1. The plot of PC1 and PC2 before filtering
     Figure. 2. The plot of PC1 and PC2 after filtering

On filtering data again was performed PCA with HW-normalized, and draw a plot but this time for PC2 and PC3, because PC1 and PC2 separated sportsmen from other genotyped so assessment of group control was impossible. In the drawing plot again was done filtering, but now takes genotyped in <img src="https://render.githubusercontent.com/render/math?math=\pm5MAD"> distance from a median of PC2 and PC3.

     Figure 3. The plot of PC2 and PC3 berfore filtering.
     Figure 4. The plot of PC2 and PC3 after filtering

In the final remain, 100 sportsmen and 98 European genotyped. Was Prepare metadata file sportsmen-control-pheno.tsv and also vcf file sportsmen-control.vcf.bgz and sportsmen-control.vcf.bgz.tbi with sportsmen and control genotyped, and then change end name in terminal from .bgz to .gz and also changet it in .tbi file using command:

```
mv data/prs-data/sportsmen-control.vcf.bgz data/prs-data/sportsmen-control.vcf.gz &
mv data/prs-data/sportsmen-control.vcf.bgz.tbi data/prs-data/sportsmen-control.vcf.gz.tbi 
```

Before calculating models of prs using [polygenic](https://github.com/intelliseq/polygenic), for sportsmen-control.vcf.gz create file .idx.db [using files](https://github.com/ippas/imdik-zekanowski-sportwgs/tree/master/preprocessing/polygenic):

```
sbatch preprocessing/polygenic/polygenicmaker.sh
```
####Prepare models to prs analysis
Download file with info about features from UK biobank usic comand:
```
  wget -P data/prs-data/ https://pan-ukb-us-east-1.s3.amazonaws.com/sumstats_release/phenotype_manifest.tsv.bgz && mv data/prs-data/phenotype_manifest.tsv.bgz data/prs-data/phenotype_manifest.tsv.gz 
```

For these features prepare an input file for cromwell using the command:
```
zcat data/prs-data/phenotype_manifest.tsv.gz | \
  cut -f2-4 | \
  grep -v "[]:/?#@\!\$&'()*+,;=%[]" | \
  grep -v "|" | \
  sed 's/\t/\",\"/g; s/^/["/; s/$/"]/; 1d' | \
  tr "\n" "," | \
  sed 's/^/[/; s/,$/]\n}\n/; s/^/{\n\t"prepare_models.array_model_info"\: /' > preprocessing/prepare-models/inputs-prepare-models.json
```

To generate models from UK biobank prepare files needed in cromwell and run a script using the command:
```
  command with 
```

### Analysis prs with polygenic



### Analysis MAF in PLINK


##### testing command
Merged vcf sample usig commad:
```
bcftools merge $(ls *gz) | bgzip -c > ../interval-vcf/samples-merged.vcf.gz
```


# Prepare file with european population
wget ftp://ftp-trace.ncbi.nih.gov/1000genomes/ftp/release/20130502/integrated_call_samples_v3.20130502.ALL.panel

cat message.txt | tr ",\t" "\n"  | sed 's/\[//g; s/\]//g; s/ //g' | tr "'" "\n" | grep . | xargs -i bash -c 'grep {} integrated_call_samples_v3.20130502.ALL.panel' | grep 'EUR' > eur-population.tsv

# Command for polygenic
polygenic --vcf /net/archive/groups/plggneuromol/matzieb/projects/imdik-zekanowski-sportwgs/data/prs-data/athletes-control.vcf.gz --model HC710.yml --af /net/archive/groups/plggneuromol/matzieb/projects/imdik-zekanowski-sportwgs/data/prs-data/gnomad-sites-freqAF-v3.1.1.vcf.gz --af-field nfe -o /net/archive/groups/plggneuromol/matzieb/projects/imdik-zekanowski-sportwgs/preprocessing/polygenic/models

# Command to prepare file with metadata
(cat data/prs-data/integrated_call_samples_v3.20130502.ALL.panel | sed '1d' |  awk '{print $0"\t1kg"}' && cat data/external-data/sporstmen-pheno.csv | sed '1d; s/"//g' | awk '{print $4"\t"$2"\tsporstmen\tnoene\tsportmen"}')  | sed '1i\\sample\tpop\tsuper_pop\tgender\tgroup' > data/prs-data/sporstmen-1kg-pheno.tsv



# Prepare control for PRS analysis
In the first step to prepare control group, was merged all genotyped samples for athlete and next was conect with 
# Sampling row to PCA
zcat 1kg-samples-merged.vcf.gz | grep -vP '^##' | awk 'NR == 1 || NR % 10000 == 0' | sed 's/^#//' > output.merged

# Prepare data to reading in Rstudio

cat output.merged | grep -v "\./\.\:\.\:\." | grep -v "\./\." | sed 's/0\/0/0|0/g; s/0\/1/0|1/g; s/1\/0/1|0/g; s/1\/1/1|1/g' > tmp.output.merged

Some display math:
```math
e^{i\pi} + 1 = 0
```
and some inline math, $`a^2 + b^2 = c^2`$.
```
$\bar x$   
\newcommand*\conj[1]{\bar{#1}}
\newcommand*\mean[1]{\bar{#1}}
#or for a string   
$\overline {xyzabc}$   
\documentclass{standalone}

\usepackage{amsmath}

\begin{document}
  $\begin{array}{r}
    a+b+c\\
    a+b^3+c\\
    a+\overline{b}+c\\
    a+\overline{b}^3+c\\
    a+\bar{b}+c\\
    a+\bar{b}^3+c\\
    a+\overline{b^3}+c\\
    a+\bar{b^3}+c\\
    a+b+c
  \end{array}$
\end{document}
```

<img src="https://render.githubusercontent.com/render/math?math=\tilde X">
<img src="https://render.githubusercontent.com/render/math?math=\pm ">
