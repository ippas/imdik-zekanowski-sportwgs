devtools::install_github("timelyportfolio/sunburstR")
require(sunburstR)

remotes::install_github("rmgpanw/codemapper")
require(codemapper)

install.packages(c("rtf"), repos = "http://cran.r-project.org")
require(rtf)





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

# download data about field from biobank UK
read_tsv("https://biobank.ndph.ox.ac.uk/ukb/scdown.cgi?fmt=txt&id=1") %>% 
  as.data.frame() %>%
  select(field_id, notes) %>%
  group_by(field_id) %>%
  mutate(biobank_data = map(field_id, ~data_field_biobank(.x))) -> field_data_biobank

# save data about fields to file
save(field_data_biobank, file = "field_data_biobank.RData")
load("/home/mateusz/field_data_biobank.RData")

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
  unnest(data_category) %>%  head
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


# preprocessing result of statistcs
prs_statistic_preprocessing(endurance_speed_results) %>% 
  add_biobank_info() %>%
  filter(p.value_variants == "1e-08") %>% 
  filter_statistcs_prs(type_category = "12_Core_Categories",
                       t_test_threshold = 0.05,
                       shapiro_test_threshold = 0.05,
                       n_cases_EUR = 2000) %>%
  # filter(category_id %in% origin_categories_main_vector) %>% 
  # filter(category_id %in% c(100091, 2000, 100080))
  filter(category_id %in% c(713, 717)) %>% 
  add_samples_results(., prs_samples_results = prs_results_rm_alternate_loci_pheno) -> df_top_endurance_speed

# prepare models with fdr = 0.25 for filtered category_id
prs_statistic_preprocessing(endurance_speed_results) %>% 
  add_biobank_info() %>%
  filter(p.value_variants == "1e-08") %>% 
  filter_statistcs_prs(type_category = "277_Origin_Categories",
                       t_test_threshold = 0.05,
                       shapiro_test_threshold = 0.05,
                       n_cases_EUR = 2000) %>%
  filter(category_id %in% origin_categories_main_vector) %>%
  filter(category_id %in% c(100091, 100080, 2000, 100071, 100006, 100078, 100013, 100081, 17518, 3000)) %>%
  # filter(FDR_category < 0.25) %>% 
  filter(category_id %in% c(100091, 100071, 100078)) %>%
  add_samples_results(., prs_samples_results = prs_results_rm_alternate_loci_pheno) -> df_top_endurance_speed


# create plot
df_top_endurance_speed %>%
  filter(group == "sportsman") %>%
  group_by(category_description) %>%
  nest() %>% 
  mutate(graph_labels = map(data, ~graph_labels(
    .x,
    columns_name = c("model", "FDR_category", "prs_midle"),
    prefix = "FDR"
  ))) %>% 
  mutate(heights = map(graph_labels, ~ceiling(nrow(.x)/3))) %>%
  mutate(plot = map(
    data,
    ~ plot_prs(
      .x,
      prs_score = prs_score,
      fill = pop,
      color = pop,
      ncol = 3,
      title = category_description,
      graphLabels = graph_labels[[1]],
      size = 18,
      bins = 20
    )
  )) -> endurace_speed_to_plot


wrap_plots(endurace_speed_to_plot$plot) +
  plot_annotation(title = "277 Origin Categories",
                  theme = theme(plot.title = element_text(size = 20))) +
  plot_layout(
    ncol = 1,
    guides = "collect",
    heights =  unlist(endurace_speed_to_plot$heights)
  ) & theme(legend.position = 'bottom') -> endurace_speed_plot


png('tmp_wgs/results/endurance-speed-origin-categories.png', width = 2480, height = 3508)
endurace_speed_plot
dev.off()


summary_group <- function(data) {
  data %>%
    .[, c(1, 2, 3, 5, 15, 16)] %>%
    unique() %>%
    group_by(pop, super_pop, group, category_id, category_description) %>%
    nest() %>%
    mutate(n = map(data, ~ nrow(.x))) %>%
    unnest(n) %>%
    select(-data) %>%
    as.data.frame() -> summary_group
  
  return(summary_group)
}

# prepare html for endurance vs speed --> origin categories
df_top_endurance_speed %>%
  filter(group == "sportsman") %>%
  summary_group() -> summary_group_endurance_speed
  
df_top_endurance_speed %>%
  model_summary_prs() -> model_summary_endurance_speed



rmarkdown::render(input = "/home/mateusz/tmp_wgs/results/template-prs-results.Rmd", 
                  output_file = sprintf("prs-origin-categories-0.05.html"),
                  params = list(plot = endurace_speed_plot, 
                                df_summary = df1,
                                df_stat = df2))

rm(summary_group_endurance_speed, model_summary_endurance_speed)
  
  
# save plot
# dev.off()
# png('tmp_wgs/results/endurance-speed-core-categories.png', width = 2480, height = 3508)
# endurace_speed_plot
# dev.off()







addHeader(rtf, title = "12 Core Categories")
wrap_plots(endurace_speed_plot$plot) +
  plot_annotation(title = "12 Core Categories",
                  theme = theme(plot.title = element_text(size = 20))) +
  plot_layout(ncol = 1, guides = "collect") &
  theme(legend.position = 'bottom')  -> tmp_plot


addPlot(rtf,plot.fun=print,width=6.5,height=9,res=300, tmp_plot)

done(rtf)




species <- c("setosa", "versicolor", "virginica")

sapply(species, function(x) {
  rmarkdown::render(input = "/home/mateusz/tmp_wgs/results/input.Rmd", 
                    output_file = sprintf("iris_params_%s.html", x),
                    params = list(species = x, path = "/home/mateusz/tmp_wgs/results/endurance-speed-core-categories.tsv"))
})

rmarkdown::render(input = "/home/mateusz/tmp_wgs/results/input.Rmd", 
                  output_file = sprintf("iris_params.html", x),
                  params = list(species = "setosa", 
                                path = "/home/mateusz/tmp_wgs/results/endurance-speed-core-categories.tsv",
                                df = df_top_endurance_speed,
                                plot=tmp_plot))
