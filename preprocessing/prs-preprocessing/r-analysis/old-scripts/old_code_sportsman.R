
#######################################################
# prepare data for field and category from biobank uk #
#######################################################
get_category_biobank(category_listing = "14 Recommended Categories") %>% 
  unnest(fields_category) %>% 
  mutate(field_list = map(Field.ID, ~data_field_biobank(.x))) -> recommended_categories_data


get_category_biobank(category_listing = "12 Core Categories") %>% 
  unnest(fields_category) %>% 
  mutate(field_list = map(Field.ID, ~data_field_biobank(.x))) -> origin_categories_data


origin_categories_speed_endurance


endurance_speed_results %>% 
  select(-data) %>%
  as.data.frame() %>%
  mutate(model = as.character(model)) %>%
  mutate(code = {
    str_split_fixed(model, "-", n = 3)[, 2]
  }) %>%
  mutate(phenocode_description = {
    str_split_fixed(model, "-", n = 6)[, 5] %>% str_replace_all(., "_", " ")
  }) %>%
  mutate(code_dod = str_replace_all(code, "_", ".")) %>%
  left_join(., icd10[, c("icd", "icd_category", "field")], by = c("code_dod" = "icd")) %>%
  left_join(., icd10[, c("icd_category", "phecode", "field")], by = c("code_dod" = "phecode")) %>%
  mutate(icd10_category = ifelse(!is.na(icd_category.x), icd_category.x, icd_category.y)) %>%
  mutate(icd10_field = ifelse(!is.na(field.x), field.x, field.y)) %>%
  select(-c(icd_category.x, icd_category.y, field.x, field.y)) %>% # remove temporary column during merging icd10
  left_join(., icd9[, c("icd", "icd_category", "field")], by = c("code_dod" = "icd")) %>%
  left_join(., icd9[, c("icd_category", "phecode", "field")], by = c("code_dod" = "phecode")) %>%
  mutate(icd9_category = ifelse(!is.na(icd_category.x), icd_category.x, icd_category.y)) %>%
  mutate(icd9_field = ifelse(!is.na(field.x), field.x, field.y)) %>%
  select(-c(icd_category.x, icd_category.y, field.x, field.y)) %>% # remove temporary column during merging icd9
  mutate(icd_category = ifelse(!is.na(icd10_category), icd10_category, icd9_category) %>% tolower()) %>%
  mutate(icd_field = ifelse(!is.na(icd10_category), icd10_field, icd9_field)) %>%
  select(-c(icd9_category, icd10_category, icd9_field, icd10_field)) %>%
  # left_join(., biobank_resource_592, by = c("code" = "term_description")) %>%
  left_join(., phenocode_data_preprocessing, by = c("code" = "phenocode")) %>%
  mutate(description = str_trim(phenocode_description)) %>%
  mutate(field = ifelse(
    !is.na(icd_field),
    icd_field,
    ifelse(!is.na(resource_field),
           resource_field, code)
  )) %>% head
  .[, c(1:6, 8, 15)] %>%
  unique() -> endurance_speed_preprocessing

endurance_speed_preprocessing %>% tail



# merge result of statistics with field categories
endurance_speed_preprocessing %>% 
  left_join({
    field_category_preprocessing[, c("category_id", "field_id")] %>% unique()
  }, by = c("field" = "field_id")) %>% 
  left_join({
    field_category_preprocessing[, c("category_id", "category")] %>% unique()
  }, by = c("phenocode_description" = "category")) %>%
  mutate(category_id = ifelse(!is.na(category_id.x), category_id.x, category_id.y)) %>%
  select(-c(category_id.x, category_id.y)) %>% 
  unique() %>%
  left_join(., type_categories_df_biobank, by = "category_id") -> field_categories_results_speed_endurance












# # function to mapping data from pan biobank with biobank UK for interest categories
# pan_biobank_mapping_to_biobank <- function(category_data, statistics_results , pehnocode_data) {
#   # preprocessing results for categories
#   category_data  %>% 
#     mutate(data_category = map(field_list, function(x) {
#       x %>% .$data %>% select(category) 
#     })) %>% 
#     unnest(data_category) %>% 
#     select(-field_list) %>%
#     as.data.frame() %>%  
#     mutate(Field.ID = as.character(Field.ID)) %>%
#     mutate(category = tolower(category)) %>%
#     mutate(category = {str_replace_all(category, "[[:punct:]]", " ") %>% 
#         str_squish() %>% str_trim()}) -> category_data_preprocessing
#   
#   # prepare data for prescriptions from pan biobank
#   phenocode_data %>% 
#     select(trait_type, phenocode) %>% 
#     mutate(phenocode = {str_replace_all(phenocode, "[[:punct:]]", " ") %>% 
#         str_replace_all(., "[[|]]", " ") %>%
#         str_squish() %>% 
#         str_trim() %>% 
#         str_replace_all(., " ", "_") %>%
#         tolower()}) %>%
#     filter(trait_type == "prescriptions") %>%
#     mutate(resource_field = "42039") -> phenocode_data_preprocessing
#   
#   # prepare data for icd9 and icd10 
#   icd9 <- read_tsv("https://raw.githubusercontent.com/atgu/ukbb_pan_ancestry/master/data/UKB_PHENOME_ICD9_PHECODE_MAP_20200109.txt") %>%
#     as.data.frame() %>%
#     .[, c(1, 2, 6)] %>% 
#     set_colnames(c("icd", "icd_category", "phecode")) %>%
#     mutate(icd = tolower(icd)) %>%
#     mutate(field = "41270")
#   
#   
#   icd10 <- read_tsv("https://raw.githubusercontent.com/atgu/ukbb_pan_ancestry/master/data/UKB_PHENOME_ICD10_PHECODE_MAP_20200109.txt") %>% 
#     as.data.frame() %>% 
#     .[, c(1, 2, 6)] %>% 
#     set_colnames(c("icd", "icd_category", "phecode")) %>%
#     mutate(icd = tolower(icd)) %>%
#     mutate(field = "41270")
#   
#   read_tsv("https://biobank.ndph.ox.ac.uk/ukb/scdown.cgi?fmt=txt&id=1") %>% 
#     as.data.frame() %>% 
#     .[,1] -> all_field_biobank
#   
#   # maping results statistics with biobank UK
#   statistics_results %>% 
#     select(-data) %>% 
#     as.data.frame() %>% 
#     mutate(model = as.character(model)) %>% 
#     mutate(code = {str_split_fixed(model, "-", n = 3)[,2]}) %>% 
#     mutate(description = {str_split_fixed(model, "-", n = 6)[,5] %>% str_replace_all(., "_", " ")}) %>%
#     mutate(code_dod = str_replace_all(code, "_", ".")) %>%  
#     left_join(., icd10[, c("icd", "icd_category", "field")], by = c("code_dod" = "icd")) %>%
#     left_join(., icd10[, c("icd_category", "phecode", "field")], by = c("code_dod" = "phecode")) %>%
#     mutate(icd10_category = ifelse(!is.na(icd_category.x), icd_category.x, icd_category.y)) %>% 
#     mutate(icd10_field = ifelse(!is.na(field.x), field.x, field.y)) %>% 
#     select(-c(icd_category.x, icd_category.y, field.x, field.y)) %>% # remove temporary column during merging icd10
#     left_join(., icd9[, c("icd", "icd_category", "field")], by = c("code_dod" = "icd")) %>%
#     left_join(., icd9[, c("icd_category", "phecode", "field")], by = c("code_dod" = "phecode")) %>% 
#     mutate(icd9_category = ifelse(!is.na(icd_category.x), icd_category.x, icd_category.y)) %>% 
#     mutate(icd9_field = ifelse(!is.na(field.x), field.x, field.y)) %>%
#     select(-c(icd_category.x, icd_category.y, field.x, field.y)) %>% # remove temporary column during merging icd9
#     mutate(icd_category = ifelse(!is.na(icd10_category), icd10_category, icd9_category) %>% tolower()) %>%
#     mutate(icd_field = ifelse(!is.na(icd10_category), icd10_field, icd9_field)) %>%
#     select(-c(icd9_category, icd10_category, icd9_field, icd10_field)) %>% 
#     left_join(., phenocode_data_preprocessing, by = c("code" = "phenocode")) %>% 
#     mutate(description = str_trim(description)) %>%
#     mutate(field = ifelse(!is.na(icd_field), 
#                           icd_field, 
#                           ifelse(!is.na(resource_field),
#                                  resource_field, code)))  -> statistics_results_preprocessing
#   
#   
#   statistics_results_preprocessing %>%  
#     filter(field %nin% field_out_recomended_categories) %>% 
#     left_join(., category_data_preprocessing[, c("Description", "Field.ID")], by = c("field" = "Field.ID")) %>% 
#     left_join(., category_data_preprocessing[, c("Description", "category")], by = c("description" = "category")) %>% 
#     mutate(Description = ifelse(!is.na(Description.x), Description.x, Description.y)) %>%
#     select(-c(code, description, code_dod, icd_category, icd_field, trait_type, resource_field, Description.x, Description.y)) %>% 
#     unique() -> statistics_results_category
#   
#   return(statistics_results_category)
# }

df_top_endurance_speed %>% 
  filter(group == "sportsman") %>% 
  {
    ggplot(., aes(x = prs_score)) +
      geom_histogram(aes(y = ..density.., fill = pop),
                     position = "identity",
                     alpha = 0.4) +
      geom_density(aes(y = ..density.., color = pop)) +
      facet_wrap(model ~ .,
                 scales = "free",
                 labeller = labeller(model = tidy_phenotypes(df_top_endurance_speed$model))) +
      theme(
        legend.position = "bottom",
        axis.title = element_text(size = 14),
        legend.text = element_text(size = 14),
        strip.text = element_text(size = 14)
      ) +
      labs(
        x = "prs score",
        y = "density",
        fill = "",
        color = "",
        title = "Test title"
      ) +
      geom_text(
        data = graphLabels,
        aes(label = t_test, x = prs_midle, y = Inf),
        vjust = 2,
        hjust  = "midle"
      )
  }



# 1. code responsible for execute statistic
prs_results_with_sport %>%
  filter(p.value_variants == "1e-08") %>%
  mutate(p.value_variants = as.character(p.value_variants)) %>%
  filter(sport == "swim" | is.na(sport)) %>% 
  select(-c(sport, n, age)) %>%
  # statstics
  group_by(model, p.value_variants) %>%
  nest() %>%
  mutate(
    t.test_control = map(data,
                         ~ ifelse(
                           inherits(try(t.test(.x[.$group == "control",]$prs_score,
                                               .x[.$group == "sportsman", ]$prs_score,
                                               var.equal = TRUE))
                                    , "try-error"),
                           1,
                           t.test(.x[.$group == "control",]$prs_score,
                                  .x[.$group == "sportsman", ]$prs_score,
                                  var.equal = TRUE)[[3]]
                         )),
    t.test_polish = map(data,
                        ~ ifelse(
                          inherits(try(t.test(.x[.$group == "polish_control", ]$prs_score,
                                              .x[.$group == "sportsman", ]$prs_score,
                                              var.equal = TRUE))
                                   , "try-error"),
                          1,
                          t.test(.x[.$group == "polish_control", ]$prs_score,
                                 .x[.$group == "sportsman", ]$prs_score,
                                 var.equal = TRUE)[[3]]
                        )),
    t.test_control_polish = map(data,
                                ~ ifelse(
                                  inherits(try(t.test(.x[.$group == "control",]$prs_score, .x[.$group == "polish_control",]$prs_score, var.equal = T))
                                           , "try-error"),
                                  1,
                                  t.test(.x[.$group == "control",]$prs_score, .x[.$group == "polish_control",]$prs_score, var.equal = T)[[3]]
                                )),
    shapiro.test_sportsman = map(data,  ~ ifelse(
      inherits(try(shapiro.test(.x[.$group == "sportsman", ]$prs_score))
               , "try-error"),
      0,
      shapiro.test(.x[.$group == "sportsman", ]$prs_score)[[2]]
    )),
    shapiro.test_control = map(data,  ~ ifelse(
      inherits(try(shapiro.test(.x[.$group == "control", ]$prs_score))
               , "try-error"),
      0,
      shapiro.test(.x[.$group == "control", ]$prs_score)[[2]]
    )),
    shapiro.test_polish = map(data,  ~ ifelse(
      inherits(try(shapiro.test(.x[.$group == "polish_control", ]$prs_score))
               , "try-error"),
      0,
      shapiro.test(.x[.$group == "polish_control", ]$prs_score)[[2]]
    )),
    prs_midle = map(data, ~mean(range(.x$prs_score)))
    # shapiro.test_sportsman = map(data, ~shapiro.test(.x[.$group == "sportsman",]$prs_score)[[2]])
  ) %>%
  unnest(
    t.test_control,
    t.test_polish,
    t.test_control_polish,
    shapiro.test_sportsman,
    shapiro.test_control,
    shapiro.test_polish,
    prs_midle
  ) -> prs_swim_results

###############################################
# 2. chose models with significance different #
###############################################
prs_statistic_preprocessing(prs_swim_results) %>% 
  # add to result info about field and category
  add_biobank_info() %>% 
  # filter model which variants have 1e-08
  filter(p.value_variants == "1e-08") %>% 
  # filter by type_category
  filter(type_category == "277_Origin_Categories") %>%
  # filter model by n_cases_EUR 
  filter_n_cases(n_cases_EUR = 2000) %>%
  # filter model by shapiro test
  filter(shapiro.test_sportsman > 0.05,
         shapiro.test_control > 0.05, 
         shapiro.test_polish > 0.05) %>%
  filter(t.test_control_polish > 0.05) %>%
  filter(t.test_polish < 0.05) %>%
  # filter(t.test_control < 0.05) %>%
  mutate(FDR_control = p.adjust(t.test_control, method = "fdr"),
         FDR_polish = p.adjust(t.test_polish, method = "fdr")) %>% 
  # filter(t.test_control < 0.05) %>%
  filter(FDR_control< 0.05) %>%
  # select(model) %>% unique()
  filter(category_id %in% c(100091, 100080, 2000, 100071, 100006, 100078, 100013, 100081, 17518, 3000)) %>% #select(model, category_description) %>% unique
  filter(category_id %in% c(100091, 100071, 100006)) %>%
  # add prs results with information for each sample for model
  add_samples_results(., prs_samples_results = prs_results_with_sport) %>%
  filter(sport == "swim" | is.na(sport)) -> df_top_swim_control

df_top_swim_control %>%
  # filter(group == "sportsman") %>%
  group_by(category_description) %>%
  nest() %>% 
  mutate(graph_labels = map(data, ~graph_labels(
    .x,
    columns_name = c("model", "FDR_control", "prs_midle"),
    prefix = "FDR"
  ))) %>% 
  mutate(heights = map(graph_labels, ~ceiling(nrow(.x)/3))) %>%
  mutate(plot = map(
    data,
    ~ plot_prs(
      .x,
      prs_score = prs_score,
      fill = group,
      color = group,
      ncol = 3,
      title = category_description,
      graphLabels = graph_labels[[1]],
      size = 18,
      bins = 20
    )
  )) -> swim_control_to_plot



wrap_plots(swim_control_to_plot$plot) +
  plot_annotation(title = "277 Origin Categories",
                  theme = theme(plot.title = element_text(size = 20))) +
  plot_layout(
    ncol = 1,
    guides = "collect",
    heights =  unlist(swim_control_to_plot$heights)
  ) & theme(legend.position = 'bottom') -> swim_control_plot

df_top_swim_control %>% 
  model_summary_prs() -> df_stat



rmarkdown::render(input = "/home/mateusz/tmp_wgs/results/template-prs-results.Rmd", 
                  output_file = sprintf("swim-control-05.html"),
                  params = list(plot = swim_control_plot, 
                                df_stat = df_stat))

rmarkdown::render(input = "/home/mateusz/tmp_wgs/results/template-prs-results.Rmd", 
                  output_file = sprintf("swim-control-fdr-05.html"),
                  params = list(plot = swim_control_plot, 
                                df_stat = df_stat))


# 
# filter_statistcs_prs <- function(results_biobank_category,
#                                  type_category = "12_Core_Categories",
#                                  t_test_threshold = 0.05,
#                                  shapiro_test_threshold,
#                                  shapiro_columns,
#                                  t_test_columns,
#                                  n_cases_EUR = 2000) {
#   
#   shapiro_filter <- paste(shapiro_columns, shapiro_test_threshold, sep = " > ") %>% 
#     paste(collapse = " & ") %>% 
#     parse(text = .)
#   
#   t_test_filter <- paste(t_test_columns, t_test_threshold, sep = " < ") %>%
#     paste(collapse = " & ") %>%
#     parse(text = .)
#   
#   results_biobank_category %>%
#     filter({{type_category}} == type_category) %>%
#     # prepare model_sign column to merge with phenocode data with number of EUR cases
#     mutate(model_sign = {
#       str_before_nth(as.character(.$model), "-", 4) %>% str_after_first(., "-") %>% tolower() %>% str_replace_all("-", " ") %>% str_squish() %>% str_replace_all(" ", "_")
#     }) %>%
#     # add column with number of EUR cases
#     left_join(., {
#       phenocode_data %>% select(c(model_sign, n_cases_EUR)) %>%
#         mutate(model_sign = {
#           tolower(model_sign) %>% str_replace_all("[[:punct:]]", " ") %>%
#             str_replace_all(., "[[|]]", " ") %>%
#             str_squish() %>%
#             str_trim() %>%
#             str_replace_all(., " ", "_")
#         })
#     }, by = "model_sign") %>%
#     # filter by EUR cases
#     filter({{n_cases_EUR}} > n_cases_EUR |
#              is.na(n_cases_EUR)) %>%
#     # filter(
#     #   shapiro.test_endurance > shapiro_test_threshold,
#     #   shapiro.test_speed > shapiro_test_threshold
#     # ) %>%
#     filter(eval(shapiro_filter)) %>%
#     group_by(category_description) %>%
#     nest() %>%
#     mutate(FDR_category = map(data, ~ p.adjust(.x$t_test, method = "fdr"))) %>%
#     unnest(c(data, FDR_category)) %>%
#     as.data.frame() %>%
#     # filter(t_test < t_test_threshold) %>%
#     filter(eval(t_test_filter)) %>%
#     relocate(category_description, .after = category_id) %>%
#     relocate(
#       c(
#         "t_test",
#         "shapiro.test_endurance",
#         "shapiro.test_speed",
#         "prs_midle"
#       ),
#       .before = FDR_category
#     )  %>% select(-model_sign) -> top_results_statistics
#   
#   return(top_results_statistics)
#   
# }




