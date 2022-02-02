workflow prepare_models {
  Array[Array[String]] array_model_info

#  scatter (model_info in array_model_info) {
#    call prepare_model { input: model_info = model_info }
#  }

  call prepare_model
  
}

task prepare_model {
  
#  Array[String] model_info
#  String phenocode = model_info[0]
#  String pheno_sex = model_info[1]
#  String coding = model_info[2]

  String phenocode = "S66"
  String pheno_sex = "both_sexes"
  String coding = ""

 
  command <<<
    echo '123'
    
    path=/net/archive/groups/plggneuromol/matzieb/projects/imdik-zekanowski-sportwgs/data/prs-data/data-preparation-models

    singularity exec \
    --bind /net/archive/groups/plggneuromol,/net/scratch/people/plgmatzieb \
    /net/archive/groups/plggneuromol/singularity-images/polygenictk-2.1.0.sif \
    pgstk model-biobankuk \
      --code ${phenocode} \
      --sex ${pheno_sex} \
      --coding '${coding}' \
      --output-directory /net/scratch/people/plgmatzieb/models-prs/tmp-test-singularity \
      --pvalue-threshold "1e-05" \
      --clumping-vcf $path/eur.phase3.biobank.set.vcf.gz \
      --source-ref-vcf $path/dbsnp155.grch37.norm.vcf.gz \
      --target-ref-vcf $path/dbsnp155.grch38.norm.vcf.gz \
      --gene-positions $path/ensembl-genes.104.tsv

  >>>

}

