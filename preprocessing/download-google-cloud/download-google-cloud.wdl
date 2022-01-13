workflow download_google_cloud {
  # call download_sparse_matrix
  # call download_grch38
  # call download_genebass
  call download_subset_sample_meta
}

task download_sparse_matrix {


  command <<<
    echo '123'
    source /net/archive/groups/plggneuromol/matzieb/./venv/bin/activate

    gsutil cp -r gs://gcp-public-data--gnomad/release/3.1.2/mt/genomes/gnomad.genomes.v3.1.2.hgdp_1kg_subset_sparse.mt /net/archive/groups/plggneuromol/imdik-zekanowski-sportwgs/data/external-data/1kg

  >>>

}

task download_grch38 {
  command <<<
    echo '123'
    source /net/archive/groups/plggneuromol/matzieb/./venv/bin/activate

    gsutil cp -r gs://gcp-public-data--gnomad/resources/context/grch38_context_vep_annotated.ht /net/archive/groups/plggneuromol/imdik-zekanowski-sportwgs/data/external-data/vep38
  >>>
}


task download_genebass {
  command <<<
    echo '123'
    source /net/archive/groups/plggneuromol/matzieb/./venv/bin/activate

    gsutil cp -r gs://ukbb-exome-public/300k/results/results.mt /net/archive/groups/plggneuromol/imdik-zekanowski-sportwgs/data/external-data/genebass
  >>>
}

task download_subset_sample_meta {
  command <<<
    echo '123'
    source /net/archive/groups/plggneuromol/matzieb/./venv/bin/activate

    gsutil cp -r gs://gcp-public-data--gnomad/release/3.1.2/ht/genomes/gnomad.genomes.v3.1.2.hgdp_1kg_subset_sample_meta.ht /net/archive/groups/plggneuromol/imdik-zekanowski-sportwgs/data/external-data
  >>>
}

