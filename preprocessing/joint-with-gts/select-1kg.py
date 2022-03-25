#!/usr/bin/env python3

import hail as hl
hl.init(tmp_dir='/net/scratch/people/plggosborcz', spark_conf={'spark.driver.memory': '90G', 'spark.executor.memory': '90G'}, default_reference='GRCh38') 

europeans = hl.import_table('/net/archive/groups/plggneuromol/imdik-zekanowski-sportwgs/data/external-data/1kg/europeans', delimiter = "\t", no_header = True)
to_keep = europeans['f0'].collect()



controls = hl.read_matrix_table('/net/archive/groups/plggneuromol/imdik-zekanowski-sportwgs/data/external-data/1kg/gnomad.genomes.v3.1.2.hgdp_1kg_subset_sparse.mt')
controls = controls.filter_cols(hl.literal(to_keep).contains(controls.s))
controls.write('/net/archive/groups/plggneuromol/imdik-zekanowski-sportwgs/data/external-data/1kg/1kg-europeans-sparse.ht')
