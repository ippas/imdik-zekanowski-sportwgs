workflow polygenicmaker_genotyped {
  Array[String] array_sample_genotyped
  Array[String] tmp_array_sample_genotyped = ["/net/archive/groups/plggneuromol/imdik-zekanowski-sportwgs/data/genotyped-vcf-gz/B102_genotyped-by-vcf.vcf.gz"]
  String singularity_image 
  
#  scatter ( sample_genotyped in array_sample_genotyped ) {
#    call tabix { input: sample_genotyped = sample_genotyped, singularity_image = singularity_image }
#  }
  
#  scatter ( sample_genotyped in array_sample_genotyped ) {
#    call polygenicmaker { input: sample_genotyped = sample_genotyped, singularity_image = singularity_image }
#  }

#  call polygenicmaker_gnomad { input: singularity_image = singularity_image }
#  call polygenicmaker_sportsmen_control { input: singularity_image = singularity_image }
  call polygenicmaker_sportsmen_merged { input: singularity_image = singularity_image }
}

task polygenicmaker {
  String sample_genotyped
  String singularity_image

  command <<<
    echo '123'
    singularity exec --bind /net/archive/groups/plggneuromol/ ${singularity_image} polygenicmaker vcf-index --vcf ${sample_genotyped}
  >>>
}


task polygenicmaker_gnomad {
  String singularity_image

  command <<<
    echo '123'
    singularity exec --bind /net/archive/groups/plggneuromol/ ${singularity_image} polygenicmaker vcf-index --vcf /net/archive/groups/plggneuromol/matzieb/projects/imdik-zekanowski-sportwgs/data/prs-data/gnomad-sites-freqAF-v3.1.1.vcf.gz
  >>>
}

task polygenicmaker_sportsmen_control {
  String singularity_image
  
  command <<<
    echo '123'
    singularity exec --bind /net/archive/groups/plggneuromol/ ${singularity_image} polygenicmaker vcf-index --vcf /net/archive/groups/plggneuromol/imdik-zekanowski-sportwgs/data/prs-data/sportsmen-control.vcf.gz
   >>>
}

task polygenicmaker_sportsmen_merged {
  String singularity_image

  command <<<
    echo '123'
    singularity exec --bind /net/archive/groups/plggneuromol/ ${singularity_image} polygenicmaker vcf-index --vcf /net/archive/groups/plggneuromol/imdik-zekanowski-sportwgs/data/prs-data/1kg-sportsmen-merged.vcf.gz.tbi
  >>>

}
  


