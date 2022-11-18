#############
# read data #
#############
# read data with prs_score
prs_results_rm_alternate_loci <- read.table('data/prs-data//prs-score-rm-alternate-loci.tsv', header = TRUE) %>%
  rename(p.value_variants = p.value)

# read metadata about samples
# sportsmen_control_polish
sportsmen_control_polish <- read.table('data/prs-data/sportsmen-control-polish-control-pheno.tsv', header = TRUE)

# add metadata for resuts prs
prs_results_rm_alternate_loci_pheno <- left_join(sportsmen_control_polish,
                                                 prs_results_rm_alternate_loci,
                                                 by = "sample")


# read phenocode-data from pan biobank uk
phenocode_data <- read.csv("data/prs-data/phenocode-data.tsv", sep = "\t") %>%
  .[, 1:38] %>%
  mutate(model_sign = paste(phenocode, pheno_sex, coding, sep = "-"))

# read data about discipline sportsmen
sportsmen_pheno <- read.table('data/prs-data/sportsmen-pheno.tsv', sep = '\t', header = T) %>%
  group_by(sport) %>%
  nest() %>%
  mutate(n = map(data, ~nrow(.x))) %>%
  unnest(c(data, n)) %>% 
  as.data.frame()


prs_results_with_sport <- prs_results_rm_alternate_loci_pheno %>%
  left_join(sportsmen_pheno, by = c("sample" = "sample_id"))


################################################
# download data for all fields from biobank uk #
################################################
read_html("https://biobank.ndph.ox.ac.uk/showcase/cats.cgi") %>%
  html_elements(xpath = paste0('.//div[@class = "tabbertab"]/h2[text() = "', "277 Origin Categories", '"]')) %>% 
  html_elements(xpath = '..') %>%
  html_elements(xpath = './/table') %>%
  html_table() %>% 
  as.data.frame() %>% 
  filter(grepl("[+]", Items)) %>% .[,1] -> origin_categories_main_vector

httr::GET("http://cran.r-project.org/Rlogo.jpg", config = httr::config(connecttimeout = 120))

# # download data about field from biobank UK
# read_tsv("https://biobank.ndph.ox.ac.uk/ukb/scdown.cgi?fmt=txt&id=1") %>% 
#   as.data.frame() %>%
#   select(field_id, notes) %>%
#   group_by(field_id) %>%
#   mutate(biobank_data = map(field_id, ~data_field_biobank(.x))) -> field_data_biobank

# # save data about fields to file
# save(field_data_biobank, file = "data/prs-data/field_data_biobank.RData")
load("data/prs-data/field_data_biobank.RData")

field_data_biobank

# preprocessing field data
field_data_biobank %>% 
  mutate(data_category = map(biobank_data, function(x) {
    x %>% .$data %>% select(category)
  })) %>%
  mutate(category_df = map(biobank_data, function(x){
    x %>% .$categories 
  })) %>% 
  mutate(category_id = map(category_df, ~.x$Category.ID),
         category_description = map(category_df, ~.x$Description)) %>% 
  unnest(c(category_id, category_description)) %>% 
  unnest(data_category) %>%  
  select(-c(biobank_data, category_df)) %>% 
  as.data.frame() %>%
  # rename(Field.ID = field_id) %>% # change from field_id to Field.ID
  mutate(field_id = as.character(field_id)) %>% 
  mutate(category = {str_replace_all(category, "[[:punct:]]", " ") %>% 
      str_squish() %>% str_trim() %>% tolower()}) -> field_category_preprocessing

field_category_preprocessing %>% head

# prepare df with phenocode for phenotype prescription
phenocode_data %>% 
  select(trait_type, phenocode) %>% 
  mutate(phenocode = {str_replace_all(phenocode, "[[:punct:]]", " ") %>% 
      str_replace_all(., "[[|]]", " ") %>%
      str_squish() %>% 
      str_trim() %>% 
      str_replace_all(., " ", "_") %>%
      tolower()}) %>%
  filter(trait_type == "prescriptions") %>%
  mutate(resource_field = "42039") -> phenocode_data_preprocessing

phenocode_data_preprocessing %>% 
  add_samples_results(prs_samples_results = prs_results_rm_alternate_loci_pheno)

# read icd9 data
icd9 <- read_tsv("https://raw.githubusercontent.com/atgu/ukbb_pan_ancestry/master/data/UKB_PHENOME_ICD9_PHECODE_MAP_20200109.txt") %>%
  as.data.frame() %>%
  .[, c(1, 2, 6)] %>%
  set_colnames(c("icd", "icd_category", "phecode")) %>%
  mutate(icd = tolower(icd)) %>%
  mutate(field = "41270")

# read icd10 data
icd10 <- read_tsv("https://raw.githubusercontent.com/atgu/ukbb_pan_ancestry/master/data/UKB_PHENOME_ICD10_PHECODE_MAP_20200109.txt") %>%
  as.data.frame() %>%
  .[, c(1, 2, 6)] %>%
  set_colnames(c("icd", "icd_category", "phecode")) %>%
  mutate(icd = tolower(icd)) %>%
  mutate(field = "41270")

