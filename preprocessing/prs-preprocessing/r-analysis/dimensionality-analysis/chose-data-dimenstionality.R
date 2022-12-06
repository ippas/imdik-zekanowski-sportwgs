#############################################################
## Stuff I have to do
## mateuszzieba97@gmail.com - Apr 2022
#############################################################

# Enable the r-universe repo
options(repos = c(
  fawda123 = 'https://fawda123.r-universe.dev',
  CRAN = 'https://cloud.r-project.org'))

# Install ggord
install.packages('ggord')

# install.packages("GGally")
require(cluster)
require(GGally)
require(gridExtra)
require(GGally)
require(Rtsne)
install.packages("yardstick")
require(yardstick)
# require(MASS)
install.packages("klaR")
install.packages('ggord')
require(klaR)

install.packages("psych")
install.packages("ggplotify")
require(ggplotify)
require(psych)
library(klaR)
library(psych)
# library(MASS)
library(ggord)
# require(cowplot)
# install.packages("ggimage")
# require(ggimage)



# prepare data
prs_statistic_preprocessing(prs_endurance_speed) %>%
  # add to result info about field and category
  add_biobank_info() %>% head
  # filter model which variants have 1e-08
  filter(p.value_variants == "1e-08") %>% 
  # filter by type_category
  filter(type_category == "277_Origin_Categories" | is.na(type_category)) %>% dim
  # filter model by n_cases_EUR 
  filter_n_cases(n_cases_EUR = 2000) %>% 
  # filter model by shapiro test
  filter(shapiro.test_endurance > 0.05,
         shapiro.test_speed > 0.05) %>%
  # filter(FDR_category < 0.25) %>%
  filter(category_id %in% c(100091, 100080, 2000, 100071, 100006, 100078, 100013, 100081, 17518, 3000, "pan_biobank_created")) %>% 
  filter(category_id %in% c(100091, 100071, 100006, 100078, "pan_biobank_created")) %>%
  select(-contains("shapiro")) %>% 
  mutate(comparison = "endurance-speed") -> df_model_1

prs_statistic_preprocessing(prs_swim_sportsmen) %>% 
  # add to result info about field and category
  add_biobank_info() %>% 
  # filter model which variants have 1e-08
  filter(p.value_variants == "1e-08") %>%
  # filter by type_category
  filter(type_category == "277_Origin_Categories" | is.na(type_category)) %>%
  # filter model by n_cases_EUR 
  filter_n_cases(n_cases_EUR = 2000) %>%
  # filter model by shapiro test
  filter(shapiro.test_sportsman > 0.05,
         shapiro.test_swim > 0.05) %>%
  # filter(t.test < stat_threshold) %>%
  filter(category_id %in% c(100091, 100080, 2000, 100071, 100006, 100078, 100013, 100081, 17518, 3000, "pan_biobank_created")) %>% 
  filter(category_id %in% c(100091, 100071, 100006, 100078, "pan_biobank_created")) %>% 
  select(-contains("shapiro")) %>% 
  mutate(comparison = "swim-sportsmen") -> df_model_2


prs_statistic_preprocessing(prs_swim_weights) %>% 
  # add to result info about field and category
  add_biobank_info() %>% 
  # filter model which variants have 1e-08
  filter(p.value_variants == "1e-08") %>%
  # filter by type_category
  filter(type_category == "277_Origin_Categories" | is.na(type_category)) %>%
  # filter model by n_cases_EUR 
  filter_n_cases(n_cases_EUR = 2000) %>% 
  # filter model by shapiro test
  filter(shapiro.test_swim > 0.05,
         shapiro.test_weights > 0.05) %>%
  filter(category_id %in% c(100091, 100080, 2000, 100071, 100006, 100078, 100013, 100081, 17518, 3000, "pan_biobank_created")) %>% dim
  filter(category_id %in% c(100091, 100071, 100006, 100078, "pan_biobank_created")) %>% 
  select(-contains("shapiro")) %>% 
  mutate(comparison = "swim-weights") -> df_model_3


# rbind(df_model_1, df_model_2, df_model_3) %>%
#   select(model, p.value_variants) %>%
#   write.table(file = "data/prs-data/dimensionality-data/all-filtered-models.tsv", 
#               row.names = FALSE,
#               quote = FALSE,
#               sep = "\t")


# prepare data to PCA and UMAP analysis
rbind(df_model_1, df_model_2, df_model_3) %>% 
  filter(p.value_variants == "1e-08") %>% 
  filter(t.test < 0.01) %>%
  add_samples_results(., prs_samples_results = prs_results_with_sport) %>%
  filter(super_pop == "sportsmen") %>% 
  # filter(n > 4) %>%
  select(sample, model, prs_score) %>% 
  unique() %>% 
  spread(model, prs_score) %>% 
  column_to_rownames(var = "sample") %>%
  as.matrix() -> filtered_to_dimensional_analysis
  

# calculate correlation between models
filtered_to_dimensional_analysis %>% 
  cor %>% 
  as.table() %>% 
  as.data.frame() %>%
  set_names(c("group_1", "group_2", "cor")) %>%
  mutate(group_1 = tidy_phenotypes(group_1),
         group_2 = tidy_phenotypes(group_2)) -> cor_models_df
  
cor_models_df %>% 
  mutate(cor = abs(cor)) %>%
  filter(cor > 0.98) %>% 
  mutate(equals = ifelse(group_1 == group_2, T, F)) %>% 
  filter(equals == F)

filtered_to_dimensional_analysis %>% .[, -c(6,7)] -> filtered_to_dimensional_analysis

# calculate pca
start <- Sys.time()
prs_models_pca <- prcomp(filtered_to_dimensional_analysis[,-c(1:7)], center = TRUE, scale. = TRUE)
end <- Sys.time()

end - start

summary(prs_models_pca)

biplot(prs_models_pca)

# skew plot and biplot
pr_var <- prs_models_pca$sdev^2
pve <- pr_var/sum(pr_var)

cbind(pve) %>%
  ggplot(aes(x = c(1:length(pve)), y = pve)) +
  geom_line() + 
  geom_point() +
  xlab("Principal Component") +
  ylab("Proportion of Variance Explained") +
  coord_cartesian(ylim = c(0,1)) -> p1

autoplot(pca_signif_sportsmen, 
         data = df_to_dimensional_analysis, 
         colour = 'pop', 
         loadings = TRUE,
         loadings.label = T) -> p2

wrap_plots(p1 + p2)


# prs_models_pca$scores %>%
prs_models_pca$x %>% 
  as.data.frame() %>%
  rownames_to_column(var = "sample") %>%
  left_join(., sportsmen_control_polish, by = "sample") %>%
  left_join(., sportsmen_pheno, by = c("sample" = "sample_id")) %>% 
  filter(super_pop == "sportsmen") %>%
  ggpairs(., columns = c(2:6), aes(colour = pop),
          progress = FALSE,
          upper = list(continuous = "density", combo = "facetdensity"),
          lower = list(combo = "facetdensity"),
          diag = list(continuous = "blank")) -> pc_plot

# lda analysis
prs_models_pca$x %>%
  as.data.frame() %>%
  rownames_to_column(var = "sample") %>%
  left_join(., sportsmen_control_polish, by = "sample") %>%
  left_join(., sportsmen_pheno, by = c("sample" = "sample_id")) %>% 
  filter(super_pop == "sportsmen") %>% 
  select(pop, PC1, PC4) %>%
  mutate(pop = as.factor(pop)) -> to_lda

MASS::lda(pop ~ ., data = to_lda) -> lda_speed_endrance

predict(lda_speed_endrance, to_lda) -> predict_speed_endurance
  
MASS::ldahist(data = p$x[,1], g = to_lda$pop)

data.frame(pop = to_lda$pop, probability = p$x[,1]) %>%
  ggplot(aes(x = probability)) +
  geom_histogram(aes(y = ..density..)) +
  facet_grid(pop ~ .) -> lda_histogram

partimat_plot <- recordPlot()
partimat(pop ~ ., data = to_lda, method = "lda")


to_lda %>% 
  mutate(prediction = p$class) %>% 
  conf_mat(truth = pop, estimate = prediction) %>%
  autoplot(type = "heatmap") -> conf_mat_plot

to_lda %>% 
  mutate(prediction = p$class) %>% 
  conf_mat(truth = pop, estimate = prediction) %>%
  summary() %>% 
  as.data.frame() -> lda_summary

to_lda %>% 
  cbind(p$posterior) %>% 
  mutate(prediction = p$class) %>% 
  roc_curve(truth = pop, endurance) %>%
  autoplot() -> roc_plot


data.frame(pop = to_lda$pop, prediction = p$x[, 1])  %>% {
  t.test(.[.$pop == "speed", 2], .[.$pop == "endurance", 2], var.eaqual = T)
} -> t.test_prediction


# prs_models_pca$scores %>% 
prs_models_pca$x %>%
  as.data.frame() %>%
  rownames_to_column(var = "sample") %>%
  left_join(., sportsmen_control_polish, by = "sample") %>%
  left_join(., sportsmen_pheno, by = c("sample" = "sample_id")) %>% 
  filter(super_pop == "sportsmen") %>% 
  gather("PC", "value", -c(sample, pop, super_pop, gender, group, sport, age, n)) %>%
  group_by(PC) %>%
  nest() %>% 
  mutate(t.test = map(data, ~t.test(.x[.$pop == "endurance",]$value,
                                    .x[.$pop == "speed",]$value,
                                    var.equal = TRUE)[[3]])) %>%
  unnest(t.test) %>%
  select(-data) %>% 
  as.data.frame() -> pc_stat


set.seed(1234)
tsne_output <- Rtsne(filtered_models_to_pca, PCA = T, max_iter = 1300, perplexity = 5)



set.seed(1234)
tsne_output$Y %>% 
  as.data.frame() %>% 
  cbind(., rownames(filtered_models_to_pca)) %>%
  set_colnames(c("tsne1", "tsne2", "sample")) %>%
  left_join(., sportsmen_control_polish, by = "sample")%>% 
  left_join(., sportsmen_pheno, by = c("sample" = "sample_id")) %>% 
  mutate(kmeans_2 = {.[,c(1,2)] %>% kmeans(., centers = 2, nstart = 100) %>% .$cluster %>% as.factor}) %>%
  mutate(kmeans_4 = {.[,c(1,2)] %>% kmeans(., centers = 4, nstart = 100) %>% .$cluster %>% as.factor}) %>%
  mutate(kmeans_6 = {.[,c(1,2)] %>% kmeans(., centers = 6, nstart = 100) %>% .$cluster %>% as.factor}) -> tsne_cluster_df

tsne_cluster_df %>%
  gather(type_cluster, cluster, -c(sample, tsne1, tsne2, super_pop, gender, group, sport, age, n)) %>%
  group_by(type_cluster) %>%
  nest() %>%
  mutate(tsne_plot = map(data, ~{ggplot(.x, aes(x = tsne1, y = tsne2, color = cluster)) + geom_point()})) %>%
  .$tsne_plot %>% wrap_plots(ncol = 2) -> tsne_plot

tsne_cluster_df %>%
  gather(type_cluster, cluster, -c(sample, tsne1, tsne2, super_pop, gender, group, sport, age, n, pop)) %>%
  group_by(type_cluster) %>% 
  nest() %>%
  mutate(table_comparision = map(data, ~{.x %>% select(pop, cluster) %>% table()})) %>% .$table_comparision -> pop_cluster_table


tsne_cluster_df %>% 
  select(pop, kmeans_2) %>% 
  mutate(prediction = ifelse(kmeans_2 == 2, "speed", "endurance")) %>% 
  mutate(pop = as.factor(pop), prediction = as.factor(prediction)) %>% 
  conf_mat(truth = pop, estimate = "prediction") %>% autoplot(type = "heatmap")




# create html
rmarkdown::render(
  input = "preprocessing/prs-preprocessing/r-analysis/dimensionality-analysis/report-dimensional-analysis.Rmd",
  output_file = "report-pca-prs-scores.html",
  params = list(
    cor_matrix = cor_models_df,
    summary_pca = as.data.frame(summary(prs_models_pca)$importance),
    skew_biplot = wrap_plots(p1 + p2),
    rotation_pca = as.data.frame(prs_models_pca$rotation) %>% rownames_to_column(var = "model") %>% mutate(model = tidy_phenotypes(model)),
    pc_plot = pc_plot,
    pc_stat = pc_stat,
    tsne_plot = tsne_plot,
    pop_cluster_table = pop_cluster_table,
    lda_summary = lda_summary,
    lda_plot = wrap_plots(conf_mat_plot, lda_histogram, roc_plot, ncol = 2),
    partimat_plot = partimat_plot,
    t.test_prediction = t.test_prediction
  )
)


# hierhical clusters

install.packages("forecast")
install.packages("caret")
install.packages('caret', dependencies = TRUE)
install.packages('e1071', dependencies=TRUE)
require(forecast)
require(caret)



########
# UMAP #
########

# test of umap
install.packages("umap")
install.packages("palmerpenguins")


require(palmerpenguins)
require(umap)


filtered_models_to_pca %>% .[., c(1:40)] %>%
  scale() %>% 
  umap()

filtered_models_to_pca %>%
  scale() %>%
  umap() -> models_umap

umap(filtered_models_to_pca) -> models_umap

head(models_umap$layout, 3)

models_umap$layout %>% 
  as.data.frame() %>%
  rownames_to_column(var = "sample") %>%
  left_join(., sportsmen_control_polish, by = "sample") %>% 
  # left_join(., sportsmen_pheno, by = c("sample" = "sample_id")) %>%
  # filter(super_pop == "sportsmen") %>%
  ggplot(aes(x = V1, y = V2, color = pop)) +
  geom_point()



# test of tsne --> DataCamp
install.packages("Rtsne")
require(Rtsne)

set.seed(1234)
tsne_output <- Rtsne(filtered_models_to_pca, PCA = T, max_iter = 1000, perplexity = 4)

tsne_output$Y %>% 
  as.data.frame() %>%
  cbind(., rownames(filtered_models_to_pca)) %>%
  set_colnames(c("tsne1", "tsne2", "sample")) %>%
  left_join(., sportsmen_control_polish, by = "sample")%>%
  ggplot(aes(x = tsne1, y = tsne2, color = pop)) + 
  geom_point()



# prs_models_pca$x %>% 
#   as.data.frame() %>%
#   rownames_to_column(var = "sample") %>%
#   left_join(., sportsmen_control_polish, by = "sample") %>%
#   left_join(., sportsmen_pheno, by = c("sample" = "sample_id")) %>%
#   filter(super_pop == "sportsmen") %>%
#   ggplot(aes(x = PC1, y = PC3, color = pop)) +
#   geom_point()






# kmeans clusters
tsne_output$Y %>% 
  as.data.frame() %>% 
  cbind(., rownames(filtered_models_to_pca)) %>%
  set_colnames(c("tsne1", "tsne2", "sample")) %>%
  left_join(., sportsmen_control_polish, by = "sample")%>% 
  left_join(., sportsmen_pheno, by = c("sample" = "sample_id")) %>% 
  mutate(kmeans = {.[,c(1,2)] %>% kmeans(., centers = 6, nstart = 100) %>% .$cluster %>% as.factor}) %>%
  # mutate(four_category = ifelse(sport == "weights", "weights", ifelse(sport == "swim", "swim", pop))) %>%
  mutate(hclust_avr = {.[,c(1,2)] %>% dist() %>% hclust(., method = "ward.D2") %>% cutree(k = 2)}) %>%
  mutate(hclust_single =  {.[,c(1,2)] %>% dist() %>% hclust(., method = "single") %>% cutree(k = 2)}) %>%
  mutate(hclust_complete =  {.[,c(1,2)] %>% dist() %>% hclust(., method = "complete") %>% cutree(k = 2)}) %>%
  mutate(hclust_mcquitty =  {.[,c(1,2)] %>% dist() %>% hclust(., method = "mcquitty") %>% cutree(k = 2)}) %>%
  mutate(hclust_median =  {.[,c(1,2)] %>% dist() %>% hclust(., method = "median") %>% cutree(k = 2)}) %>%
  mutate(hclust_centroid =  {.[,c(1,2)] %>% dist() %>% hclust(., method = "centroid") %>% cutree(k = 2)}) %>% 
  ggplot(aes(x = tsne1, y = tsne2, color = kmeans)) +
  geom_point() +
  stat_ellipse(fill = pop)


tsne_output$Y %>% 
  as.data.frame() %>% 
  cbind(., rownames(filtered_models_to_pca)) %>%
  set_colnames(c("tsne1", "tsne2", "sample")) %>%
  left_join(., sportsmen_control_polish, by = "sample")%>% 
  left_join(., sportsmen_pheno, by = c("sample" = "sample_id")) %>% 
  mutate(clusters = {.[,c(1,2)] %>% kmeans(., centers = 2, nstart = 100) %>% .$cluster %>% as.factor}) %>%
  mutate(four_category = ifelse(sport == "weights", "weights", ifelse(sport == "swim", "swim", pop))) %>%
  # arrange(., by = sport)
  # .[sort(.$sport),]
  ggplot(aes(x = tsne1, y = tsne2, color = clusters)) + 
  geom_point()