# this script filters the vcf with repeatmasker track

import hail as hl


hl.import_vcf('gs://hail-data/vcf/part001.vcf.gz',
        reference_genome='GRCh38',
        force_bgz = True,
        array_elements_required = False).write('gs://hail-data/mts/part001.mt')

mt = hl.import_matrix_table('gs://hail-data/mts/part001.mt')

rpmk = hl.import_bed('gs://hail-data/external-data/repeatmasker_all',
        reference_genome='GRCh38',
        skip_invalid_intervals=True)

mt = mt.filter_rows(hl.is_defined(rpmk[mt.locus]), keep = False)


cov = hl.read_table('gs://gcp-public-data--gnomad/release/3.0.1/coverage/genomes/gnomad.genomes.r3.0.1.coverage.ht')
cov = cov.annotate(locus = hl.parse_locus(cov.locus, reference_genome='GRCh38'))
cov = cov.select(cov.locus, table.over_1)
cov = cov.annotate(locus = hl.parse_locus(cov.locus, reference_genome='GRCh38'))
cov = cov.filter(cov.over_1 > 0.9)
cov = cov.key_by(cov.locus)

mt = mt.filter_rows(hl.is_defined(cov[mt.locus]), keep = True)

mt.write('gs://hail-data/mts/part001-rpmk-cov.mt')
