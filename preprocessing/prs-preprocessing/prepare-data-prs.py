##########################
# import needed packages #
##########################
import glob
import pandas as pd
import json
import multiprocessing
import argparse


parser = argparse.ArgumentParser()

parser.add_argument("-i", "--input_path", help="Path for json files")
parser.add_argument("-o", "--output", help="Output file")

args = parser.parse_args()

def sample_info_prs(json_file):
    tmp_list = json_file.replace(args.input_path, '').split("-")
    tmp_json = json.load(open(json_file))
    sample_info = [tmp_list[0],
                '-'.join(tmp_list[1:7]),
                '-'.join(tmp_list[7:9]).replace('.yml', ''), 
                tmp_json['score_model']['value'],
                tmp_json['score_model']['genotyping_alleles_count'],
                tmp_json['score_model']['imputing_alleles_count'],
                tmp_json['score_model']['af_alleles_count'],
                tmp_json['score_model']['missing_alleles_count']]
                

    return(sample_info)

json_files = glob.glob(args.input_path+"*json")

a_pool = multiprocessing.Pool()

result = a_pool.map(sample_info_prs, json_files)

# Create data frame from list
prs_score_df = pd.DataFrame(result,
                            columns=['sample', 'model', 'p-value', 'prs_score', 'genotyping_alleles_count',
                            'imputing_alleles_count', 'af_alleles_count', 'missing_alleles_count'])


prs_score_df.to_csv(args.output, sep='\t', index=False)
