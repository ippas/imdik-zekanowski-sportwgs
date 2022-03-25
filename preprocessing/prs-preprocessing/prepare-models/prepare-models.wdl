workflow prepare_models {
  Array[Array[String]] array_model_info

 scatter (model_info in array_model_info) {
   call prepare_model { input: model_info = model_info }
 }

# call prepare_model
  
}

task prepare_model {
  
  Array[String] model_info
  String phenocode = model_info[0]
  String pheno_sex = model_info[1]
  String coding = model_info[2]

  # String phenocode = "benserazide / levodopa"
  # String pheno_sex = "both_sexes"
  # String coding = ""

 
  command <<<

    path_output=/net/scratch/people/plgmatzieb/prs-models/
    path_output_model=/net/archive/groups/plggneuromol/matzieb/projects/imdik-zekanowski-sportwgs/data/prs-models/
    path_model_below_15=/net/archive/groups/plggneuromol/matzieb/projects/imdik-zekanowski-sportwgs/data/prs-models/models-below-15
    
    echo "Create model for:"
    echo "phenocode: ${phenocode}"
    echo "pheno_sex: ${pheno_sex}"
    echo "coding: ${coding}"
    echo ""

    # change capital letters to lover and problematic sign to '_'
    if [[ "${phenocode}"  == *[:/?\ "#"@!$"'"\(\)\*+,\;=%\|\-]* ]]
    then 
        phenocode_mod=$(echo "${phenocode}" | \
          sed "s/[:/?\ #@!$\'\(\)\*+,\;=%\|\-]/_/g; s/_\+/_/g" | \
          tr '[:upper:]' '[:lower:]')  
    else 
        phenocode_mod=$(echo "${phenocode}" | tr '[:upper:]' '[:lower:]')
    fi


    for threshold in "1e-08" "1e-07" "1e-06" "1e-05"
    do
      singularity exec \
      --bind /net/archive/groups/plggneuromol,/net/scratch/people/plgmatzieb \
      /net/archive/groups/plggneuromol/singularity-images/polygenictk_2.1.5.sif \
      pgstk model-biobankuk \
        --code "${phenocode}" \
        --sex '${pheno_sex}' \
        --coding '${coding}' \
        --output-directory $path_output \
        --pvalue-threshold $threshold \
        --clumping-vcf /eur.phase3.biobank.set.vcf.gz \
        --source-ref-vcf /dbsnp155.grch37.norm.vcf.gz \
        --target-ref-vcf /dbsnp155.grch38.norm.vcf.gz \
        --gene-positions /ensembl-genes.104.tsv \
        --l $path_output/biobankuk-$phenocode_mod-${pheno_sex}-'${coding}'-$threshold-pgstk.log
    
      
      
      # create variable with file contain model
      model_file=$(ls $path_output | grep "biobankuk\-$phenocode_mod\-${pheno_sex}\-${coding}.*\-EUR\-$threshold.yml")

      # check in, that file with model exist
      if [ "$model_file" != "" ]; then
        number_variants=$(cat $path_output/$model_file | grep " rs" | wc -l)

      # checing if there are enough variants in model
        if [ $number_variants -gt 14 ]; then
          echo ""
          echo "Copying a model file to $path_output_model"
          echo "File with the model has $number_variants variants."
          echo ""

          cp $path_output/$model_file $path_output_model

          break

        elif [[ $number_variants -lt 15 && "$threshold" != "1e-05" ]]; then
          echo ""
          echo "File with a model at the threshold=$threshold has an insufficient nuber of variants, it has only $number_variants."
          echo "Creating a model file for the next threshold."
          echo ""

        else
          echo ""
          echo "Warning! The model has an insufficient number of 15 variants in the last threshold $threshold, have only $number_variants"
          echo "Nevertheless copying model file to $path_model_below_15"
          echo ""

          cp $path_output/$model_file $path_model_below_15

        fi

      else
        echo ""
        echo "File with a model at the threshold=$threshold does not exist."
        echo ""

      fi

    done

  >>>

}

