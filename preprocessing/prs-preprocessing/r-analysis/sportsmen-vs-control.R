#############################################################
## Stuff I have to do
## mateuszzieba97@gmail.com, 2022 year
#############################################################
# This code is responsible for analysis sportsmen versus control from 1000 Genomes and 
# additionally for polish control

# require packages and function to analysis prs
source("preprocessing/prs-preprocessing/r-analysis/functions-biobank.R")


#######################################
# Analysis prs without alternate loci #
#######################################
# 1. code responsible for execute statistic
prs_results_rm_alternate_loci_pheno %>%
  filter(p.value_variants == "1e-08") %>%
  left_join(sportsmen_pheno, by = c("sample" = "sample_id")) %>%
  mutate(p.value_variants = as.character(p.value_variants)) %>%
  group_by(model, p.value_variants) %>%
  nest() %>%
  mutate(
    t.test_control = map(data, ~ ifelse(
      inherits(try(t.test(.x[.$group == "control", ]$prs_score,
                          .x[.$group == "sportsman", ]$prs_score,
                          var.equal = TRUE))
               ,
               "try-error"),
      1,
      t.test(.x[.$group == "control",]$prs_score,
             .x[.$group == "sportsman",]$prs_score,
             var.equal = TRUE)[[3]]
    )),
    t.test_genotyping = map(data,  ~ ifelse(
      inherits(try(t.test(.x[.$group == "control",]$genotyping_alleles_count,
                          .x[.$group == "sportsman",]$genotyping_alleles_count,
                          var.equal = T))
               , "try-error"),
      1,
      t.test(
        .x[.$group == "control",]$genotyping_alleles_count,
        .x[.$group == "sportsman",]$genotyping_alleles_count,
        var.equal = T
      )[[3]]
    )),
    mean_control_genotyping = map(data, ~ mean(.x[.$group == "control", ]$genotyping_alleles_count)),
    mean_sportsman_genotyping = map(data, ~ mean(.x[.$group == "sportsman",]$genotyping_alleles_count)),
    t.test_polish = map(data, ~ ifelse(
      inherits(try(t.test(.x[.$group == "polish_control", ]$prs_score,
                          .x[.$group == "sportsman", ]$prs_score,
                          var.equal = TRUE))
               ,
               "try-error"),
      1,
      t.test(.x[.$group == "polish_control",]$prs_score,
             .x[.$group == "sportsman",]$prs_score,
             var.equal = TRUE)[[3]]
    )),
    t.test_control_polish = map(data, ~ ifelse(
      inherits(try(t.test(.x[.$group == "control", ]$prs_score,
                          .x[.$group == "polish_control", ]$prs_score,
                          var.equal = TRUE))
               ,
               "try-error"),
      1,
      t.test(.x[.$group == "control",]$prs_score,
             .x[.$group == "polish_control",]$prs_score,
             var.equal = TRUE)[[3]]
    )),
    shapiro.test_sportsman = map(data,  ~ ifelse(
      inherits(try(shapiro.test(.x[.$group == "sportsman",]$prs_score))
               , "try-error"),
      0,
      shapiro.test(.x[.$group == "sportsman",]$prs_score)[[2]]
    )),
    shapiro.test_control = map(data,  ~ ifelse(
      inherits(try(shapiro.test(.x[.$group == "control",]$prs_score))
               , "try-error"),
      0,
      shapiro.test(.x[.$group == "control",]$prs_score)[[2]]
    )),
    shapiro.test_polish = map(data,  ~ ifelse(
      inherits(try(shapiro.test(.x[.$group == "polish_control",]$prs_score))
               , "try-error"),
      0,
      shapiro.test(.x[.$group == "polish_control",]$prs_score)[[2]]
    )),
    prs_midle = map(data, ~ mean(range(.x$prs_score)))
  ) %>%
  unnest(-data) -> prs_sportsmen_control


prs_statistic_preprocessing(prs_sportsmen_control) %>% 
  filter(p.value_variants == "1e-08") %>% 
  filter_n_cases(n_cases_EUR = 2000) %>%
  filter(shapiro.test_sportsman > 0.05,
         shapiro.test_control > 0.05,
         shapiro.test_polish > 0.05
         ) %>% 
  filter(t.test_control_polish > 0.05) %>%
  filter(t.test_polish < 0.1) %>% 
  mutate(FDR = p.adjust(t.test_control, method = "fdr")) %>%
  add_biobank_info() %>%  
  # filter(type_category == "277_Origin_Categories")  %>% 
  filter(FDR < 0.05) %>% 
  filter(category_id %in% c(100091, 100080, 2000, 100071, 100006, 100078, 100013, 100081, 17518, 3000)) %>%
  filter(category_id %in% c(100071, 100006, 100078, 2000)) %>% 
  add_samples_results(., prs_samples_results = prs_results_with_sport) -> df_top_sportsmen_control
 

# prepare palette for group
palette_group <-
  c(
    "sportsman" = "dodgerblue",
    "control" = "firebrick",
    "polish_control" = "green2"
  )


########################
# histplot and boxplot #
########################
df_top_sportsmen_control %>% 
  mutate(model2 = model) %>%
  group_by(model2, category_description) %>%
  nest() %>% 
  mutate(graph_labels = map(data, ~ graph_labels(
    .x,
    columns_name = c("model", "FDR", "prs_midle"),
    prefix = "FDR",
    digits = 7
  ))) %>% 
  mutate(stat_signif_df = map(
    data,
    ~ stat_signif_create(
      y_position = .x$prs_score,
      xmin = 1,
      xmax = 2,
      test_value = .x$FDR,
      prefix = "FDR = ",
      digits = 7
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
      histogram = c("sportsman", "control"),
      size = 30,
      bins = 20
    )
  )) %>% 
  mutate(legend = map(histogram, ~get_legend(.x))) %>% 
  mutate(boxplot = map2(
    .x = data,
    .y = stat_signif_df,
    ~ boxplot_prs(.x, size = 30, stat_signif_df = .y, levels = c("sportsman", "control", "polish_control"))
  )) %>% 
  mutate(hist_box = map2(
    .x = histogram,
    .y = boxplot,
    ~ wrap_elements((.x + .y) + plot_annotation(
      title = tidy_phenotypes(model2),
      theme = theme(
        plot.title = element_text(size = unit(24, "mm")),
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


#########################
# 4. create html report #
#########################
experiment_group <- "sportsman"
control_group <- "control"
stat_threshold <- 0.05

df_top_sportsmen_control %>% 
  filter(group %in% c(experiment_group, control_group)) %>% 
  select(-c(sport, age, n)) %>% unique() %>% 
  model_summary_prs() -> df_stat

number_group(df_top_sportsmen_control) -> df_number_group

cbind( c("comparison", "p.value variants", "n cases EUR", "threshold shapiro.test", "threshold FDR"),
       c(paste(experiment_group, "vs", control_group), "1e-08", "more than 2000", "> 0.05", stat_threshold)) %>% 
  as.data.frame() %>%
  set_colnames(c("description", "value")) -> df_info

output_path <- paste0(getwd(), '/analysis/reports-prs/', experiment_group, "-", control_group, "-hist-box-fdr.", stat_threshold, ".html", sep = "")

rmarkdown::render(input = "preprocessing/prs-preprocessing/r-analysis/report-prs.Rmd", 
                  output_file = output_path,
                  params = list(plot = wrap_plots(hist_box_plot, to_hist_box$data[[1]]$legend[[1]], heights = c(40,1), ncol = 1),
                                df_info = df_info,
                                df_number_group = df_number_group,
                                df_stat = df_stat,
                                height_plot = to_hist_box$heights %>% sum * 5 + 5))

