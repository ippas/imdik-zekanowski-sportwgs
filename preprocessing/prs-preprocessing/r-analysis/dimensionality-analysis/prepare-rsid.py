import glob as glob
import os
import yaml
import sys

path_models = "data/prs-data/dimensionality-data/all-filtered-models/"

# create list of significant models
significant_modles = ["biobankuk-20151-both_sexes--forced_vital_capacity_fvc_best_measure-EUR",    
                      "biobankuk-30090-both_sexes--platelet_crit-EUR",
                      "biobankuk-30280-both_sexes--immature_reticulocyte_fraction-EUR",
                      "biobankuk-3063-both_sexes--forced_expiratory_volume_in_1_second_fev1_-EUR",
                      "biobankuk-allopurinol-both_sexes--na-EUR", 
                      "biobankuk-anti_gout_agent_microtuble_polymerization_inhibitor-both_sexes--na-EUR",
                      "biobankuk-egfrcreacys-both_sexes--estimated_glomerular_filtration_rate_cystain_c-EUR"]

# significant_modles = ["biobankuk-30280-both_sexes--immature_reticulocyte_fraction-EUR",
#                       "biobankuk-anti_gout_agent_microtuble_polymerization_inhibitor-both_sexes--na-EUR"]

list_risd_all_models = []
list_effect_size = []
list_rsid_effect_size = []
# loop over all models
for model in significant_modles:
    # read model
    with open(path_models + model + "-1e-08.yml", 'r') as ymlfile:
        cfg = yaml.load(ymlfile)

    # get list of rsids
    list_rsid = list(cfg["score_model"]["variants"].keys())

    for rsid in list_rsid:
        effect_size = cfg["score_model"]["variants"][rsid]["effect_size"]
        list_effect_size.append(effect_size)
        list_rsid_effect_size.append([rsid, effect_size])

    # append to list
    list_risd_all_models.extend(list_rsid)


# unique list of rsids
list_risd_all_models = list(set(list_risd_all_models))

# filter from list_rsid_effect_size only rsids with absolute effect size > 0.25
list_rsid_effect_size = [item for item in list_rsid_effect_size if abs(item[1]) > 0.25]


# get firt element of each nested list_resid_effect_size
list_risd_impact_0_25 = [item[0] for item in list_rsid_effect_size]

list_risd_impact_0_25 = ["^#"] + ["\t" + item + "\t" for item in list_risd_impact_0_25]

with open("data/prs-data/dimensionality-data/rsid-impact-0.25.txt", "w") as f:
    f.writelines([x + "\n" for x in list_risd_impact_0_25])

print(list_risd_impact_0_25[0:10])

list_risd_all_models = ["^#"] + ["\t" + item + "\t" for item in list_risd_all_models]

print(list_risd_all_models[0:10])
# write to file
with open("data/prs-data/dimensionality-data/rsid-significant-models.txt", "w") as f:
    f.writelines([x + "\n" for x in list_risd_all_models])


