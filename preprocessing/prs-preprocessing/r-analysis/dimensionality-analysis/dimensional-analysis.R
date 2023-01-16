#############################################################
## Stuff I have to do
## mateuszzieba97@gmail.com - Apr 2022
#############################################################

###############################################################
# require R6 class to dimmenstionality analysis scores of PRS #
###############################################################
source("preprocessing/prs-preprocessing/r-analysis/dimensionality-analysis/dimensional-analysis-class.R")

################
# prepare data #
################
prs_statistic_preprocessing(prs_endurance_speed) %>%
  # add to result info about field and category
  add_biobank_info() %>% head
# filter model which variants have 1e-08
filter(p.value_variants == "1e-08") %>%
  # filter by type_category
  filter(type_category == "277_Origin_Categories" |
           is.na(type_category)) %>% dim
# filter model by n_cases_EUR
filter_n_cases(n_cases_EUR = 2000) %>%
  # filter model by shapiro test
  filter(shapiro.test_endurance > 0.05,
         shapiro.test_speed > 0.05) %>%
  # filter(FDR_category < 0.25) %>%
  filter(
    category_id %in% c(
      100091,
      100080,
      2000,
      100071,
      100006,
      100078,
      100013,
      100081,
      17518,
      3000,
      "pan_biobank_created"
    )
  ) %>%
  filter(category_id %in% c(100091, 100071, 100006, 100078, "pan_biobank_created")) %>%
  select(-contains("shapiro")) %>%
  mutate(comparison = "endurance-speed") -> df_model_1

prs_statistic_preprocessing(prs_swim_sportsmen) %>%
  # add to result info about field and category
  add_biobank_info() %>%
  # filter model which variants have 1e-08
  filter(p.value_variants == "1e-08") %>%
  # filter by type_category
  filter(type_category == "277_Origin_Categories" |
           is.na(type_category)) %>%
  # filter model by n_cases_EUR
  filter_n_cases(n_cases_EUR = 2000) %>%
  # filter model by shapiro test
  filter(shapiro.test_sportsman > 0.05,
         shapiro.test_swim > 0.05) %>%
  # filter(t.test < stat_threshold) %>%
  filter(
    category_id %in% c(
      100091,
      100080,
      2000,
      100071,
      100006,
      100078,
      100013,
      100081,
      17518,
      3000,
      "pan_biobank_created"
    )
  ) %>%
  filter(category_id %in% c(100091, 100071, 100006, 100078, "pan_biobank_created")) %>%
  select(-contains("shapiro")) %>%
  mutate(comparison = "swim-sportsmen") -> df_model_2


prs_statistic_preprocessing(prs_swim_weights) %>%
  # add to result info about field and category
  add_biobank_infolda_results() %>%
  # filter model which variants have 1e-08
  filter(p.value_variants == "1e-08") %>%
  # filter by type_category
  filter(type_category == "277_Origin_Categories" |
           is.na(type_category)) %>%
  # filter model by n_cases_EUR
  filter_n_cases(n_cases_EUR = 2000) %>%
  # filter model by shapiro test
  filter(shapiro.test_swim > 0.05,
         shapiro.test_weights > 0.05) %>%
  filter(
    category_id %in% c(
      100091,
      100080,
      2000,
      100071,
      100006,
      100078,
      100013,
      100081,
      17518,
      3000,
      "pan_biobank_created"
    )
  ) %>%
  filter(category_id %in% c(100091, 100071, 100006, 100078, "pan_biobank_created")) %>%
  select(-contains("shapiro")) %>%
  mutate(comparison = "swim-weights") -> df_model_3


# prepare data to PCA and UMAP analysis
rbind(df_model_1, df_model_2, df_model_3) %>% 
  filter(p.value_variants == "1e-08") %>% 
  filter(t.test < 0.01) %>%
  add_samples_results(., prs_samples_results = prs_results_with_sport) %>%
  filter(super_pop == "sportsmen") %>%
  select(sample, pop, super_pop, gender, group, sport, age, n, model, prs_score) %>% 
  unique() %>%  
  spread(model, prs_score) -> filtered_to_dimensional_analysis


##################################
# dimensionality analysis of PRS #
##################################
dim_prs <- DimensionalityAnalysis$new(filtered_to_dimensional_analysis)

dim_prs$lda_slope_intercept()
dim_prs$lda_classification_plot()
dim_prs$lda_classification_plot_res

#################################################
# dimensionality analysis of PRS on random data # 
#################################################
# permutate random data 100 times
start <- Sys.time()
plan(multisession, workers = 12)
future_map(c(1:100), function(x){prepare_ranodom_data(prs_results_with_sport)}) -> permutate_dimensionality_list_100
end <- Sys.time()
end-start


# permutate random data 1000 times
start <- Sys.time()
plan(multisession, workers = 12)
future_map(c(1:1000), function(x){prepare_ranodom_data(prs_results_with_sport)}) -> permutate_dimensionality_list_1000
end <- Sys.time()
end-start

# preprocessing statistics
permutate_dimensionality_list_1000 %>% 
  tibble(number = c(1:1000), rand_data = .) %>%
  mutate(dimensional_analysis = map(rand_data,  ~ {
    DimensionalityAnalysis$new(.x)
  })) %>% 
  mutate(p.value = map(dimensional_analysis, ~ {
    .x$p.value_analysis
  })) %>%
  mutate(p.value_type = map(dimensional_analysis, ~ {
    .$type_statistics
  }))  %>%
  unnest(c(p.value, p.value_type)) %>%
  mutate(p.value_pop = map2(.x = rand_data, .y = p.value, ~ ifelse(
    is.na(.y), t.test(.x[.$pop == "speed", 9],
                      .x[.$pop == "endurance", 9],
                      var.equal = TRUE)[[3]],
    NA
  ))) %>%
  mutate(p.value_swim_weights = map2(.x = rand_data, .y = p.value, ~ ifelse(
    is.na(.y), t.test(.x[.$sport == "swim", 9],
                      .x[.$sport == "weights", 9],
                      var.equal = TRUE)[[3]],
    NA
  ))) %>%
  mutate(p.value_swim_sportsman = map2(.x = rand_data, .y = p.value, ~ ifelse(
    is.na(.y), t.test(.x[.$sport == "swim", 9],
                      .x[.$sport != "swim", 9],
                      var.equal = TRUE)[[3]],
    NA
  ))) %>% 
  unnest(c(p.value_pop, p.value_swim_weights, p.value_swim_sportsman)) %>%
  mutate(min_value = apply(.[,c(6:8)], 1, min)) %>%
  mutate(p.value = ifelse(is.na(p.value), min_value, p.value)) %>%
  select(-c(p.value_pop, p.value_swim_sportsman, p.value_swim_weights, min_value)) -> dimensionality_stat_preprocessing

# check from which stage is p.value
dimensionality_stat_preprocessing %>% 
  select(-c(rand_data, dimensional_analysis)) %>% 
  as.data.frame() %>%
  select(p.value_type) %>% 
  table

# random data with the better p.value from origin data
dimensionality_stat_preprocessing %>% 
  select(-c(rand_data, dimensional_analysis)) %>% 
  as.data.frame() %>%
  filter(p.value < dim_prs$lda_statistics_res[3]) %>%
  nrow -> better_permutate

