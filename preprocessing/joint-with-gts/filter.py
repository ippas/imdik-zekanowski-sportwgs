#!/usr/bin/env python3

import hail as hl
import sys                                                                                      

part = sys.argv[1]

hl.init(tmp_dir='/net/scratch/people/plggosborcz', default_reference='GRCh38')

rpmk = hl.read_table('/net/archive/groups/plggneuromol/imdik-zekanowski-gts/data/external-data/repeatmasker-extended-keyed.ht')
cov = hl.read_table('/net/archive/groups/plggneuromol/imdik-zekanowski-gts/data/external-data/gnomad/gnomad-cov-keyed.ht')

hl.import_vcf('/net/archive/groups/plggneuromol/imdik-zekanowski-gts/data/joint-with-sportsmen/vcf-parts/'+str(part)+'-part.vcf.gz', 
	reference_genome='GRCh38',
        force_bgz = True,
        array_elements_required = False).write('/net/scratch/people/plggosborcz/temp-mts/'+str(part)+'-part.mt')

mt = hl.read_matrix_table('/net/scratch/people/plggosborcz/temp-mts/'+str(part)+'-part.mt')
mt = mt.filter_rows(hl.is_defined(rpmk[mt.locus]), keep = False)

mt.checkpoint('/net/scratch/people/plggosborcz/temp-mts/'+str(part)+'-part-rpmk.mt')

mt = mt.filter_rows(hl.is_defined(cov[mt.locus]), keep = True)

mt.checkpoint('/net/scratch/people/plggosborcz/temp-mts/'+str(part)+'-part-cov.mt')



mt = mt.annotate_cols(group = hl.if_else(mt.s.contains('B'), 'sport', 'GTS'))
mt = mt.annotate_rows(dp_qc = hl.agg.group_by(mt.group, hl.agg.stats(mt.DP)),
                     gq_qc = hl.agg.group_by(mt.group, hl.agg.stats(mt.GQ)),
                     hwe = hl.agg.group_by(mt.group, hl.agg.hardy_weinberg_test(mt.GT)))

mt = mt.annotate_rows(n_below_dp_3 = hl.agg.group_by(mt.group, hl.agg.count_where(mt.DP < 3)),
                      n_below_gq_30 = hl.agg.group_by(mt.group, hl.agg.count_where(mt.GQ <30)))

mt.checkpoint('/net/scratch/people/plggosborcz/temp-mts/'+str(part)+'-qc.mt')

mt = mt.filter_rows((mt.dp_qc['sport'].mean > 5) &
                    (mt.dp_qc['GTS'].mean > 5) &
                    (mt.gq_qc['sport'].mean > 50) &
                    (mt.gq_qc['GTS'].mean > 50) &
                    (mt.hwe['sport'].p_value > 0.05) &
                    (mt.hwe['GTS'].p_value > 0.05) &
                    (mt.n_below_dp_3['sport'] < 3) &
                    (mt.n_below_gq_30['sport'] < 30) &
                    (mt.n_below_dp_3['GTS'] < 3) &
                    (mt.n_below_gq_30['GTS'] <30))

mt.checkpoint('/net/scratch/people/plggosborcz/temp-mts/'+str(part)+'-filtered.mt')

