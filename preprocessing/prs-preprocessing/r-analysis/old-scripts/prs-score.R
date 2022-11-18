#####################################
# Script write in r.version = 4.0.3 #
#####################################

##############################
# Installing needed packages #
##############################
install.packages("magrittr")
install.packages("tidyverse")
install.packages("pryr")
install.packages("cape")
install.packages("dartR")
install.packages("strex")

require(strex)
require(magrittr)
require(dplyr)
require(stats)
require(pryr)
require(ggplot2)
require(tidyverse)
require(cape)
require(dartR)
require(stringr)


# read data frame with results prs
prs_results <- read.table('/home/mateusz/tmp_wgs/prs-score.tsv', header = TRUE) %>%
  rename(p.value_variants = p.value)

prs_results_pheno <- left_join(sportsmen_control_polish, prs_results, by = "sample")

prs_results_rm_alternate_loci <- read.table('/home/mateusz/tmp_wgs/prs-score-rm-alternate-loci.tsv', header = TRUE) %>% 
  rename(p.value_variants = p.value)

prs_results_rm_alternate_loci_pheno <- left_join(sportsmen_control_polish, 
                                                 prs_results_rm_alternate_loci, 
                                                 by = "sample") 


# phenocode_data <-  read.table('/home/mateusz/tmp_wgs/phenocode-data.tsv', sep = "\t",fill = T, header = F) 
phenocode_data <- read.csv("/home/mateusz/tmp_wgs/phenocode-data.tsv", sep = "\t") %>% 
  .[, 1:38] %>%
  mutate(model_sign = paste(phenocode, pheno_sex, coding, sep = "-"))

constant <- function(values){
  ifelse(length(unique(values)) == 1, T, F)
}

################
# Analysis prs #
################

# 1. code responsible for execute statistic
prs_results_pheno %>%
  group_by(model) %>% 
  nest() %>% 
  mutate(constant_control = map(data, ~constant(.x[which(.$group == "sportsman" | .$group == "control"),]$prs_score))) %>%
  mutate(constant_polish = map(data, ~constant(.x[which(.$group == "sportsman" | .$group == "polish_control"),]$prs_score))) %>%
  unnest(constant_control, constant_polish) %>% 
  filter(constant_control != TRUE & constant_polish != TRUE) %>% 
  select(-c(constant_control, constant_polish)) %>%
  mutate(t.test_control = map(data, ~t.test(.x[.$group == "control",]$prs_score,
                                    .x[.$group == "sportsman",]$prs_score,
                                    var.equal = TRUE)[[3]]),
         t.test_genotyping = map(data,  ~ifelse(inherits(try(t.test(.x[.$group == "control",]$genotyping_alleles_count, .x[.$group == "sportsman",]$genotyping_alleles_count, var.equal = T)), "try-error"), 
                                                1, 
                                                t.test(.x[.$group == "control",]$genotyping_alleles_count, .x[.$group == "sportsman",]$genotyping_alleles_count, var.equal = T)[[3]])),
         mean_control_genotyping = map(data, ~mean(.x[.$group == "control", ]$genotyping_alleles_count)),
         mean_sportsman_genotyping = map(data, ~mean(.x[.$group == "sportsman",]$genotyping_alleles_count)),
         # wilcoxon_control = map(data, ~wilcox.test(.x[.$group == "control",]$prs_score,
         #                                                .x[.$group == "sportsman",]$prs_score)[[3]]),
         # kolmogorov.smirnov_control = map(data, ~ks.test(.x[.$group == "control",]$prs_score,
         #                                         .x[.$group == "sportsman",]$prs_score)[[2]]),
         t.test_polish = map(data, ~t.test(.x[.$group == "polish_control",]$prs_score,
                                    .x[.$group == "sportsman",]$prs_score,
                                    var.equal = TRUE)[[3]]),
         # wilcoxon_polish = map(data, ~wilcox.test(.x[.$group == "polish_control",]$prs_score,
         #                                           .x[.$group == "sportsman",]$prs_score)[[3]]),
         # kolmogorov.smirnov_polish = map(data, ~ks.test(.x[.$group == "polish_control",]$prs_score,
         #                                                 .x[.$group == "sportsman",]$prs_score)[[2]])
         ) %>%
  unnest(t.test_control, t.test_polish, wilcoxon_control, wilcoxon_polish, t.test_genotyping, 
         mean_control_genotyping, mean_sportsman_genotyping) -> prs_result_stat


# 2. filtering significat features
prs_result_stat %>%
  .[order(.$t.test_control),] %>% 
  select(-data) %>%
  mutate(FDR_control = p.adjust(t.test_control, method = "fdr"),
         FDR_polish = p.adjust(t.test_polish, method = "fdr")) %>% 
  filter(FDR_control < 0.001 & FDR_polish < 0.01)

# 3. filter top model
prs_result_stat %>%
  .[order(.$t.test_control),] %>% 
  select(-data) %>%
  as.data.frame %>% 
  mutate(FDR_control = p.adjust(t.test_control, method = "fdr"),
         FDR_polish = p.adjust(t.test_polish, method = "fdr")) %>%
  filter(FDR_polish < 0.01) %>%
  head(20) %>%
  .[,1] %>% as.character() -> top_model

# 4. generate plot for features
prs_results_pheno %>% 
  filter(model %in% top_model) %>%
  ggplot(aes(x = prs_score)) +
  geom_histogram(aes(y=..density.., fill = group), position = "identity", alpha=0.4) +
  geom_density(aes(y=..density.., color = group)) +
  facet_wrap(model ~ ., scales = "free") +
  theme(legend.position="bottom")
  
  
  
#######################################
# Analysis prs without alternate loci #
#######################################

# 1. code responsible for execute statistic
prs_results_rm_alternate_loci_pheno %>% 
  filter(p.value_variants == "1e-08") %>%
  left_join(sportsmen_pheno, by = c("sample" = "sample_id")) %>% 
  # filter(sport == "swim" | is.na(sport)) %>% 
  select(-c(sport, n, age)) %>%
  mutate(p.value_variants = as.character(p.value_variants)) %>%
  group_by(model, p.value_variants) %>% 
  nest() %>% 
  mutate(constant_control = map(data, ~constant(.x[which(.$group == "sportsman" | .$group == "control"),]$prs_score))) %>%
  mutate(constant_polish = map(data, ~constant(.x[which(.$group == "sportsman" | .$group == "polish_control"),]$prs_score))) %>%
  unnest(constant_control, constant_polish) %>% 
  filter(constant_control != TRUE & constant_polish != TRUE) %>% 
  select(-c(constant_control, constant_polish)) %>%
  mutate(t.test_control = map(data, ~t.test(.x[.$group == "control",]$prs_score,
                                            .x[.$group == "sportsman",]$prs_score,
                                            var.equal = TRUE)[[3]]),
         # t.test_control = map(data, ~ifelse(inherits(try(t.test(.x[.$group == "control",]$prs_score,
         #                                                        .x[.$group == "sportsman"]$prs_score,
         #                                                        var.equal = TRUE)), 
         #                                             "try-error"),
         #                                    1,
         #                                    t.test(.x[.$group == "control",]$prs_score,
         #                                           .x[.$group == "sportsman"]$prs_score,
         #                                           var.equal = TRUE)[[3]])),
         t.test_genotyping = map(data,  ~ifelse(inherits(try(t.test(.x[.$group == "control",]$genotyping_alleles_count, .x[.$group == "sportsman",]$genotyping_alleles_count, var.equal = T)), "try-error"), 
                                                1, 
                                                t.test(.x[.$group == "control",]$genotyping_alleles_count, .x[.$group == "sportsman",]$genotyping_alleles_count, var.equal = T)[[3]])),
         mean_control_genotyping = map(data, ~mean(.x[.$group == "control", ]$genotyping_alleles_count)),
         mean_sportsman_genotyping = map(data, ~mean(.x[.$group == "sportsman",]$genotyping_alleles_count)),
         # wilcoxon_control = map(data, ~wilcox.test(.x[.$group == "control",]$prs_score,
         #                                           .x[.$group == "sportsman",]$prs_score)[[3]]),
         # kolmogorov.smirnov_control = map(data, ~ks.test(.x[.$group == "control",]$prs_score,
         #                                                 .x[.$group == "sportsman",]$prs_score)[[2]]),
         t.test_polish = map(data, ~t.test(.x[.$group == "polish_control",]$prs_score,
                                           .x[.$group == "sportsman",]$prs_score,
                                           var.equal = TRUE)[[3]]),
         # wilcoxon_polish = map(data, ~wilcox.test(.x[.$group == "polish_control",]$prs_score,
         #                                          .x[.$group == "sportsman",]$prs_score)[[3]]),
         # kolmogorov.smirnov_polish = map(data, ~ks.test(.x[.$group == "polish_control",]$prs_score,
         #                                                .x[.$group == "sportsman",]$prs_score)[[2]]),
         t.test_control_polish = map(data,  ~ifelse(inherits(try(t.test(.x[.$group == "control",]$prs_score, .x[.$group == "polish_control",]$prs_score, var.equal = T)), "try-error"), 
                                                              1, 
                                                              t.test(.x[.$group == "control",]$prs_score, .x[.$group == "polish_control",]$prs_score, var.equal = T)[[3]])),
         shapiro.test_sportsman = map(data,  ~ifelse(inherits(try(shapiro.test(.x[.$group == "sportsman",]$prs_score)), "try-error"),
                                                     0,
                                                     shapiro.test(.x[.$group == "sportsman",]$prs_score)[[2]])),
         shapiro.test_control = map(data,  ~ifelse(inherits(try(shapiro.test(.x[.$group == "control",]$prs_score)), "try-error"),
                                                     0,
                                                     shapiro.test(.x[.$group == "control",]$prs_score)[[2]])),
         shapiro.test_polish = map(data,  ~ifelse(inherits(try(shapiro.test(.x[.$group == "polish_control",]$prs_score)), "try-error"),
                                                   0,
                                                   shapiro.test(.x[.$group == "polish_control",]$prs_score)[[2]]))
         # shapiro.test_sportsman = map(data, ~shapiro.test(.x[.$group == "sportsman",]$prs_score)[[2]])
  ) %>%
  unnest(t.test_control, t.test_polish, t.test_genotyping, t.test_control_polish, 
         mean_control_genotyping, mean_sportsman_genotyping, 
         shapiro.test_sportsman, shapiro.test_control, shapiro.test_polish) -> prs_result_stat_rm_alternate_loci


# 2. filtering significat features
# prs_result_stat_rm_alternate_loci %>%
prs_sportsmen_control %>% 
  .[order(.$t.test_control),] %>% 
  select(-data) %>%
  as.data.frame() %>% 
  filter(shapiro.test_sportsman > 0.000001) %>% 
  filter(shapiro.test_control > 0.0001) %>% 
  mutate(ratio_genotyped = mean_sportsman_genotyping/mean_control_genotyping) %>% 
  filter(ratio_genotyped > 0.9 | ratio_genotyped < 1.1) %>% 
  mutate(model_sign = {str_before_nth(as.character(.$model), "-", 4) %>% str_after_first(., "-")}) %>% 
  left_join(., {phenocode_data %>% select(c(model_sign, n_cases_EUR))}, by = "model_sign") %>%
  filter(n_cases_EUR > 2000) %>%
  filter(t.test_polish < 0.1) %>% 
  filter(t.test_control_polish > 0.05) %>%
  mutate(FDR_control = p.adjust(t.test_control, method = "fdr")) %>% 
  filter(FDR_control < 0.05)

# 3. filter top model
prs_result_stat_rm_alternate_loci %>%
  .[order(.$t.test_control),] %>% 
  select(-c(data)) %>%
  as.data.frame %>% 
  filter(shapiro.test_sportsman > 0.05) %>%
  filter(shapiro.test_control > 0.05) %>% 
  # filter(shapiro.test_sportsman > 0.000001) %>%
  # filter(shapiro.test_control > 0.0001) %>%
  mutate(ratio_genotyped = mean_sportsman_genotyping/mean_control_genotyping) %>% 
  filter(ratio_genotyped > 0.9 | ratio_genotyped < 1.1) %>% 
  mutate(model_sign = {str_before_nth(as.character(.$model), "-", 4) %>% str_after_first(., "-")}) %>% 
  left_join(., {phenocode_data %>% select(c(model_sign, n_cases_EUR))}, by = "model_sign") %>%
  filter(n_cases_EUR > 2000) %>%
  filter(t.test_polish < 0.05) %>% 
  filter(t.test_control_polish > 0.05) %>% 
  mutate(FDR_control = p.adjust(t.test_control, method = "fdr")) %>% 
  filter(FDR_control < 0.05) %>% 
  .[,1] %>% as.character() -> top_model



# 4. generate plot for features
prs_results_rm_alternate_loci_pheno %>% 
  filter(model %in% top_model) %>%
  mutate(model = str_replace_all(model, "biobankuk-", "")) %>%
  mutate(model = str_replace_all(model, "-EUR", "")) %>%
  mutate(model = str_replace_all(model, "-both_sexes-", "")) %>% 
  ggplot(aes(x = prs_score)) +
  geom_histogram(aes(y=..density.., fill = group), position = "identity", alpha=0.4) +
  geom_density(aes(y=..density.., color = group)) +
  facet_wrap(model ~ ., scales = "free") +
  theme(legend.position="bottom")

#########################################
# customize parameters to filter models #
#########################################
names_plot <- c(
  "biobankuk-136-both_sexes--number_of_operations_self_reported-EUR" = "Number of operations\n self reported",
  "biobankuk-41200-both_sexes-A651-operative_procedures_main_opcs4-EUR" = "Carpal tunnel syndrome",
  "biobankuk-1548-both_sexes--variation_in_diet-EUR" = "Variation in diet",
  "biobankuk-1697-both_sexes--comparative_height_size_at_age_10-EUR" = "Comparative height\n size at age 10",
  "biobankuk-20002-both_sexes-1478-non_cancer_illness_code_self_reported-EUR" = "Cervical spondylosis",
  "biobankuk-20088-both_sexes-350-types_of_spreads_sauces_consumed-EUR" = "Other types of spreads\n sauces consumed",
  "biobankuk-20150-both_sexes--forced_expiratory_volume_in_1_second_fev1_best_measure-EUR" = "Forced expiratory\n volume in 1 second", 
  "biobankuk-23129-both_sexes--trunk_fat_free_mass-EUR"  = "Trunk fat free mass",
  "biobankuk-23130-both_sexes--trunk_predicted_mass-EUR" = "Trunk predicted mass",
  "biobankuk-274-both_sexes--gout_and_other_crystal_arthropathies-EUR" = "Gout and other\n crystal arthropathies",
  "biobankuk-5115-both_sexes--3mm_cylindrical_power_angle_right_-EUR"   = "3mm cylindrical power\n angle right (eye)")


prs_results_rm_alternate_loci_pheno %>%
  filter(model %in% top_model) %>%
  ggplot(aes(x = prs_score)) +
  geom_histogram(aes(y=..density.., fill = group), position = "identity", alpha=0.4) +
  geom_density(aes(y=..density.., color = group)) +
  facet_wrap(model ~ ., scales = "free",  labeller = labeller(model = names_plot)) +
  theme(legend.position="bottom",
        strip.text = element_text(size = 12, margin = margin()))


png("/home/mateusz/projects/plots/features-sporstmen-control.png",
    width = 7016,
    height = 4960,
    res = 600)

# 4. generate plot for features
prs_results_rm_alternate_loci_pheno %>%
  filter(model %in% top_model) %>%
  ggplot(aes(x = prs_score)) +
  geom_histogram(aes(y=..density.., fill = group), position = "identity", alpha=0.4) +
  geom_density(aes(y=..density.., color = group)) +
  facet_wrap(model ~ ., scales = "free",  labeller = labeller(model = names_plot)) +
  theme(legend.position="bottom",
        axis.title = element_text(size = 14),
        legend.text = element_text(size = 14),
        strip.text = element_text(size = 14)) +
  labs(x = "prs score",
       y = "density",
       fill = "",
       color = "")


dev.off()

##########################
# prs endurance vs speed #
##########################
# 1. code responsible for execute statistic between speed and endurance
prs_results_rm_alternate_loci_pheno %>% 
  mutate(p.value_variants = as.character(p.value_variants)) %>% 
  group_by(model, p.value_variants) %>% 
  nest() %>% 
  mutate(constant_control = map(data, ~constant(.x[which(.$group == "sportsman" | .$group == "control"),]$prs_score))) %>%
  mutate(constant_polish = map(data, ~constant(.x[which(.$group == "sportsman" | .$group == "polish_control"),]$prs_score))) %>%
  unnest(constant_control, constant_polish) %>% 
  filter(constant_control != TRUE & constant_polish != TRUE) %>% 
  select(-c(constant_control, constant_polish)) %>%
  mutate(t.test_sportsman = map(data,  ~ifelse(inherits(try(t.test(.x[.$pop == "endurance",]$prs_score, .x[.$pop == "speed",]$prs_score, var.equal = T)), "try-error"), 
                                       1, 
                                       t.test(.x[.$pop == "endurance",]$prs_score, .x[.$pop == "speed",]$prs_score, var.equal = T)[[3]])),
         shapiro.test_endurance = map(data,  ~ifelse(inherits(try(shapiro.test(.x[.$pop == "endurance",]$prs_score)), "try-error"),
                                                   0,
                                                   shapiro.test(.x[.$pop == "endurance",]$prs_score)[[2]])),
         shapiro.test_speed = map(data,  ~ifelse(inherits(try(shapiro.test(.x[.$pop == "speed",]$prs_score)), "try-error"),
                                                  0,
                                                  shapiro.test(.x[.$pop == "speed",]$prs_score)[[2]]))
  ) %>%
  unnest(t.test_sportsman, shapiro.test_endurance, shapiro.test_speed) -> prs_result_stat_sportsman

# 2. filtering significat features
prs_result_stat_sportsman %>%
  .[order(.$t.test_sportsman),] %>% 
  select(-c(data)) %>% 
  as.data.frame() %>% 
  mutate(model_sign = {str_before_nth(as.character(.$model), "-", 4) %>% str_after_first(., "-")}) %>% 
  left_join(., {phenocode_data %>% select(c(model_sign, n_cases_EUR))}, by = "model_sign") %>%
  filter(n_cases_EUR > 2000) %>%
  filter(shapiro.test_endurance > 0.05, shapiro.test_speed > 0.05) %>%
  mutate(FDR = p.adjust(t.test_sportsman, method = "fdr")) %>%
  filter(t.test_sportsman < 0.05)

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
  filter(model %in% top_model_sportsman) %>%
  filter(group == "sportsman") %>%
  mutate(model = str_replace_all(model, "biobankuk-", "")) %>%
  mutate(model = str_replace_all(model, "-EUR", "")) %>%
  mutate(model = str_replace_all(model, "-both_sexes", "")) %>%
  ggplot(aes(x = prs_score)) +
  geom_histogram(aes(y=..density.., fill = pop), position = "identity", alpha=0.4) +
  geom_density(aes(y=..density.., color = pop)) +
  facet_wrap(model ~ ., scales = "free") +
  theme(legend.position="bottom")
 

############
# old code #
############
# # read prs model results from prometheus
# prs.results <- read.table(pipe( 'ssh  -o "StrictHostKeyChecking no" -F /home/mateusz/.ssh/config prometheus "cat /net/archive/groups/plggneuromol/matzieb/projects/imdik-zekanowski-sportwgs/results/prs-models-results/prs-model-results.tsv"'), 
#                           header = T)
# 
# read.table(pipe( 'ssh  -o "StrictHostKeyChecking no" -F /home/mateusz/.ssh/config prometheus "cat /net/archive/groups/plggneuromol/matzieb/projects/imdik-zekanowski-sportwgs/results/prs-models-results/prs-model-results.tsv"'), 
#            header = T)
#   
# prs.results <- prs.results %>% 
#   gather(key = "model", value = "genotyping.score", -sample) 
# 
# sportsmen.control.pheno <- read.table(pipe( 'ssh  plgmatzieb@prometheus.cyfronet.pl "cat /net/archive/groups/plggneuromol/matzieb/projects/imdik-zekanowski-sportwgs/data/prs-data/sportsmen-control-pheno.tsv"'), 
#                                       header = T)



## testing
sportsmen_pheno <-  read.csv("/home/mateusz/tmp_wgs/sportsmen-pheno.tsv", sep = "\t") %>%
  group_by(sport) %>% 
  nest() %>%
  mutate(sport_size = map(data, ~count(.x))) %>%
  unnest(data, sport_size) %>%
  as.data.frame() %>%
  mutate(category_size = ifelse(n > 2, "large", "small"))


sportsmen_pheno %>%
  group_by(sport) %>% 
  nest() %>%
  mutate(sport_size = map(data, ~count(.x))) %>%
  unnest(sport_size) %>%
  filter(n > 6)
  as.data.frame() %>%
  mutate(category_size = ifelse(n > 2, "large", "small"))

prs_results_rm_alternate_loci_pheno %>%
  filter(group == "sportsman") %>% 
  left_join(sportsmen_pheno, by = c("sample" = "sample_id")) %>% 
  filter(n > 6) %>%
  # filter(pop == "endurance") %>%
  filter(model %in% top_model) %>%
  ggplot(aes(x = prs_score)) +
  geom_histogram(aes(y=..density.., fill = sport), position = "identity", alpha=0.4) +
  geom_density(aes(y=..density.., color = sport)) +
  facet_wrap(model ~ ., scales = "free",  labeller = labeller(model = names_plot)) +
  theme(legend.position="bottom",
        axis.title = element_text(size = 14),
        legend.text = element_text(size = 14),
        strip.text = element_text(size = 14)) 
  labs(x = "prs score",
       y = "density",
       fill = "",
       color = "")
  
  
  
# 1. code responsible for execute statistic between speed and endurance
prs_results_rm_alternate_loci_pheno %>% 
  mutate(p.value_variants = as.character(p.value_variants)) %>%
  filter(p.value_variants == "1e-08") %>%
  left_join(sportsmen_pheno, by = c("sample" = "sample_id")) %>% 
  filter(n > 2) %>%
  group_by(model, p.value_variants) %>% 
  nest() %>% 
  mutate(t.test_sportsman = map(data,  ~ifelse(inherits(try(t.test(.x[.$pop == "endurance",]$prs_score, .x[.$pop == "speed",]$prs_score, var.equal = T)), "try-error"), 
                                               1, 
                                               t.test(.x[.$pop == "endurance",]$prs_score, .x[.$pop == "speed",]$prs_score, var.equal = T)[[3]])),
         shapiro.test_endurance = map(data,  ~ifelse(inherits(try(shapiro.test(.x[.$pop == "endurance",]$prs_score)), "try-error"),
                                                     0,
                                                     shapiro.test(.x[.$pop == "endurance",]$prs_score)[[2]])),
         shapiro.test_speed = map(data,  ~ifelse(inherits(try(shapiro.test(.x[.$pop == "speed",]$prs_score)), "try-error"),
                                                 0,
                                                 shapiro.test(.x[.$pop == "speed",]$prs_score)[[2]]))
  ) %>%
  unnest(t.test_sportsman, shapiro.test_endurance, shapiro.test_speed) -> prs_result_stat_sportsman


# 2. filtering significat features
prs_result_stat_sportsman %>%
  .[order(.$t.test_sportsman),] %>% 
  select(-c(data)) %>% 
  as.data.frame() %>% 
  mutate(model_sign = {str_before_nth(as.character(.$model), "-", 4) %>% str_after_first(., "-")}) %>% 
  left_join(., {phenocode_data %>% select(c(model_sign, n_cases_EUR, category))}, by = "model_sign") %>%
  filter(n_cases_EUR > 2000 | is.na(n_cases_EUR)) %>%
  filter(shapiro.test_endurance > 0.05, shapiro.test_speed > 0.05) %>%
  mutate(FDR = p.adjust(t.test_sportsman, method = "fdr")) %>%
  filter(t.test_sportsman < 0.01)

# 3. filter top model
prs_result_stat_sportsman %>%
  .[order(.$t.test_sportsman),] %>% 
  select(-c(data)) %>% 
  as.data.frame() %>% 
  mutate(model_sign = {str_before_nth(as.character(.$model), "-", 4) %>% str_after_first(., "-")}) %>% 
  # left_join(., {phenocode_data %>% select(c(model_sign, n_cases_EUR))}, by = "model_sign") %>%
  left_join(., {phenocode_data %>% select(c(model_sign, n_cases_EUR, category))}, by = "model_sign") %>%
  filter(n_cases_EUR > 2000) %>%
  filter(shapiro.test_endurance > 0.05, shapiro.test_speed > 0.05) %>%
  mutate(FDR = p.adjust(t.test_sportsman, method = "fdr")) %>%
  filter(t.test_sportsman < 0.01) %>% 
  head(20)  %>% .[,1] -> top_model_sportsman


# 3. filter top model
prs_results_rm_alternate_loci_pheno %>% 
  filter(model %in% top_model_sportsman) %>%
  filter(group == "sportsman") %>%
  mutate(model = str_replace_all(model, "biobankuk-", "")) %>%
  mutate(model = str_replace_all(model, "-EUR", "")) %>%
  mutate(model = str_replace_all(model, "-both_sexes", "")) %>%
  ggplot(aes(x = prs_score)) +
  geom_histogram(aes(y=..density.., fill = pop), position = "identity", alpha=0.4) +
  geom_density(aes(y=..density.., color = pop)) +
  facet_wrap(model ~ ., scales = "free") +
  theme(legend.position="bottom")


sportsmen_control_polish %>% right_join(sportsmen_pheno, by = c("sample" = "sample_id")) %>% na.omit() %>% filter(n > 2) %>% .[,2] %>% table

# to correct join phenocode_data with prs results, because special sign exist in phenocode_data
prs_results_rm_alternate_loci %>% head


prs_results_rm_alternate_loci[grep("xant", prs_results_rm_alternate_loci$model),]

