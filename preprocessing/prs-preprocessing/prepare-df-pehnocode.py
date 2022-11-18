import json 
import pandas as pd

json_file = "data/prs-data/phenocode-data.js"

with open(json_file ) as f:
    phenocode_raw = f.read().replace('\\\\', '\\').replace('\\\'', '\\\\\'')
phenocode = json.loads(phenocode_raw[96:-7])

df = pd.DataFrame.from_records(phenocode)


df.to_csv('data/prs-data/phenocode-data.tsv', sep="\t", index=False)