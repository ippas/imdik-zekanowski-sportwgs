###################################
# 1. swim vs sportsmen statistics #
###################################
experiment_group <- "weights"
control_group <- "sportsman"

prs_results_with_sport %>%
  filter(p.value_variants == "1e-08") %>%
  mutate(p.value_variants = as.character(p.value_variants)) %>%
  # create column with group
  mutate(group = ifelse(sport == experiment_group, experiment_group, control_group)) %>%
  select(-c(sport, n, age)) %>% 
  statistics_sportsmen_prs(column_group = "group", group1 = experiment_group, group2 = control_group) -> prs_weights_sportsmen

###############################################
# 2. chose models with significance different #
###############################################
prs_statistic_preprocessing(prs_weights_sportsmen) %>% 
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
         shapiro.test_weights > 0.05) %>%
  mutate(FDR_category = p.adjust(t.test, method = "fdr")) %>%
  filter(t.test< 0.05) %>%
  filter(category_id %in% c(100091, 100080, 2000, 100071, 100006, 100078, 100013, 100081, 17518, 3000)) %>% 
  filter(category_id %in% c(100091, 100071, 100006, 100078)) %>%
  # add prs results with information for each sample for model
  add_samples_results(., prs_samples_results = prs_results_with_sport) %>% 
  mutate(sport = ifelse(is.na(sport), group, sport)) %>% 
  # filter(group == "sportsman") %>%
  mutate(group = ifelse(sport == experiment_group, experiment_group, group)) -> df_top_weights_sportsmen


# prepare palette for group
palette_group <-
  c(
    experiment_group = "dodgerblue",
    control_group = "firebrick",
    "control" = "green2",
    "polish_control" = "orange"
  )

##################
# 3. create plot #
##################
df_top_weights_sportsmen %>% 
  group_by(category_description) %>%
  nest() %>% 
  mutate(graph_labels = map(data, ~graph_labels(
    .x,
    columns_name = c("model", "t.test", "prs_midle"),
    prefix = "p"
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
      palette = palette_group,
      histogram = c(experiment_group, control_group),
      size = 18,
      bins = 20
    )
  )) -> weights_sportsmen_to_plot

wrap_plots(weights_sportsmen_to_plot$plot) +
  plot_annotation(title = "277 Origin Categories",
                  theme = theme(plot.title = element_text(size = 20))) +
  plot_layout(
    ncol = 1,
    guides = "collect",
    heights =  unlist(weights_sportsmen_to_plot$heights)
  ) & theme(legend.position = 'bottom') -> weights_sportsmen_plot


#########################
# 4. create html report #
#########################
df_top_weights_sportsmen %>% 
  filter(group %in% c(experiment_group, control_group)) %>%
  select(-c(sport, age, n)) %>% unique() %>%
  model_summary_prs() -> df_stat

number_group(df_top_weights_sportsmen) -> df_number_group

cbind( c("comparison", "p.value variants", "n cases EUR", "threshold shapiro.test", "threshold t.test"),
       c(paste(experiment_group, "vs", control_group), "1e-08", "more than 2000", "> 0.05", "< 0.05")) %>% 
  as.data.frame() %>%
  set_colnames(c("description", "value"))-> df_info

rmarkdown::render(input = "preprocessing/prs-preprocessing/r-analysis/report-prs.Rmd", 
                  output_file = sprintf(paste(experiment_group, control_group, "05.html", sep = "-")),
                  params = list(plot = weights_sportsmen_plot,
                                df_info = df_info,
                                df_number_group = df_number_group,
                                df_stat = df_stat))








# 1. code responsible for execute statistic
prs_results_rm_alternate_loci_pheno %>%
  filter(p.value_variants == "1e-08") %>%
  mutate(p.value_variants = as.character(p.value_variants)) %>%
  left_join(sportsmen_pheno, by = c("sample" = "sample_id")) %>%
  filter(sport == "weights" | is.na(sport)) %>%
  select(-c(sport, n, age, category_size)) %>%
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
  ) -> prs_weights_results

prs_weights_results %>% 
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
  )) %>% head%>% .[, c(1:6, 8, 15)] %>%
  unique() 



###############################
# endurance vs speed analysis #
###############################
# 1. code responsible for execute statistic between speed and endurance
# prs_results_rm_alternate_loci_pheno %>% 
#   mutate(p.value_variants = as.character(p.value_variants)) %>%
#   # filter(p.value_variants == "1e-08") %>%
#   left_join(sportsmen_pheno, by = c("sample" = "sample_id")) %>% 
#   statistics_prs(., group1 = "endurance", group2 = "speed") -> endurance_speed_results
columns_shapiro <- c("shapiro.test_sporsman", "shapiro.test_control", "shapiro.test_polish")

paste(columns_shapiro, 0.05, sep = " > ") %>% paste(collapse = " & ") %>% parse(text = .)
sapply(columns_shapiro, paste0, paste(" > ", c(0.05, 0.05, 0.01)))  %>% paste(., collapse = " & ")

# 2. chose models with significance different
prs_statistic_preprocessing(prs_weights_results) %>% 
  # add to result info about field and category
  add_biobank_info() %>%
  # filter model which variants have 1e-08
  filter(p.value_variants == "1e-08") %>% head %>% filter(eval(parse(text = "shapiro.test_polish > 0.05 & shapiro.test_control > 0.05 & shapiro.test_sportsman > 0.05")))

# 2. chose models with significance different
prs_statistic_preprocessing(prs_weights_results) %>% 
  # add to result info about field and category
  add_biobank_info() %>%
  # filter model which variants have 1e-08
  filter(p.value_variants == "1e-08") %>% 
  # filter results
  filter_cases(., 
               type_category = "277_Origin_Categories", 
               n_cases_EUR = 2000) %>%
  filter(shapiro.test_sportsman > 0.0,
         shapiro.test_control > 0.05, 
         shapiro.test_polish > 0)

    # chose category which are main category in 277 Origin Categories
  filter(category_id %in% origin_categories_main_vector) %>%
  # filter interest category
  filter(category_id %in% c(100091, 100080, 2000, 100071, 100006, 100078, 100013, 100081, 17518, 3000)) %>%
  # filter by calculated FDR inner for each category_id
  filter(FDR_category < 0.25) %>% 
  # 
  filter(category_id %in% c(100091, 100071, 100078)) %>%
  # add prs results with information for each sample for model
  add_samples_results(., prs_samples_results = prs_results_rm_alternate_loci_pheno) -> df_top_endurance_speed
  
  type_categories_biobank <- read_html("https://biobank.ndph.ox.ac.uk/showcase/cats.cgi") %>%
    html_elements(xpath = paste0('.//div[@class = "tabbertab"]')) %>% 
    html_elements(xpath = ".//h2") %>% 
    html_text() %>%
    str_replace_all(' ', '_')
  
  
  # prepare data frame with type categories
  read_html("https://biobank.ndph.ox.ac.uk/showcase/cats.cgi") %>%
    html_elements(xpath = paste0('.//div[@class = "tabbertab"]')) %>%
    # html_elements(xpath = ".//table") %>% html_table() 
    lapply(., function(x) {
      x %>%
        html_elements(xpath = ".//table") %>%
        html_table() %>% 
        as.data.frame()
    }) %>% 
    set_names(type_categories_biobank) %>%
    plyr::ldply(.id = "type_category") %>% 
    select(-Items) %>%
    set_colnames(c("type_category", "category_id", "category_description")) -> type_categories_df_biobank




prs_weights_results

# 2. filtering significat features
prs_weights_results %>%
  .[order(.$t.test_control), ] %>% 
  select(-c(data)) %>% 
  as.data.frame() %>%
  filter(shapiro.test_sportsman > 0.05) %>% 
  filter(shapiro.test_control > 0.05) %>%  
  filter(shapiro.test_polish > 0.05) %>%
  mutate(model_sign = {str_before_nth(as.character(.$model), "-", 4) %>% str_after_first(., "-")}) %>% 
  left_join(., {phenocode_data %>% select(c(model_sign, n_cases_EUR))}, by = "model_sign") %>%
  filter(n_cases_EUR > 2000 | is.na(n_cases_EUR)) %>%
  filter(t.test_polish < 0.05) %>% 
  filter(t.test_control_polish > 0.05) %>% 
  mutate(FDR_control = p.adjust(t.test_control, method = "fdr")) %>% 
  mutate(FDR_polish = p.adjust(t.test_polish, method = "fdr")) %>% 
  filter(FDR_control < 0.05) -> df_top_weights


png(
  "/home/mateusz/projects/plots/weights-vs-controls-phenotypes.png",
  width = 7016,
  height = 4960,
  res = 600
)

graphLabels <- df_top_weights %>% 
  .[, c("model", "FDR_control", "FDR_polish", "prs_midle")] %>%
  mutate(t_test = paste("FDR(con) =", round(FDR_control, 5), "\nFDR(pol) =", round(FDR_polish, 5)))


prs_results_rm_alternate_loci_pheno %>%
  filter(model %in% df_top_weights$model) %>%
  left_join(sportsmen_pheno, by = c("sample" = "sample_id")) %>%
  {
    ggplot(., aes(x = prs_score)) +
      geom_histogram(aes(y = ..density.., fill = group),
                     position = "identity",
                     alpha = 0.4) +
      geom_density(aes(y = ..density.., color = group)) +
      facet_wrap(model ~ .,
                 scales = "free",
                 labeller = labeller(model = tidy_phenotypes(df_top_weights$model))) +
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
        color = ""
      ) +
      scale_fill_discrete(labels = c("1000 Genomes control", "polish control", "weightlifter")) +
      scale_color_discrete(labels = c("1000 Genomes control", "polish control", "weightlifter")) +
      geom_text(
        data = graphLabels,
        aes(label = t_test, x = prs_midle, y = Inf),
        vjust = 1.5,
        hjust  = "midle"
      )
  }

dev.off()


sportsmen_control_polish %>% 
  left_join(sportsmen_pheno, by = c("sample" = "sample_id")) %>%
  filter(sport == "weights" | is.na(sport)) %>%
  .[,5] %>% table
