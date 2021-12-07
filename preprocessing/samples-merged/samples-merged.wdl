workflow merge {
  #call merge_samples
  call merge_1kg_samples
}

task merge_samples {
  command <<<
    echo '123'
    module load plgrid/tools/bcftools/1.9

    bcftools merge $(ls /net/archive/groups/plggneuromol/imdik-zekanowski-sportwgs/data/genotyped-vcf-gz/*.vcf.gz) | bgzip -c > samples-merged.vcf.gz

  >>>
  
  output {
    File samples_merged = "samples-merged.vcf.gz"
  }

}

task merge_1kg_samples {
  command <<<
    echo '123'
    module load plgrid/tools/bcftools/1.9
   
    bcftools merge $(ls /net/archive/groups/plggneuromol/imdik-zekanowski-sportwgs/data/prs-data/1kg.rsid.chr.vcf.gz /net/archive/groups/plggneuromol/imdik-zekanowski-sportwgs/data/prs-data/samples-merged.vcf.gz) | 
      bgzip -c > 1kg-samples-merged.vcf.gz
  >>>
 
  output {
    File kg_samples_merged = "1kg-samples-merged.vcf.gz"
  }

}
