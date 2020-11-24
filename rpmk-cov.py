# this script filters the vcf with repeatmasker track

import hail as hl

rpmk = hl.import_bed('gs://hail-data/external-data/repeatmasker_all',
        reference_genome='GRCh38',
        skip_invalid_intervals=True)

cov = hl.read_table('gs://gcp-public-data--gnomad/release/3.0.1/coverage/genomes/gnomad.genomes.r3.0.1.coverage.ht')
cov = cov.filter(cov.over_1 > 0.9)
cov = cov.key_by(cov.locus)

for i in ['001', '002', '003', '004', '005', '006', '007', '008', '009',
    '010', '011', '012', '013', '014', '015', '016', '017', '018', '019', '020']:

    hl.import_vcf('gs://hail-data/vcf/part'+i+'.vcf.gz',
        reference_genome='GRCh38',
        force_bgz = True,
        array_elements_required = False).write('gs://hail-data/mts/part'+i+'.mt')

        mt = hl.import_matrix_table('gs://hail-data/mts/part'+i+'.mt')

        mt = mt.filter_rows(hl.is_defined(rpmk[mt.locus]), keep = False)
        mt = mt.filter_rows(hl.is_defined(cov[mt.locus]), keep = True)

        mt.write('gs://hail-data/mts/part'+i+'-rpmk-cov.mt')
