###### ANOVA
# 1. code responsible for execute statistic between speed and endurance
prs_results_rm_alternate_loci_pheno %>% 
  mutate(p.value_variants = as.character(p.value_variants)) %>% 
  left_join(sportsmen_pheno, by = c("sample" = "sample_id")) %>% 
  filter(sport == "weights" | sport == "swim") %>% 
  group_by(model, p.value_variants) %>% 
  nest() %>% 
  mutate(t_test = map(data, ~ifelse(inherits(try(t.test(.x[.$sport == "swim",]$prs_score, .x[.$sport == "weights",]$prs_score, var.equal = TRUE)), "try-error"),
                                    1,
                                    t.test(.x[.$sport == "swim",]$prs_score, .x[.$sport == "weights",]$prs_score, var.equal = TRUE)[[3]])),
         shapiro_swim = map(data, ~ifelse(inherits(try(shapiro.test(.x[.$sport == "swim",]$prs_score)), "try-error"),
                                0,
                                shapiro.test(.x[.$sport == "swim",]$prs_score)[[2]])),
         shapiro_weights = map(data, ~ifelse(inherits(try(shapiro.test(.x[.$sport == "weights",]$prs_score)), "try-error"),
                                          0,
                                          shapiro.test(.x[.$sport == "weights",]$prs_score)[[2]])),
         prs_midle = map(data, ~mean(range(.x$prs_score)))
         ) %>% unnest(t_test, shapiro_swim, shapiro_weights, prs_midle) -> anova_resutlts
  

z

anova_resutlts %>%
  select(-c(data)) %>%
  as.data.frame() %>%
  # mutate(model_sign = {str_before_nth(as.character(.$model), "-", 4) %>% str_after_first(., "-")}) %>%
  # left_join(., {phenocode_data %>% select(c(model_sign, n_cases_EUR))}, by = "model_sign") %>%
  # filter(n_cases_EUR > 2000 | is.na(n_cases_EUR)) %>%
  # filter(p.value_shapiro > 0.05) %>%
  filter(p.value_variants == "1e-08") %>%
  filter(shapiro_swim > 0.05,
         shapiro_weights > 0.05) %>%
  .[order(.$t_test),]  %>% 
  filter(t_test < 0.05)  %>% .[,1] -> top_anova_results

# # 2. filtering significat features
# prs_result_stat_sportsman %>%
#   .[order(.$t.test_sportsman),] %>% 
#   select(-c(data)) %>% 
#   as.data.frame() %>% 
#   mutate(model_sign = {str_before_nth(as.character(.$model), "-", 4) %>% str_after_first(., "-")}) %>% 
#   left_join(., {phenocode_data %>% select(c(model_sign, n_cases_EUR))}, by = "model_sign") %>%
#   filter(n_cases_EUR > 2000) %>%
#   filter(shapiro.test_endurance > 0.05, shapiro.test_speed > 0.05) %>%
#   mutate(FDR = p.adjust(t.test_sportsman, method = "fdr")) %>%
#   filter(t.test_sportsman < 0.05)

# 3. filter top model
prs_result_stat_sportsman %>%
  .[order(.$t.test_sportsman),] %>% 
  select(-c(data)) %>% 
  as.data.frame() %>% 
  mutate(model_sign = {str_before_nth(as.character(.$model), "-", 4) %>% str_after_first(., "-")}) %>% 
  left_join(., {phenocode_data %>% select(c(model_sign, n_cases_EUR))}, by = "model_sign") %>%
  filter(n_cases_EUR > 2000) %>%
  filter(shapiro.test_endurance > 0.05, shapiro.test_speed > 0.05) %>%
  mutate(FDR = p.adjust(t.test_sportsman, method = "fdr")) %>%
  filter(t.test_sportsman < 0.05) %>% 
  head(20)  %>% .[,1] -> top_model_sportsman


# 3. filter top model
prs_results_rm_alternate_loci_pheno %>% 
  filter(model %in% top_anova_results) %>%
  filter(group == "sportsman") %>%
  left_join(sportsmen_pheno, by = c("sample" = "sample_id")) %>% 
  filter(sport == "weights" | sport == "swim") %>%
  mutate(model = str_replace_all(model, "biobankuk-", "")) %>%
  mutate(model = str_replace_all(model, "-EUR", "")) %>%
  mutate(model = str_replace_all(model, "-both_sexes", "")) %>%
  ggplot(aes(x = prs_score)) +
  geom_histogram(aes(y=..density.., fill = sport), position = "identity", alpha=0.4) +
  geom_density(aes(y=..density.., color = sport)) +
  facet_wrap(model ~ ., scales = "free") +
  theme(legend.position="bottom") +
  

