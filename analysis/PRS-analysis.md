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
     awk '{print $4"\t"$2"\tsporstmen\tnoene\tsportsman"}')  | 
sed '1i\\sample\tpop\tsuper_pop\tgender\tgroup' > data/prs-data/1kg-sportsmen-pheno.tsv
```
In the first step to prepare the control group, was merged all genotyped samples for the athlete and next connected with samples from 1000 genomes inside 1kg.rsid.chr.vcf.gz, to run the script which executes this use command which [uses files from](https://github.com/ippas/imdik-zekanowski-sportwgs/tree/master/preprocessing), which have two tasks first merge all sportsmen genotype, and second merge them with 1kg.rsid.vcf.gz:

```
sbatch preprocessing/samples-merged/samples-merged.sh
```

The next step was to execute using prs-control-pca.ipynb which used python version 3.7.7 and 2.64 version of [hail package](https://hail.is/). Inside script merging all samples and preparing a metadata file was read and reduced the size of data by drawing rows from vcf file with a probability equal to 0.001 for each line, as a result of that was left about 80 thousand lines, also the value "inf" which are in sportsmen samples in the field QUAL was replaced to 50. To the data was added metadata information about belonging to the population, for 45 genotyped from 1kg.rsid.chr.vcf.gz had no information, so genotyped with missing metadata was removed. On prepare sample was run principal component analysis (PCA) with [Hardy-Weinberg normalized genotype](https://hail.is/docs/0.2/methods/genetics.html#hail.methods.hwe_normalized_pca). The PC1 and PC2 plot was drawn and based on them filtered genotypes that are near to a group of athletes. 

Figure. 1. The plot of PC1 and PC2 before filtering
Figure. 2. The plot of PC1 and PC2 after filtering

On filtering data again was performed PCA with HW-normalized, and draw a plot but this time for PC2 and PC3, because PC1 and PC2 separated sportsmen from other genotyped so assessment of group control was impossible. In the drawing plot again was doing filtering on genotyped nearly of athletes population.

Figure 3. The plot of PC2 and PC3 berfore filtering.
Figure 4. The plot of PC2 and PC3 after filtering




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

<img src="https://render.githubusercontent.com/render/math?math=\tilde x">
