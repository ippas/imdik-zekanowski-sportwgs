workflow prs_analysis {
    Array[String] array_model_files

    scatter (model_files in array_model_files) {
        call polygenic { input: model_files = model_files }
    }

    # call polygenic
}

task polygenic {
    
    #String model_files = "biobankuk-008_52-both_sexes--intestinal_infection_due_to_c_difficile-EUR-1e-05.yml biobankuk-008_5-both_sexes--bacterial_enteritis-EUR-1e-05.yml biobankuk-008_6-both_sexes--viral_enteritis-EUR-1e-05.yml biobankuk-008-both_sexes--intestinal_infection-EUR-1e-05.yml biobankuk-010-both_sexes--tuberculosis-EUR-1e-05.yml biobankuk-038_1-both_sexes--gram_negative_septicemia-EUR-1e-05.yml biobankuk-038_2-both_sexes--gram_positive_septicemia-EUR-1e-05.yml biobankuk-038-both_sexes--septicemia-EUR-1e-05.yml biobankuk-041_1-both_sexes--staphylococcus_infections-EUR-1e-05.yml biobankuk-041_2-both_sexes--streptococcus_infection-EUR-1e-05.yml biobankuk-041_4-both_sexes--e_coli-EUR-1e-05.yml biobankuk-041-both_sexes--bacterial_infection_nos-EUR-1e-05.yml"
    String model_files
    String model_path
    String output_path
    String vcf_file

    command <<<
    data_path=/net/archive/groups/plggneuromol/imdik-zekanowski-sportwgs/data/prs-data
    for model in ${model_files}

    do
      singularity exec \
        --bind /net/archive/groups/plggneuromol/ \
        /net/archive/groups/plggneuromol/singularity-images/polygenic.sif pgstk pgs-compute \
          --vcf ${vcf_file} \
          --model ${model_path}/$model \
          --af $data_path/gnomad.3.1.vcf.gz \
          --af-field AF_nfe \
          -o ${output_path}
    done
    >>>
}