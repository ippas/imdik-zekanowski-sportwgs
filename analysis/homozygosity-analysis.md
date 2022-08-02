
# Homozygosity documentation

## I. Prepare vcf file to `plink` analysis

From `.vcf` file was removed:
 -  indels
 -  multiallelic loci (max-alleles = 2)
 -  missing data (max-missing = 0.98)
To prepare data run:
```
sbatch preprocessing/prs-preprocessing/homozygosity-analysis.sh
``` 
## II. PLINK analysis
Filtering by Hardy-Weinberg with the command:
```
plink \
  --vcf data/homozygosity/filtmissing-biallelic-noindels-scpc-4.2.vcf.gz \
  --hwe 1e-25 \
  --recode vcf \
  --out data/homozygosity/hw-filtmissing-biallelic-noindels-sc-4.2

```

Filtering by maf (Minor Allele Frequency):
```
plink \
  --vcf data/homozygosity/hw-filtmissing-biallelic-noindels-sc-4.2.vcf \
  --maf 0.05 \
  --recode vcf \
  --out data/homozygosity/maf-hw-filtmissing-biallelic-noindels-sc-4.2
```

Linkage disequilibrium based SNP [pruning](https://zzz.bwh.harvard.edu/plink/summary.shtml). For each parameter pruning created folder, and inside the appropriate folder execute the command for pruning and homozygosity:
##### For parameters 50 5 and 0.5
```
mkdir data/homozygosity/prune-50-5-0.5/ &&
plink \
  --vcf data/homozygosity/maf-hw-filtmissing-biallelic-noindels-sc-4.2.vcf \
  --indep-pairwise 50 5 0.5 \
  --out data/homozygosity/prune-50-5-0.5/50-5-0.5
```

```
plink \
  --vcf data/homozygosity/maf-hw-filtmissing-biallelic-noindels-sc-4.2.vcf \
  --extract data/homozygosity/prune-50-5-0.5/50-5-0.5.prune.in  \
  --make-bed \
  --recode vcf \
  --out data/homozygosity/prune-50-5-0.5/prune-50-5-0.5-maf-hw
```

```
plink \
  --vcf data/homozygosity/prune-50-5-0.5/prune-50-5-0.5-maf-hw.vcf \
  --homozyg \
  --allow-extra-chr \
  --out data/homozygosity/prune-50-5-0.5/homozyg-200-prune-50-5-0.5 \
  --homozyg-kb 200 \
  --homozyg-het 1 \
  --homozyg-window-threshold 0.96
```

Corrected samples in file with IBD using the command:
```
cat data/homozygosity/prune-50-5-0.5/homozyg-200-prune-50-5-0.5.hom | \
  awk '{print $1"_"$2"\t"$0}' | \
  sed 's/_B/;B/; s/_N/;N/; s/_H/;H/; s/_4/;4/' | \
  sed 's/;.*\t//' | \
  awk '{$3=""; $2=""; sub("  ", ""); print}' | \
  sed 's/ /\t/g; s/FID_IID/FID/' > data/homozygosity/prune-50-5-0.5/homozyg-200-prune-50-5-0.5.tsv
```

##### For parameters 50 5 and 0.3
```
mkdir data/homozygosity/prune-50-5-0.3/ &&
plink \
  --vcf data/homozygosity/maf-hw-filtmissing-biallelic-noindels-sc-4.2.vcf \
  --indep-pairwise 50 5 0.3 \
  --out data/homozygosity/prune-50-5-0.3/50-5-0.3
```

```
plink \
  --vcf data/homozygosity/maf-hw-filtmissing-biallelic-noindels-sc-4.2.vcf \
  --extract data/homozygosity/prune-50-5-0.3/50-5-0.3.prune.in  \
  --make-bed \
  --recode vcf \
  --out data/homozygosity/prune-50-5-0.3/prune-50-5-0.3-maf-hw
```

```
plink \
  --vcf data/homozygosity/prune-50-5-0.3/prune-50-5-0.3-maf-hw.vcf \
  --homozyg \
  --allow-extra-chr \
  --out data/homozygosity/prune-50-5-0.3/homozyg-200-prune-50-5-0.3 \
  --homozyg-kb 200 \
  --homozyg-het 1 \
  --homozyg-window-threshold 0.96
```

Corrected samples in file with IBD using command:
```
cat data/homozygosity/prune-50-5-0.3/homozyg-200-prune-50-5-0.3.hom | \
  awk '{print $1"_"$2"\t"$0}' | \
  sed 's/_B/;B/; s/_N/;N/; s/_H/;H/; s/_4/;4/' | \
  sed 's/;.*\t//' | \
  awk '{$3=""; $2=""; sub("  ", ""); print}' | \
  sed 's/ /\t/g; s/FID_IID/FID/' > data/homozygosity/prune-50-5-0.3/homozyg-200-prune-50-5-0.3.tsv
```


## III. IBD analysis in  R
For results of homozygosity calculate in `homozygosity.R` per sample:
 - sum of region
 - sum for PHOM = 1
 - sum of kb > 1000kb
 - max region
 - sum of KB > 500kb

Despite the analysis of IBD for sporsmen, no definite conclusions can be made. The significant statistical differences found between Polish sportsmen and the control of the European population from 1000 genomes indicate that the sportsmen would be more homozygous. However, this is more effect by the fact that the Polish population is highly homozygous, so the prepared control of Europeans is inappropriate in this kind of analysis. In the case of performing statistics between sportsmen and Polish control, no significant statistical differences were found. However, in this case, the prepared control is four times smaller in size that the population of sportsmen (only t.test performed for two parameters: 1.  sum of region, 2. max  region).
The analysis in R for IBD was performed for the data pruned for the parameters: `--indep-pairwise 50 5 0.5`, because found more IBD regions (n = 3163) than for the parameters: `--indep-pairwise 50 5 0.3` (n = 1138)





