
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

start <- Sys.time()
plan(multisession, workers = 12)
future_map(c(1:100), function(x){prepare_ranodom_data(prs_results_with_sport)}) -> tmp_permutate_dimensionality_list_100
end <- Sys.time()
end-start



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
  select(-c(p.value_pop, p.value_swim_sportsman, p.value_swim_weights, min_value)) -> tmp_statistics



tmp_statistics %>% 
  select(-c(rand_data, dimensional_analysis)) %>% 
  as.data.frame() %>%
  select(p.value_type) %>% table


tmp_statistics %>% 
  select(-c(rand_data, dimensional_analysis)) %>% 
  as.data.frame() %>%
  filter(p.value < 0.00000001)




tmp_permutate_dimensionality_list_100 %>%
  tibble(number = c(1:100), rand_data = .) %>%
  head(100) %>% 
  mutate(dimensional_analysis = map(rand_data,  ~ {
    DimensionalityAnalysis$new(.x)
  })) %>%
  mutate(p.value = map(dimensional_analysis, ~ {
    .x$p.value_analysis
  })) %>%
  mutate(p.value_type = map(dimensional_analysis, ~ {
    .$type_statistics
  })) %>%
  unnest(c(p.value, p.value_type)) %>% tail
  

  
  
  
  
  
