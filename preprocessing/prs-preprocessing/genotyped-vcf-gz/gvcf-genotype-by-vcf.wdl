workflow gvcf_genotype_by_vcf_workflow {
  
#  Array[Array[String]] tmp_array_sample_info = [["B102", "/net/archive/groups/plggneuromol/imdik-zekanowski-sportwgs/data/gvcf/B102_uniq.g.vcf.gz", "/net/archive/groups/plggneuromol/imdik-zekanowski-sportwgs/data/gvcf/B102_uniq.g.vcf.gz.tbi"]]

  
  Array[Array[String]] array_sample_info
  
  scatter (sample_info in array_sample_info) {
     call gvcf_genotype_by_vcf { input: sample_info = sample_info }
  }
}


task gvcf_genotype_by_vcf {

  Array[String] sample_info

  String sample_id = sample_info[0]
  File sample_gvcf_gz = sample_info[1]
  File sample_gvcf_gz_tbi = sample_info[2]

  String task_name = "gvcf_genotype_by_vcf"
  String task_version = "2.0.2"
  Int? index
  String task_name_with_index = if defined(index) then task_name + "_" + index else task_name
  String docker_image
  String genotype_gvcfs_java_options
  String gatk_path = "/gatk/gatk"

  # vcf used for genotyping (if no bed provided) and merging (for example clinvar)
  File interval_vcf_gz
  File interval_vcf_gz_tbi
 
  # bed used for genotyping
  File? interval_bed_gz
  File? interval_bed_gz_tbi

  File intervals = select_first([interval_bed_gz, interval_vcf_gz])

  Boolean merge_annotations


  command <<<
    echo '123'

  # 1. GENOTYPING sample_gvcf_gz WITH interval_bed_gz

  ${gatk_path} --java-options "${genotype_gvcfs_java_options}" \
      GenotypeGVCFs \
      --allow-old-rms-mapping-quality-annotation-data \
      --lenient \
      --include-non-variant-sites \
      --intervals ${intervals} \
      --variant "${sample_gvcf_gz}" \
      --output genotyped-sample.vcf.gz \
      --reference /resources/reference-genomes/broad-institute-hg38/Homo_sapiens_assembly38.fa


  # 2. MERGING interval_vcf_gz WITH genotyped-sample.vcf.gz (TO CONTAIN ISEQ_CLINVAR_GENE_INFO)

  if [ "${merge_annotations}" = true ]; then
    bcftools merge genotyped-sample.vcf.gz ${interval_vcf_gz} | bgzip > temp.vcf.gz  2>> bcftools.stderr_log


  # 3. REMOVING irrelevant sample from interval_vcf_gz (syntetic_homo_sample IN CLINVAR)

    sample_name=$(bcftools query -l ${sample_gvcf_gz})
    bcftools view -s $sample_name temp.vcf.gz | bgzip > ${sample_id}_genotyped-by-vcf.vcf.gz  2>> bcftools.stderr_log
  else
    cp genotyped-sample.vcf.gz ${sample_id}_genotyped-by-vcf.vcf.gz
    tabix -f ${sample_id}_genotyped-by-vcf.vcf.gz

  fi

  
  zcat ${sample_id}_genotyped-by-vcf.vcf.gz | awk '$5!="." {print}' | bgzip > tmp.vcf.gz
  mv tmp.vcf.gz ${sample_id}_genotyped-by-vcf.vcf.gz
  
  tabix -p vcf ${sample_id}_genotyped-by-vcf.vcf.gz

#  cat bcftools.stderr_log >&2

#  if grep -q "^\[E::" bcftools.stderr_log; then
#    exit 1
#  fi

  >>>

  runtime {
    docker: docker_image
#    image: "/net/archive/groups/plggneuromol/singularity-images/intelliseqngs_gatk_4.1.7.0_hg38.1.0.1.sif"
    memory: "6G"
    cpu: 1
  }

  output {

    File genotyped_vcf_gz = "${sample_id}_genotyped-by-vcf.vcf.gz"
    File genotyped_vcf_gz_tbi = "${sample_id}_genotyped-by-vcf.vcf.gz.tbi"

  }

}
