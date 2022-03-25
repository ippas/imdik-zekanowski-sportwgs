workflow polygenicmaker_genotyped {
  Array[String] array_sample_genotyped
  Array[String] tmp_array_sample_genotyped = ["/net/archive/groups/plggneuromol/imdik-zekanowski-sportwgs/data/genotyped-vcf-gz/B102_genotyped-by-vcf.vcf.gz"]
  String singularity_image 
  
#  scatter ( sample_genotyped in array_sample_genotyped ) {
#    call tabix { input: sample_genotyped = sample_genotyped, singularity_image = singularity_image }
#  }
  
  scatter ( sample_genotyped in array_sample_genotyped ) {
    call polygenicmaker { input: sample_genotyped = sample_genotyped, singularity_image = singularity_image }
  }
}

task tabix {
  String sample_genotyped
  String singularity_image

  command <<< 
    echo '123'
    tabix -p vcf ${sample_genotyped}
  >>>

  runtime {
    image: singularity_image
    cpu: 1
  }

  output {
    File index_tbi = "${sample_genotyped}.tbi"
  }

}

task polygenicmaker {
  String sample_genotyped
  String singularity_image

  command <<<
    echo '123'
    singularity exec --bind /net/archive/groups/plggneuromol/ ${singularity_image}  polygenicmaker vcf-index --vcf ${sample_genotyped}
  >>>
  
#  runtime {
#
#    image: singularity_image
#    cpu: 1
#  }

}
