install.packages("furrr")

require(R6)
require(furrr)
require(yardstick)
require(GGally)

###########################################
# create class to dimensionality analysis #
###########################################
DimensionalityAnalysis <- R6Class(
  "DimensionalityAnalysisPRS",
  
  public = list(
    df_models = NULL,
    df_metadata_sportsmen = NULL,
    filter_corr_models_res = NULL,
    pca_results = NULL,
    pc_statistics_res = NULL,
    
    df_prepare_to_lda = NULL,
    lda_results = NULL,
    lda_predict = NULL,
    lda_summary_res = NULL,
    lda_statistics_res = NULL,
    lda_slope = NULL,
    lda_intercept = NULL,
    lda_classification_plot_res = NULL,
    
    skew_plot_res = NULL,
    biplot_res = NULL,
    pca_plot_res = NULL,
    conf_mat_plot_res = NULL,
    lda_hist_res = NULL,
    roc_curve_res = NULL,
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
        # self$type_statistics <- "model_lda"

        self$df_models <- data
        self$df_metadata_sportsmen <- data %>% .[, c(1:8)]
        
        self$df_models %>% 
          select(-c(sample, super_pop, gender, group, sport, age, n)) %>%
          mutate(pop = as.factor(pop)) -> df_prepare_to_lda
        
        self$df_prepare_to_lda <- df_prepare_to_lda
        
        self$lda_analysis()
        self$lda_summary()
        self$lda_statistics()
        self$lda_slope_intercept()
        
        # self$type_statistics <- "model_lda"
        
        return(cat("LDA analysis is execute on results from two models"))
      }
      
      self$df_models <- data
      self$df_metadata_sportsmen <- data %>% .[, c(1:8)]
      
      # calculate correlation between models and filter similar models by chose first
      self$filter_corr_models() 
      
      # calculate pca on filtered data by correlation
      self$pca_analysis()

      # self$pc_statistics() -> pc_stat
      self$pc_statistics()

      # pc_stat %>%
      self$pc_statistics_res %>%
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


      self$pca_results$x %>%
        as.data.frame() %>%
        rownames_to_column(var = "sample") %>%
        left_join(self$df_metadata_sportsmen, ., by = "sample") %>%
        select(c(pop, pc_to_lda)) %>%
        mutate(pop = as.factor(pop)) -> df_prepare_to_lda

      self$df_prepare_to_lda <- df_prepare_to_lda


      self$skew_plot()
      self$biplot()
      self$pca_plot()
      self$lda_analysis()
      self$lda_summary()
      self$lda_statistics()
      self$conf_mat_plot()
      self$lda_hist()
      self$roc_curve()

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
        select(-c(models_to_remove)) -> df_models_corr_filt
      
      rownames(df_models_corr_filt) <- df_models_corr_filt$sample
      
      self$filter_corr_models_res <- df_models_corr_filt
      
      return(df_models_corr_filt)
    },
    
    # calculate results for pca
    pca_analysis = function() {
      prs_models_pca <- prcomp(self$filter_corr_models_res[,-c(1:8)],
                               center = TRUE,
                               scale. = TRUE) -> pca_results
      
      self$pca_results <- pca_results
      
      return(pca_results)
    },
    
    # function to create skew plot
    skew_plot = function(){
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
      
      self$skew_plot_res <- skew_plot
      
      return(skew_plot)
    },
    
    # function to create biplot
    biplot = function(){
      autoplot(
        self$pca_results,
        data = self$df_models,
        colour = 'pop',
        loadings = TRUE,
        loadings.label = T
      ) -> biplot
      
      self$biplot_res <- biplot
      
      return(biplot)
    },
    
    # function to create plot for fist five PC
    pca_plot = function() {
      number_col <- self$pca_results$x %>% ncol %>% {ifelse(. >= 5, 5 + 8, . + 8)}
      
      self$pca_results$x %>%
        as.data.frame() %>%
        rownames_to_column(var = "sample") %>%
        left_join(self$df_metadata_sportsmen, ., by = "sample") %>%
        ggpairs(
          .,
          columns = c(9:number_col),
          aes(colour = pop),
          progress = FALSE,
          upper = list(continuous = "density", combo = "facetdensity"),
          lower = list(combo = "facetdensity"),
          diag = list(continuous = "blank")
        ) -> pca_plot
      
      self$pca_plot_res <- pca_plot
      
      return(pca_plot)
    },
    
    # function to calculate t.test for each PC
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
      
      self$lda_results <- lda_results
      
      self$lda_predict <- lda_predict
    },
    
    # fucntion to create plot of confusion matrix
    conf_mat_plot = function(){
      self$df_prepare_to_lda %>%
        mutate(prediction = self$lda_predict$class) %>%
        conf_mat(truth = pop, estimate = prediction) %>%
        autoplot(type = "heatmap") -> conf_mat_plot

      self$conf_mat_plot_res <- conf_mat_plot

      return(conf_mat_plot)
    },

    # function to create histogram from results of LDA
    lda_hist = function(){
      data.frame(pop = self$df_prepare_to_lda$pop, probability = self$lda_predict$x[,1]) %>%
        ggplot(aes(x = probability)) +
        geom_histogram(aes(y = ..density..), bins = 20) +
        facet_grid(pop ~ .) -> lda_hist

      self$lda_hist_res <- lda_hist

      return(lda_hist)
    },

    # function to create ROC curve
    roc_curve = function(){
      self$df_prepare_to_lda %>%
        cbind(self$lda_predict$posterior) %>%
        mutate(prediction = self$lda_predict$class) %>%
        yardstick::roc_curve(truth = pop, endurance) %>%
        autoplot() -> roc_curve
      
      self$roc_curve_res <- roc_curve

      return(roc_curve)
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
    
    # calculate t.test for lda analysis
    lda_statistics = function(){
      data.frame(pop = self$df_prepare_to_lda$pop, prediction = self$lda_predict$x[, 1])  %>% {
        t.test(.[.$pop == "speed", 2], .[.$pop == "endurance", 2], var.eaqual = T)
      } -> t.test_prediction_lda
      
      self$lda_statistics_res <- t.test_prediction_lda
      
      self$type_statistics <- "lda"
      self$p.value_analysis <-  t.test_prediction_lda %>% .[[3]]
      
      return(t.test_prediction_lda)
    },
    
    # function to calculate slope and intercept for lda analysis
    lda_slope_intercept = function(){
      self$df_prepare_to_lda %>% 
        filter(pop == "speed") %>% .[, c(2,3)] -> x1
      
      self$df_prepare_to_lda %>%
        filter(pop == "endurance") %>% .[, c(2,3)] -> x2
      
      n1 <- nrow(x1)
      n2 <- nrow(x2)
      n <- n1 + n2
      
      x <- rbind(x1, x2)
      y <- c(rep("speed", n1), rep("endurance", n2))
      
      # Plot data
      ggplot(data.frame(x1=x[,1], x2=x[,2], y=y), aes(x=x1, y=x2, color=as.factor(y))) +
        geom_point()
      
      # Calculate pi_hat_1 and pi_hat_2
      pi_hat_1 <- n1 / n
      pi_hat_2 <- n2 / n
      
      # Calculate mu_hat_1 and mu_hat_2
      mu_hat_1 <- colMeans(x1)
      mu_hat_2 <- colMeans(x2)
      
      # Calculate cov_hat_1 and cov_hat_2
      cov_hat_1 <- cov(x1)
      cov_hat_2 <- cov(x2)
      
      # Calculate cov_hat
      cov_hat <- (cov_hat_1 + cov_hat_2) / 2
      
      cov_inv <- solve(cov_hat)
      
      # Calculate slope and intercept
      slope_vec <- cov_inv %*% (mu_hat_1 - mu_hat_2)
      slope <- -slope_vec[1] / slope_vec[2]
      intercept_partial <- log(pi_hat_2) - log(pi_hat_1) + 0.5 * t(mu_hat_1) %*% cov_inv %*% mu_hat_1 - 0.5 * t(mu_hat_2) %*% cov_inv %*% mu_hat_2
      intercept <- intercept_partial / slope_vec[2]
      
      self$lda_slope <- slope
      self$lda_intercept <- intercept
    },
    
    # function to create classification plot after 
    lda_classification_plot = function(){
      self$df_prepare_to_lda %>%
        mutate(label = ifelse(pop == "speed", "s", "e")) %>% 
        mutate(predict = lda_predict$class) %>% 
        mutate(color = ifelse(pop == predict, "black", "red"))  %>% 
        mutate(color = as.factor(color)) %>%
        ggplot(aes(x = PC1, y = PC4)) +
        geom_text(aes(label = label, color = color)) +
        scale_color_identity() +
        geom_abline(slope = slope, intercept = intercept) +
        labs(title = "Classification sportsmen to group via LDA") + 
        theme(plot.title = element_text(size = 18)) -> lda_plot
        
      self$lda_classification_plot_res <- lda_plot
      
      return(lda_plot)
    } 
  )
)


########################################################################
# prepare function for filter prs data --> only to permuate statistics #
########################################################################
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

####################################
# function for prepare random data #
####################################
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
  
  
  rbind(df1, df2, df3) %>% 
    filter(t.test < 0.01) %>%
    add_samples_results(., prs_samples_results = prs_results_rand) %>%
    filter(super_pop == "sportsmen") %>%
    select(sample, model, prs_score) %>%
    unique() %>%
    spread(model, prs_score) %>%
    left_join(., sportsmen_metadata_rand, by = c("sample" = "sample_rand")) %>%
    relocate(c(pop, super_pop, gender, group, sport, age, n), .after = sample) -> filtered_to_dimensional_rand
  
  return(filtered_to_dimensional_rand)
}
