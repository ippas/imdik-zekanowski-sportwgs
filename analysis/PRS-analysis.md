# PRS analysis

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
