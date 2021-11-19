#!/usr/bin/env python3

import hail as hl
hl.init(tmp_dir='/net/scratch/people/plggosborcz', spark_conf={'spark.driver.memory': '90G', 'spark.executor.memory': '90G'}, default_reference='GRCh38') 

import os
files = os.listdir('/net/archive/groups/plggneuromol/imdik-zekanowski-sportwgs/data/gvcf/')

gvcfs = []

for f in files:
    if (f.find("tbi")) == -1:
        gvcfs.append('/net/archive/groups/plggneuromol/imdik-zekanowski-sportwgs/data/gvcf/'+f)

gvcfs.sort()


samples = []

for f in files:
    if (f.find("tbi")) == -1:
        samples.append((f.split('.'))[0])

samples.sort()


hl.experimental.run_combiner(gvcfs, out_file='/net/archive/groups/plggneuromol/imdik-zekanowski-sportwgs/data/joint/sport-sparse.mt',
                             tmp_path='/net/scratch/people/plggosborcz',
                             header = '/net/archive/groups/plggneuromol/imdik-zekanowski-gts/data/gvcf/header-460.txt',
                             sample_names = samples,
                             reference_genome='GRCh38', use_genome_default_intervals = True)
