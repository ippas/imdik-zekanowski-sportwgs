#this script makes a large matrix table, runs PCA and

import hail as hl

mts = []

for i in ['001', '002', '003', '004', '005', '006', '007', '008', '009', '011', '012', '013', '014', '015', '016', '017', '020']:

    mts.append(hl.read_matrix_table('gs://hail-data/mts/part'+i+'-filtered-anno.mt'))

mt = hl.MatrixTable.union_rows(*mts)
mt.write('gs://hail-data/mts/sportsmen.mt')
mt = hl.read_matrix_table('gs://hail-data/mts/sportsmen.mt')
mt_sample = mt.sample_rows(0.001)
eigenvalues, pcs, _ = hl.hwe_normalized_pca(mt_sample.GT)
mt_sample = mt_sample.annotate_cols(scores = pcs[mt_sample.s].scores)
mt = mt.annotate_cols(scores = pcs[mt.s].scores)

mt.write('gs://hail-data/mts/sportsmen-pca.mt')
mt_sample.write('gs://hail-data/mts/sportsmen-small.mt')
