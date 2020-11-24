#this script annotates

import hail as hl

#for i in ['001', '002', '003', '004', '005', '006', '007', '008', '009',
#    '010', '011', '012', '013', '014', '015', '016', '017', '018', '019', '020']:


#mt = hl.read_matrix_table('gs://hail-data/mts/part001-rpmk-cov.mt')

gnomad = hl.read_table(gs://gcp-public-data--gnomad/release/3.1/ht/genomes/gnomad.genomes.v3.1.sites.ht)

a = str(gnomad.describe())

file2write=open("gs://hail-data/gnomad-description",'w')
file2write.write(a)
file2write.close()
