#############################################################
## Stuff I have to do
## mateuszzieba97@gmail.com, 2022 year
#############################################################
# This code is responsible for analysis endurance versus speed sportsmen

# require packages and function to analysis prs
source("preprocessing/prs-preprocessing/r-analysis/functions-biobank.R")


###################################
# 1. swim vs sportsmen statistics #
###################################
experiment_group <- "endurance"
control_group <- "speed"
stat_threshold <- 0.01

prs_results_with_sport %>%
  filter(p.value_variants == "1e-08") %>%
  mutate(p.value_variants = as.character(p.value_variants)) %>% 
  # create column with group
  mutate(group = ifelse(group == "sportsman", pop, group)) %>% 
  select(-c(sport, n, age)) %>% 
  statistics_sportsmen_prs(column_group = "group", group1 = experiment_group, group2 = control_group) -> prs_endurance_speed

###############################################
# 2. chose models with significance different #
###############################################
prs_statistic_preprocessing(prs_endurance_speed) %>% 
  # add to result info about field and category
  add_biobank_info() %>% 
  # filter model which variants have 1e-08
  filter(p.value_variants == "1e-08") %>% 
  # filter by type_category
  filter(type_category == "277_Origin_Categories") %>%
  # filter model by n_cases_EUR 
  filter_n_cases(n_cases_EUR = 2000) %>% 
  # filter model by shapiro test
  filter(shapiro.test_endurance > 0.05,
         shapiro.test_speed > 0.05) %>%
  group_by(category_description) %>%
  nest() %>%
  mutate(FDR_category = map(data, ~ p.adjust(.x$t.test, method = "fdr"))) %>%
  unnest(c(data, FDR_category)) %>%
  as.data.frame() %>% 
  filter(t.test < stat_threshold) %>% 
  # filter(FDR_category < 0.25) %>%
  filter(category_id %in% c(100091, 100080, 2000, 100071, 100006, 100078, 100013, 100081, 17518, 3000)) %>% 
  filter(category_id %in% c(100091, 100071, 100006, 100078)) %>% 
  # add prs results with information for each sample for model
  add_samples_results(., prs_samples_results = prs_results_with_sport) %>% 
  mutate(sport = ifelse(is.na(sport), group, sport)) %>% 
  # filter(group == "sportsman") %>%
  mutate(group = ifelse(group == "sportsman", pop, group)) -> df_top_endurance_speed


# prepare palette for group
palette_group <-
  c(
    "endurance" = "dodgerblue",
    "speed" = "firebrick",
    "control" = "green3",
    "polish_control" = "orange"
  )

##################
# 3. create plot #
##################
df_top_endurance_speed %>% 
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
      ncol = 2,
      title = category_description,
      graphLabels = graph_labels[[1]],
      palette = palette_group,
      histogram = c(experiment_group, control_group),
      size = 18,
      bins = 20
    )
  )) -> endurance_speed_to_plot

wrap_plots(endurance_speed_to_plot$plot) +
  plot_annotation(title = "277 Origin Categories",
                  theme = theme(plot.title = element_text(size = 20))) +
  plot_layout(
    ncol = 1,
    guides = "collect",
    heights =  unlist(endurance_speed_to_plot$heights)
  ) & theme(legend.position = 'bottom') -> endurance_speed_plot


#########################
# 4. create html report #
#########################
 df_top_endurance_speed %>% 
  filter(group %in% c(experiment_group, control_group)) %>%
  select(-c(sport, age, n)) %>% unique() %>%
  model_summary_prs() -> df_stat

number_group(df_top_endurance_speed) -> df_number_group

cbind( c("comparison", "p.value variants", "n cases EUR", "threshold shapiro.test", "threshold t.test"),
       c(paste(experiment_group, "vs", control_group), "1e-08", "more than 2000", "> 0.05", stat_threshold)) %>% 
  as.data.frame() %>%
  set_colnames(c("description", "value"))-> df_info

output_path <- paste0(getwd(), '/results/reports-prs/', experiment_group, "-", control_group, "-fdr-0.25.html", sep = "")

# rmarkdown::render(input = "preprocessing/prs-preprocessing/r-analysis/report-prs.Rmd", 
#                   output_file = output_path,
#                   params = list(plot = endurance_speed_plot,
#                                 df_info = df_info,
#                                 df_number_group = df_number_group,
#                                 df_stat = df_stat))

########################
# histplot and boxplot #
########################
df_top_endurance_speed %>% 
  mutate(model2 = model) %>%
  group_by(model2, category_description) %>%
  nest() %>% 
  mutate(graph_labels = map(data, ~ graph_labels(
    .x,
    columns_name = c("model", "t.test", "prs_midle"),
    prefix = "p"
  ))) %>% 
  mutate(stat_signif_df = map(
    data,
    ~ stat_signif_create(
      y_position = .x$prs_score,
      xmin = 1,
      xmax = 2,
      test_value = .x$t.test,
      prefix = "p = "
    )
  )) %>% 
  mutate(histogram = map(
    data,
    ~ histogram_prs(
      .x,
      prs_score = prs_score,
      fill = group,
      color = group,
      graphLabels = graph_labels[[1]],
      palette = palette_group,
      histogram = c("endurance", "speed"),
      size = 30,
      bins = 20
    )
  )) %>% 
  mutate(legend = map(histogram, ~get_legend(.x))) %>%
  mutate(boxplot = map2(
    .x = data,
    .y = stat_signif_df,
    ~ boxplot_prs(.x, size = 30, stat_signif_df = .y, levels = c("endurance", "speed", "control", "polish_control"))
  )) %>%
  mutate(hist_box = map2(
    .x = histogram,
    .y = boxplot,
    ~ wrap_elements((.x + .y) + plot_annotation(
      title = tidy_phenotypes(model2),
      theme = theme(
        plot.title = element_text(size = unit(26, "mm")),
        aspect.ratio =
          9 / 16
      )
    ) &
      theme(
        legend.position = 'none',
        plot.margin = unit(c(0, 0, 0, 0), "points")
      )
    )
  ))  %>%
  group_by(category_description) %>%
  nest() %>%
  mutate(category_wrap = map(data, ~ (wrap_plots(.x$hist_box, ncol = 1)))) %>%
  mutate(category_wrap_title = map(category_wrap,
                                   ~ wrap_elements(
                                     .x + plot_annotation(
                                       title = category_description,
                                       theme = theme(
                                         plot.background = element_rect(fill = "gray90"),
                                         plot.margin =
                                           unit(c(0, 0, 0, 0), "cm"),
                                         plot.title = element_text(
                                           size = unit(30, "mm"),
                                           face = "bold",
                                           hjust = 0.5,
                                           margin = margin(t = 1, b = 1, unit = "pt")
                                         )
                                       )
                                     )
                                   ))) %>%
  mutate(heights = map(data, ~nrow(.x))) %>% 
  unnest(heights) -> to_hist_box 

wrap_plots(to_hist_box$category_wrap_title, ncol = 1) + coord_fixed() +
  plot_layout(heights =to_hist_box$heights) & theme(plot.margin=unit(c(0,0,0,0), "points")) -> hist_box_plot

output_path <- paste0(getwd(), '/analysis/reports-prs/', experiment_group, "-", control_group, "-hist-box-p.", stat_threshold, ".html", sep = "")


rmarkdown::render(input = "preprocessing/prs-preprocessing/r-analysis/report-prs.Rmd", 
                  output_file = output_path,
                  params = list(plot = wrap_plots(hist_box_plot, to_hist_box$data[[1]]$legend[[1]], heights = c(40,1), ncol = 1),
                                df_info = df_info,
                                df_number_group = df_number_group,
                                df_stat = df_stat,
                                height_plot = to_hist_box$heights %>% sum * 5 + 5))


# save plot to png, earlier size text = 30 or 24 for title 
dev.off()
png("analysis/reports-prs/endurance-speed-health.png", width = 1920, height = 2160)
wrap_plots(hist_box_plot[[1]], to_hist_box$data[[1]]$legend[[1]], heights = c(40,1), ncol = 1)
dev.off()

png("analysis/reports-prs/endurance-speed-biological-samples.png", width = 1920, height = 1080)
# wrap_plots(hist_box_plot[[2]], to_hist_box$data[[1]]$legend[[1]], heights = c(40,1), ncol = 1)
hist_box_plot[[2]]
dev.off()

