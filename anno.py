#this script annotates the mt with gnomad, nearest genes and HPO

import hail as hl

gnomad = hl.read_table('gs://gcp-public-data--gnomad/release/3.1/ht/genomes/gnomad.genomes.v3.1.sites.ht')

genes = hl.read_table('gs://hail-data/external-data/genecode_v32.ht')
genes = genes.filter(hl.is_valid_contig(genes['hg38.knownGene.chrom'], reference_genome='GRCh38'))


start = genes['hg38.knownGene.txStart']
stop =  genes['hg38.knownGene.txEnd']
genes = genes.annotate(interval =
                        hl.locus_interval(genes['hg38.knownGene.chrom'],
                                          start,
                                          stop,
                                          reference_genome='GRCh38', includes_start=False))

start_long = hl.cond(genes['hg38.knownGene.txStart'] < 20000, 1, genes['hg38.knownGene.txStart'] - 20000)
stop_long =  hl.cond(hl.contig_length(genes['hg38.knownGene.chrom'], reference_genome='GRCh38') - genes['hg38.knownGene.txEnd'] < 20000, 
                hl.contig_length(genes['hg38.knownGene.chrom'], reference_genome='GRCh38'),
                genes['hg38.knownGene.txEnd'] + 20000)

genes = genes.annotate(interval_long = 
                        hl.locus_interval(genes['hg38.knownGene.chrom'], 
                                          start_long,
                                          stop_long,
                                          reference_genome='GRCh38'))



hpo = hl.import_table('gs://hail-data/external-data/hpo.tsv', impute = True, no_header=True)
genes = genes.key_by(genes['hg38.kgXref.geneSymbol'])
hpo = hpo.key_by(hpo.f0)
genes = genes.annotate(hpo = hpo.index(genes['hg38.kgXref.geneSymbol'], all_matches = True)['f1'])


for i in ['001', '002', '003', '004', '005', '006', '007', '008', '009',
    '010', '011', '012', '013', '014', '015', '016', '017', '018', '019', '020']:

	mt = hl.read_matrix_table('gs://hail-data/mts/part'+i+'-rpmk-cov.mt')
	mt = hl.split_multi_hts(mt)
	mt = mt.annotate_rows(gnomad_v3_1 = gnomad[mt.row_key])

	genes = genes.key_by(genes.interval)
	mt = mt.annotate_rows(within_gene = hl.array(hl.set(genes.index(mt.locus, all_matches=True)['hg38.kgXref.geneSymbol'])))

	mt = mt.annotate_rows(hpo = hl.array(hl.set(genes.index(mt.locus, all_matches=True)['hpo'])))

	genes = genes.key_by(genes.interval_long)
	mt = mt.annotate_rows(nearest_genes_20kb = hl.array(hl.set(genes.index(mt.locus, all_matches=True)['hg38.kgXref.geneSymbol'])))

	db = hl.experimental.DB(region='us', cloud='gcp')
	mt = db.annotate_rows_db(mt, 'DANN', 'clinvar_gene_summary', 'clinvar_variant_summary')
	mt.write('gs://hail-data/mts/part'+i+'-filtered-anno.mt')
