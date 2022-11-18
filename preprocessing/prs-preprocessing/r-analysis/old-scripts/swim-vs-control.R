#####################
# swim vs sportsmen #
#####################
prs_results_with_sport %>%
  filter(p.value_variants == "1e-08") %>%
  mutate(p.value_variants = as.character(p.value_variants)) %>% 
  # filter(group == "sportsman") %>% 
  mutate(group = ifelse(sport == "swim", "swim", "sportsman")) %>%
  select(-c(sport, n, age)) %>% 
  statistics_sportsmen_prs(column_group = "group", group1 = "swim", group2 = "sportsman") -> prs_swim_sportsmen


###############################################
# 2. chose models with significance different #
###############################################
prs_statistic_preprocessing(prs_swim_sportsmen) %>% 
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
         shapiro.test_swim > 0.05) %>%
  mutate(FDR_category = p.adjust(t.test, method = "fdr")) %>%
  filter(t.test< 0.05) %>%
  filter(category_id %in% c(100091, 100080, 2000, 100071, 100006, 100078, 100013, 100081, 17518, 3000)) %>% 
  filter(category_id %in% c(100091, 100071, 100006, 100078)) %>%
  # add prs results with information for each sample for model
  add_samples_results(., prs_samples_results = prs_results_with_sport) %>% 
  mutate(sport = ifelse(is.na(sport), group, sport)) %>% 
  # filter(group == "sportsman") %>%
  mutate(group = ifelse(sport == "swim", "swim", group)) -> df_top_swim_sportsmen


palette_group <-
  c(
    "swim" = "dodgerblue",
    "sportsman" = "firebrick",
    "control" = "green2",
    "polish_control" = "orange"
  )

df_top_swim_sportsmen %>% 
  # filter(group == "sportsman") %>%
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
      histogram = c("swim", "sportsman"),
      size = 18,
      bins = 20
    )
  )) -> swim_sportsmen_to_plot

wrap_plots(swim_sportsmen_to_plot$plot) +
  plot_annotation(title = "277 Origin Categories",
                  theme = theme(plot.title = element_text(size = 20))) +
  plot_layout(
    ncol = 1,
    guides = "collect",
    heights =  unlist(swim_sportsmen_to_plot$heights)
  ) & theme(legend.position = 'bottom') -> swim_sportsmen_plot

df_top_swim_sportsmen %>% 
  filter(group %in% c("swim", "sportsman")) %>%
  select(-c(sport, age, n)) %>% unique() %>%
  model_summary_prs() -> df_stat


number_group(df_top_swim_sportsmen) -> df_number_group

cbind( c("comparison", "p.value variants", "n cases EUR", "threshold shapiro.test", "threshold t.test"),
       c("swim vs sportsmen", "1e-08", "more than 2000", "> 0.05", "< 0.05")) %>% 
  as.data.frame() %>%
  set_colnames(c("description", "value"))-> df_info

rmarkdown::render(input = "preprocessing/prs-preprocessing/r-analysis/report-prs.Rmd", 
                  output_file = sprintf("swim-sportsmen-05.html"),
                  params = list(plot = swim_sportsmen_plot,
                                df_info = df_info,
                                df_number_group = df_number_group,
                                df_stat = df_stat))


#





































prs_swim_results

# 2. filtering significat features
prs_swim_results %>%
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
  mutate(FDR_polish = p.adjust(t.test_polish, method = "fdr")) %>% filter(t.test_control < 0.05)
  filter(FDR_control < 0.05) -> df_top_swim


png(
  "/home/mateusz/projects/plots/swim-vs-controls-phenotypes.png",
  width = 7016,
  height = 4960,
  res = 600
)

graphLabels <- df_top_swim %>% 
    .[, c("model", "FDR_control", "FDR_polish", "prs_midle")] %>%
    mutate(t_test = paste("FDR(con) =", round(FDR_control, 5), "\nFDR(pol) =", round(FDR_polish, 5)))


prs_results_rm_alternate_loci_pheno %>%
  filter(model %in% df_top_swim$model) %>%
  left_join(sportsmen_pheno, by = c("sample" = "sample_id")) %>%
  {
    ggplot(., aes(x = prs_score)) +
      geom_histogram(aes(y = ..density.., fill = group),
                     position = "identity",
                     alpha = 0.4) +
      geom_density(aes(y = ..density.., color = group)) +
      facet_wrap(model ~ .,
                 scales = "free",
                 labeller = labeller(model = tidy_phenotypes(df_top_swim$model))) +
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
      scale_fill_discrete(labels = c("1000 Genomes control", "polish control", "swimmers")) +
      scale_color_discrete(labels = c("1000 Genomes control", "polish control", "swimmers")) +
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
  filter(sport == "swim" | is.na(sport)) %>%
  .[,5] %>% table
  