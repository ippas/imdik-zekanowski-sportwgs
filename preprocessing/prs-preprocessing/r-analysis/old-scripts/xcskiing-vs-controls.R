# 1. code responsible for execute statistic
prs_results_rm_alternate_loci_pheno %>%
  # filter(p.value_variants == "1e-08") %>%
  mutate(p.value_variants = as.character(p.value_variants)) %>%
  left_join(sportsmen_pheno, by = c("sample" = "sample_id")) %>%
  # filter(group != "speed") %>%
  # filter(n > 1 | is.na(n)) %>%
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
  ) -> sportsman_results


sportsman_results

# 2. filtering significat features
sportsman_results %>%
  .[order(.$t.test_control), ] %>% 
  select(-c(data)) %>% 
  as.data.frame() %>%
  filter(shapiro.test_sportsman > 0.0001) %>%
  filter(shapiro.test_control > 0.0001) %>%
  # filter(shapiro.test_polish > 0.05) %>%
  mutate(model_sign = {str_before_nth(as.character(.$model), "-", 4) %>% str_after_first(., "-")}) %>% 
  left_join(., {phenocode_data %>% select(c(model_sign, n_cases_EUR))}, by = "model_sign") %>%
  filter(n_cases_EUR > 2000 | is.na(n_cases_EUR)) %>%
  filter(t.test_polish < 0.1) %>% 
  filter(t.test_control_polish > 0.05) %>% 
  mutate(FDR_control = p.adjust(t.test_control, method = "fdr")) %>% 
  mutate(FDR_polish = p.adjust(t.test_polish, method = "fdr")) %>% 
  filter(FDR_control < 0.05) -> df_top_sportsman


png(
  "/home/mateusz/projects/plots/xcskiing-vs-controls-phenotypes.png",
  width = 7016,
  height = 4960,
  res = 600
)

graphLabels <- df_top_sportsman %>% 
  .[, c("model", "FDR_control", "FDR_polish", "prs_midle")] %>%
  mutate(t_test = paste("FDR(con) =", round(FDR_control, 6)))


prs_results_rm_alternate_loci_pheno %>%
  filter(model %in% df_top_sportsman$model) %>%
  left_join(sportsmen_pheno, by = c("sample" = "sample_id")) %>%
  {
    ggplot(., aes(x = prs_score)) +
      geom_histogram(aes(y = ..density.., fill = group),
                     position = "identity",
                     alpha = 0.4) +
      geom_density(aes(y = ..density.., color = group)) +
      facet_wrap(model ~ .,
                 scales = "free",
                 labeller = labeller(model = tidy_phenotypes(df_top_sportsman$model))) +
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
      scale_fill_discrete(labels = c("1000 Genomes control", "polish control", "sportsman")) +
      scale_color_discrete(labels = c("1000 Genomes control", "polish control", "sportsman")) +
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
  # filter(sport == "xcskiing" | is.na(sport)) %>%
  .[,6] %>% table
