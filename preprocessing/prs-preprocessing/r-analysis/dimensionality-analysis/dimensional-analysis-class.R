install.packages("furrr")

require(R6)
require(furrr)
require(yardstick)

# prepare data to PCA and UMAP analysis
rbind(df_model_1, df_model_2, df_model_3) %>% 
  filter(p.value_variants == "1e-08") %>% 
  filter(t.test < 0.01) %>%
  add_samples_results(., prs_samples_results = prs_results_with_sport) %>%
  filter(super_pop == "sportsmen") %>%
  select(sample, pop, super_pop, gender, group, sport, age, n, model, prs_score) %>% 
  unique() %>%  
  spread(model, prs_score) -> filtered_to_dimensional_analysis
  
# create class to dimensionality analysis
DimensionalityAnalysis <- R6Class(
  "DimensionalityAnalysisPRS",
  
  public = list(
    df_models = NULL,
    df_metadata_sportsmen = NULL,
    pca_results = NULL,
    pc_statistics_res = NULL,
    df_prepare_to_lda = NULL,
    lda_predict = NULL,
    lda_summary_res = NULL,
    lda_statistics_res = NULL,
    
    skew_biplot_res = NULL,
    pca_plot_res = NULL,
    lda_plots_res = NULL,
    type_statistics = NULL,
    p.value_analysis = NULL,
    
    
    initialize = function(data) {
      if(nrow(data) == 0){
        self$type_statistics <- "model"
        self$p.value_analysis <- 1
        return(cat("Analysis is not significant"))
      } else if(ncol(data) == (1 + 8)) {
        self$type_statistics <- "model"
        self$p.value_analysis <- NA
        return(cat("P.value from t.test execute on phenotype"))
      } else if(ncol(data) == (2 + 8)) {
        self$type_statistics <- "model_lda"

        self$df_models <- data
        self$df_metadata_sportsmen <- data %>% .[, c(1:8)]
        
        self$df_models %>% 
          select(-c(sample, super_pop, gender, group, sport, age, n)) %>%
          mutate(pop = as.factor(pop)) -> df_prepare_to_lda
        
        self$df_prepare_to_lda <- df_prepare_to_lda
        
        self$lda_analysis()
        self$lda_summary()
        self$lda_statistics()
        
        self$type_statistics <- "model_lda"
        
        return(cat("LDA analysis is execute on results from two models"))
      }
      
      self$df_models <- data
      self$df_metadata_sportsmen <- data %>% .[, c(1:8)]
      
      # calculate correlation between models and filter similar models by chose first
      filter_corr <- self$filter_corr_models()
       
      rownames(filter_corr) <- filter_corr$sample
      
      # calculate pca on filtered data by correaltaion
      prs_models_pca <- prcomp(filter_corr[,-c(1:8)], center = TRUE, scale. = TRUE) -> pca_results

      self$pca_results <- pca_results

      self$pc_statistics() -> pc_stat

      pc_stat %>%
        top_n(-2) %>%
        filter(t.test < 0.01) %>%
        .[,1] -> pc_to_lda

      if(length(pc_to_lda) == 0){
        self$type_statistics <- "pca"
        self$p.value_analysis <- 1
        return(cat("No PC is significant from PCA"))
      } else if(length(pc_to_lda) == 1){
        self$type_statistics <- "pca"
        self$p.value_analysis <- pc_stat %>%
          filter(PC == pc_to_lda) %>% .[,2]
        return(cat("Only one PC is significant."))
      }


      pca_results$x %>%
        as.data.frame() %>%
        rownames_to_column(var = "sample") %>%
        left_join(self$df_metadata_sportsmen, ., by = "sample") %>%
        select(c(pop, pc_to_lda)) %>%
        mutate(pop = as.factor(pop)) -> df_prepare_to_lda

      self$df_prepare_to_lda <- df_prepare_to_lda


      # self$skew_biplot()
      # self$pca_plot()
      self$lda_analysis()
      # self$lda_plots()
      self$lda_summary()
      self$lda_statistics()

    },
    
    # calculate correlation between models
    correlation_models = function() {
      self$df_models[,-c(1:8)] %>%
        cor %>%
        as.table() %>%
        as.data.frame() %>%
        set_names(c("group_1", "group_2", "cor"))
    },
    
    # filter by correlation models
    filter_corr_models = function() {
      self$correlation_models() %>%
        mutate(cor = abs(cor)) %>%
        filter(cor > 0.98) %>%
        mutate(equals = ifelse(group_1 == group_2, T, F)) %>%
        filter(equals == F) %>%
        mutate(paired = map2_chr(group_1, group_2, ~ str_flatten(sort(c(
          .x, .y
        ))))) %>%
        group_by(paired) %>%
        filter(row_number() == 1) %>%
        .[, 1] %>%
        as.data.frame() %>%
        .[, 1] %>% as.character() -> models_to_remove
      
      self$df_models %>%
        as.data.frame() %>%
        select(-models_to_remove) -> df_models_corr_filt
      
      return(df_models_corr_filt)
    },
    
    pca_analysis = function() {
      prs_models_pca <- prcomp(self$filter_corr_models()[,-c(1:8)],
                               center = TRUE,
                               scale. = TRUE) -> pca_results
      
      return(pca_results)
    },
    
    # function to create skew and biplots
    skew_biplot = function() {
      pr_var <- self$pca_results$sdev ^ 2
      pve <- pr_var / sum(pr_var)
      
      # create skew plot
      cbind(pve) %>%
        ggplot(aes(x = c(1:length(pve)), y = pve)) +
        geom_line() +
        geom_point() +
        xlab("Principal Component") +
        ylab("Proportion of Variance Explained") +
        coord_cartesian(ylim = c(0, 1)) -> skew_plot
      
      # create biplot
      autoplot(
        self$pca_results,
        data = self$df_models,
        colour = 'pop',
        loadings = TRUE,
        loadings.label = T
      ) -> biplot
      
      wrap_plots(skew_plot + biplot) -> skew_biplot
      
      self$skew_biplot_res <- skew_biplot
      
      return(skew_biplot)
    },
    
    # function to create plot for fist five PC
    pca_plot = function() {
      self$pca_results$x %>%
        as.data.frame() %>%
        rownames_to_column(var = "sample") %>%
        left_join(self$df_metadata_sportsmen, ., by = "sample") %>%
        ggpairs(
          .,
          columns = c(9:13),
          aes(colour = pop),
          progress = FALSE,
          upper = list(continuous = "density", combo = "facetdensity"),
          lower = list(combo = "facetdensity"),
          diag = list(continuous = "blank")
        ) -> pca_plot
      
      self$pca_plot_res <- pca_plot
      
      return(pca_plot)
    },
    
    # function to calculate statistics inside each PC
    pc_statistics = function() {
      self$pca_results$x %>%
        as.data.frame() %>%
        rownames_to_column(var = "sample") %>%
        left_join(self$df_metadata_sportsmen, ., by = "sample") %>%
        gather("PC", "value", -c(sample, pop, super_pop, gender, group, sport, age, n)) %>%
        group_by(PC) %>%
        nest() %>%
        mutate(t.test = map(data, ~t.test(.x[.$pop == "endurance",]$value,
                                          .x[.$pop == "speed",]$value,
                                          var.equal = TRUE)[[3]])) %>%
        unnest(t.test) %>%
        select(-data) %>% 
        as.data.frame() -> pc_stat
      
      self$pc_statistics_res <- pc_stat
      
      return(pc_stat)
    },
    
    # function to execute lda analysis
    lda_analysis = function() {
      MASS::lda(pop ~ ., data = self$df_prepare_to_lda) -> lda_results
      
      predict(lda_results, self$df_prepare_to_lda) -> lda_predict
      
      self$lda_predict <- lda_predict
    },
    
    # function to visualize lda results
    lda_plots = function() {
      
      # create plot for confusion matrix
      self$df_prepare_to_lda %>% 
        mutate(prediction = self$lda_predict$class) %>% 
        conf_mat(truth = pop, estimate = prediction) %>%
        autoplot(type = "heatmap") -> conf_mat_plot
      
      # create histogram on each group from lda
      data.frame(pop = self$df_prepare_to_lda$pop, probability = self$lda_predict$x[,1]) %>%
        ggplot(aes(x = probability)) +
        geom_histogram(aes(y = ..density..)) +
        facet_grid(pop ~ .) -> lda_histogram
      
      # create plot with roc curve
      self$df_prepare_to_lda %>%
        cbind(self$lda_predict$posterior) %>%
        mutate(prediction = self$lda_predict$class) %>%
        roc_curve(truth = pop, endurance) %>%
        autoplot() -> roc_plot

      wrap_plots(conf_mat_plot, lda_histogram, roc_plot, ncol = 2) -> lda_plots
      
      self$lda_plots_res <- lda_plots

      return(lda_plots)
    },
    
    # calculate summary of lda analysis
    lda_summary = function() {
      self$df_prepare_to_lda %>% 
        mutate(prediction = self$lda_predict$class) %>% 
        conf_mat(truth = pop, estimate = prediction) %>%
        summary() %>% 
        as.data.frame() -> lda_summary
      
      self$lda_summary_res <- lda_summary
      
      return(lda_summary)
    },
    
    lda_statistics = function(){
      data.frame(pop = self$df_prepare_to_lda$pop, prediction = self$lda_predict$x[, 1])  %>% {
        t.test(.[.$pop == "speed", 2], .[.$pop == "endurance", 2], var.eaqual = T)
      } -> t.test_prediction_lda
      
      self$lda_statistics_res <- t.test_prediction_lda
      
      self$type_statistics <- "lda"
      self$p.value_analysis <-  t.test_prediction_lda %>% .[[3]]
      
      return(t.test_prediction_lda)
    }
  )
)


# test R6class with map
permutate_dimensionality_table %>%
  mutate(n_models = map(rand_data, ~(ncol(.x) - 8))) %>% 
  unnest(n_models) %>% 
  mutate(dimensional_analysis = map(rand_data, ~{DimensionalityAnalysis$new(.x)})) %>%
  mutate(tmp = map(dimensional_analysis, ~{.x$p.value_analysis})) %>% unnest(tmp) 
  select(number, PC, t.test) %>% as.data.frame() %>% filter(number == 9)



# test each function in R6 class
test_dimensionality_class <- DimensionalityAnalysis$new(filtered_to_dimensional_analysis)

test_dimensionality_class$execute_analysis()
test_dimensionality_class$lda_summary_res
test_dimensionality_class$df_models

test_dimensionality_class$correlation_models()
test_dimensionality_class$filter_corr_models()
test_dimensionality_class$pca_analysis() %>% summary()
test_dimensionality_class$skew_biplot()
test_dimensionality_class$pca_plot()
test_dimensionality_class$df_prepare_to_lda
test_dimensionality_class$lda_analysis()
test_dimensionality_class$lda_predict
test_dimensionality_class$lda_plots()
test_dimensionality_class$lda_summary()
test_dimensionality_class$lda_statistics()  %>% .[[3]]



# prepare function for filter prs data --> only to permuate statistics
filter_prs_data <- function(data, n_cases_EUR = 2000, shapiro_threshold = 0.05) {
  data %>%
    colnames %>%
    .[str_detect(., 'shapiro.[:alpha:]+')] -> shapiro_names
  
  data %>%
    prs_statistic_preprocessing() %>%
    add_biobank_info() %>% 
    filter(type_category == "287_Origin_Categories" | is.na(type_category)) %>% 
    # filter model by n_cases_EUR 
    filter_n_cases(n_cases_EUR = {{n_cases_EUR}}) %>% 
    filter(get(shapiro_names[1]) > shapiro_threshold,
           get(shapiro_names[2]) > shapiro_threshold) %>% 
    filter(category_id %in% c(100091, 100080, 2000, 100071, 100006, 100078, 100013, 100081, 17518, 3000, "pan_biobank_created")) %>% 
    select(-c(category_id, type_category, category_description)) %>% 
    unique()  %>% 
    select(-contains("shapiro"))-> filter_data
  
  return(filter_data)
}



prepare_ranodom_data <- function(data){
  
  sportsmen_metadata %>%
    mutate(sample_rand = sample(sample), .after = "sample") %>% 
    select(-sample) -> sportsmen_metadata_rand
  
  
  prs_results_with_sport %>% 
    filter(p.value_variants == "1e-08") %>%
    filter(group == "sportsman") %>%
    mutate(p.value_variants = as.character(p.value_variants)) %>%
    select(
      -c(
        genotyping_alleles_count,
        imputing_alleles_count,
        af_alleles_count,
        missing_alleles_count,
        pop,
        super_pop,
        gender,
        group,
        sport,
        n, 
        age
      )
    ) %>% 
    left_join(., sportsmen_metadata_rand, by = c("sample" = "sample_rand")) %>%
    # rename(sample_rand = "sample") %>%
    relocate(c(pop, super_pop, gender, group, sport, age, n), .after = "sample") %>%  
    mutate(p.value_variants = as.character(p.value_variants)) -> prs_results_rand
  
  # 2. calculate stat and filter
  # 2.1 endurace vs speed
  prs_results_rand %>% 
    # create column with group
    mutate(group = ifelse(group == "sportsman", pop, group)) %>% 
    select(-c(sport, n, age)) %>% 
    statistics_sportsmen_prs(column_group = "group", group1 = "endurance", group2 = "speed") -> endurance_speed_rand
  
  # filter data
  endurance_speed_rand %>% 
    filter_prs_data(shapiro_threshold = 0.05) -> df1
  
  
  # 2.2 swim vs sportsman
  prs_results_rand %>% 
    # create column with group
    mutate(group = ifelse(sport == "swim", "swim", "sportsman")) %>%
    select(-c(sport, n, age)) %>% 
    statistics_sportsmen_prs(column_group = "group", group1 = "swim", group2 = "sportsman") -> swim_sportsmen_rand 
  
  swim_sportsmen_rand %>% 
    filter_prs_data(shapiro_threshold = 0.05) -> df2
  
  # 2.3 swim vs weights
  prs_results_rand %>% 
    # create column with group
    mutate(group = ifelse(sport == "swim" | sport == "weights", sport, group)) %>%
    select(-c(sport, n, age)) %>% 
    statistics_sportsmen_prs(column_group = "group", group1 = "swim", group2 = "weights") -> swim_weights_rand
  
  # filter data
  swim_weights_rand %>% 
    filter_prs_data(shapiro_threshold = 0.05) -> df3
  
  
  rbind(df1, df2, df3) %>% # filtered_to_dimensional_rand
    filter(t.test < 0.01) %>%
    add_samples_results(., prs_samples_results = prs_results_rand) %>%
    filter(super_pop == "sportsmen") %>%
    select(sample, model, prs_score) %>%
    unique() %>%
    spread(model, prs_score) %>%
    left_join(., sportsmen_metadata_rand, by = c("sample" = "sample_rand")) %>%
    relocate(c(pop, super_pop, gender, group, sport, age, n), .after = sample) -> filtered_to_dimensional_rand
  
  return(filtered_to_dimensional_rand)
  # return(df1)
}
