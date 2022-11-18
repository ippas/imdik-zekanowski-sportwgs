#############################################################
## Stuff I have to do
## mateuszzieba97@gmail.com, 2022 year
#############################################################
# This code is responsible for analysis swimmers versus weightlifters

# require packages and function to analysis prs
source("preprocessing/prs-preprocessing/r-analysis/functions-biobank.R")


# # # read data 
homozygosity_results_05 <- read.table('data/prs-data/homozyg-200-prune-50-5-0.5.tsv', header = TRUE)


###########################################
# homozygosity between sportsmen controls #
###########################################

###############################
# sum per sample homozygosity #
###############################
my_comparisons <- list(c("polish_control", "sportsman"), 
                       c("control", "sportsman"))
group_colors <- c(control = "#F8766D", sportsman =  "#619CFF", polish_control = "#00BA38")

homozygosity_results_05 %>%  
  group_by(FID) %>%
  nest() %>% 
  mutate(id_sum = map(data, ~sum(.$KB))) %>%
  unnest(id_sum) %>% 
  left_join(., sportsmen_control_polish, by = c("FID" ="sample")) %>%  
  mutate(group = factor(group, levels = c("control", "polish_control", "sportsman"), ordered = TRUE)) %>% 
  {ggplot(., aes(x = id_sum)) +
      geom_histogram(aes(y=..density.., fill = group), alpha = 0.3, position = "identity") +
      geom_density(aes(y=..density.., color = group)) +
      scale_fill_manual(values = group_colors) +
      scale_color_manual(values = group_colors) + 
      theme(legend.position = "none")} -> sum_hist


homozygosity_results_05 %>%
  group_by(FID) %>%
  nest() %>% 
  mutate(id_sum = map(data, ~sum(.$KB))) %>%
  unnest(id_sum) %>% 
  left_join(., sportsmen_control_polish, by = c("FID" ="sample")) %>%
  {ggboxplot(., x = "group", y = "id_sum",
             color = "group",
             add = "jitter") + 
      guides(color = guide_legend(nrow = 2)) + 
      theme(legend.title=element_blank(),
            legend.position = "none") + 
      scale_color_manual(values = group_colors) + 
      stat_compare_means(method = "t.test", comparisons = my_comparisons, label.y = c(50000, 75000))} -> sum_box
      
sum_hist + sum_box +
  plot_annotation("Sum of homozygous regions per sample") +
  plot_layout(guides = "collect") -> sum


#################################
# sum homozygosity for PHOM = 1 #
#################################
homozygosity_results_05 %>%
  filter(PHOM == 1) %>%
  group_by(FID) %>%
  nest() %>%
  mutate(id_sum_phom1 = map(data, ~sum(.$KB))) %>%
  unnest(id_sum_phom1) %>% 
  left_join(., sportsmen_control_polish, by = c("FID" ="sample")) %>%
  mutate(group = factor(group, levels = c("control", "polish_control", "sportsman"), ordered = TRUE)) %>% 
  {ggplot(., aes(x = id_sum_phom1)) +
      geom_density(aes(y=..density.., color = group)) +
      scale_fill_manual(values = group_colors) +
      scale_color_manual(values = group_colors) +
      geom_histogram(aes(y=..density.., fill = group), alpha = 0.3, position = "identity") +
      theme(legend.position = "none")} -> sum_phom_hist



homozygosity_results_05 %>%
  filter(PHOM == 1) %>%
  group_by(FID) %>%
  nest() %>%
  mutate(id_sum_phom1 = map(data, ~sum(.$KB))) %>%
  unnest(id_sum_phom1) %>% 
  left_join(., sportsmen_control_polish, by = c("FID" ="sample")) %>% 
  {ggboxplot(., x = "group", y = "id_sum_phom1",
             color = "group",
             add = "jitter") + 
      guides(color = guide_legend(nrow = 2)) + 
      theme(legend.title=element_blank(),
            legend.position = "none") +
      scale_color_manual(values = group_colors) +
      stat_compare_means(method = "t.test", comparison = list(c("control", "sportsman"), label.y = 15000, label.x = 1.2))}-> sum_phom_box 



sum_phom_hist + sum_phom_box +
  plot_annotation("Sum of homozygous regions per sample for PHOM=1") +
  plot_layout(guides = "collect") -> sum_phom


###############################
# max per sample homozygosity #
###############################
homozygosity_results_05 %>%  
  group_by(FID) %>%
  nest() %>% 
  mutate(id_max = map(data, ~max(.$KB))) %>%
  unnest(id_max) %>%  
  left_join(., sportsmen_control_polish, by = c("FID" ="sample")) %>%
  mutate(group = factor(group, levels = c("control", "polish_control", "sportsman"), ordered = TRUE)) %>% 
  {ggplot(., aes(x = id_max)) +
      scale_fill_manual(values = group_colors) +
      scale_color_manual(values = group_colors) +
      geom_histogram(aes(y=..density.., fill = group), alpha = 0.3, position = "identity") +
      geom_density(aes(y=..density.., color = group))} -> max_hist


homozygosity_results_05 %>%  
  group_by(FID) %>%
  nest() %>% 
  mutate(id_max = map(data, ~max(.$KB))) %>%
  unnest(id_max) %>%  
  left_join(., sportsmen_control_polish, by = c("FID" ="sample")) %>%
  {ggboxplot(., x = "group", y = "id_max",
             color = "group",
             add = "jitter") + 
      guides(color = guide_legend(nrow = 2)) + 
      theme(legend.title=element_blank(),
            legend.position="none") +
      scale_color_manual(values = group_colors) + 
      stat_compare_means(method = "t.test", comparisons = my_comparisons, label.y = c(10000, 12000))} -> max_box 


max_hist + max_box +
  plot_annotation("Max of homozygous regions per sample") +
  plot_layout(guides = "collect") -> max


#############################
# sum per sample, Kb > 1000 #
#############################
homozygosity_results_05 %>%
  filter(KB > 1000) %>%
  group_by(FID) %>%
  nest() %>%
  mutate(id_sum_1000kb = map(data, ~sum(.$KB))) %>%
  unnest(id_sum_1000kb) %>% 
  left_join(., sportsmen_control_polish, by = c("FID" ="sample")) %>%
  {ggplot(., aes(x = id_sum_1000kb)) +
      scale_fill_manual(values = group_colors) +
      scale_color_manual(values = group_colors) +
      geom_histogram(aes(y=..density.., fill = group), alpha = 0.3, position = "identity") +
      geom_density(aes(y=..density.., color = group))} -> sum_1000kb_hist
 

homozygosity_results_05 %>%
  filter(KB > 1000) %>%
  group_by(FID) %>%
  nest() %>%
  mutate(id_sum_1000kb = map(data, ~sum(.$KB))) %>%
  unnest(id_sum_1000kb) %>% 
  left_join(., sportsmen_control_polish, by = c("FID" ="sample")) %>%
  {ggboxplot(., x = "group", y = "id_sum_1000kb",
             color = "group",
             add = "jitter") + 
      guides(color = guide_legend(nrow = 2)) + 
      theme(legend.title=element_blank(),
            legend.position="none") +
      scale_color_manual(values = group_colors) +
      stat_compare_means(method = "t.test", comparison = list(c("control", "sportsman"), label.y = 60000, label.x = 1.2))} -> sum_1000kb_box 

sum_1000kb_hist + sum_1000kb_box +
  plot_annotation("Sum of homozygous regions per sample for region > 1000kb") +
  plot_layout(guides = "collect") -> sum_1000kb


############################
# sum per sample, Kb > 500 #
############################
homozygosity_results_05 %>%
filter(KB > 500) %>%
group_by(FID) %>%
nest() %>%
mutate(id_sum_500kb = map(data, ~sum(.$KB))) %>%
unnest(id_sum_500kb) %>%
as.data.frame() %>% 
left_join(., sportsmen_control_polish, by = c("FID" ="sample")) %>%
{ggplot(., aes(x = id_sum_500kb)) +
    scale_fill_manual(values = group_colors) +
    scale_color_manual(values = group_colors) +
    geom_histogram(aes(y=..density.., fill = group), alpha = 0.3, position = "identity") +
    geom_density(aes(y=..density.., color = group))} -> sum_500kb_hist


homozygosity_results_05 %>%
  filter(KB > 500) %>%
  group_by(FID) %>%
  nest() %>%
  mutate(id_sum_500kb = map(data, ~sum(.$KB))) %>%
  unnest(id_sum_500kb) %>%
  as.data.frame() %>% 
  left_join(., sportsmen_control_polish, by = c("FID" ="sample")) %>%
  {ggboxplot(., x = "group", y = "id_sum_500kb",
             color = "group",
             add = "jitter") + 
      guides(color = guide_legend(nrow = 2)) + 
      theme(legend.title=element_blank(), 
            legend.position = "none") +
      scale_color_manual(values = group_colors) +
      stat_compare_means(method = "t.test", comparison = list(c("control", "sportsman"), label.y = 80000, label.x = 1.2))} -> sum_500kb_box

sum_500kb_hist + sum_500kb_box +
  plot_annotation("Sum of homozygous regions per sample for region > 500kb") +
  plot_layout(guides = "collect") -> sum_500kb


############################################################
# sum per chromosome and max chrom homozygosity per sample #
############################################################
homozygosity_results_05 %>%
  group_by(FID, CHR) %>%
  nest() %>%
  mutate(id_chr_sum = map(data, ~sum(.$KB))) %>%
  unnest(data, id_chr_sum) %>%
  ungroup() %>% 
  as.data.frame() %>% 
  group_by(FID) %>%
  nest() %>%
  mutate(id_chr_max = map(data, ~max(.$id_chr_sum))) %>%
  unnest(id_chr_max) %>%
  left_join(., sportsmen_control_polish, by = c("FID" ="sample")) %>%
  {ggplot(., aes(x = id_chr_max)) + 
      scale_fill_manual(values = group_colors) +
      scale_color_manual(values = group_colors) +
      geom_histogram(aes(y=..density.., fill = group), alpha = 0.3, position = "identity") +
      geom_density(aes(y=..density.., color = group))} -> max_sum_chr_hist


homozygosity_results_05 %>%
  group_by(FID, CHR) %>%
  nest() %>%
  mutate(id_chr_sum = map(data, ~sum(.$KB))) %>%
  unnest(data, id_chr_sum) %>%
  ungroup() %>% 
  as.data.frame() %>% 
  group_by(FID) %>%
  nest() %>%
  mutate(id_chr_max = map(data, ~max(.$id_chr_sum))) %>%
  unnest(id_chr_max) %>%
  left_join(., sportsmen_control_polish, by = c("FID" ="sample")) %>%
  {ggboxplot(., x = "group", y = "id_chr_max",
             color = "group",
             add = "jitter") + 
      guides(color = guide_legend(nrow = 2)) + 
      theme(legend.title=element_blank(),
            legend.position = "none") +
      scale_color_manual(values = group_colors) +
      stat_compare_means(method = "t.test", comparison = list(c("control", "sportsman"), label.y = 40000, label.x = 1.2))} -> max_sum_chr_box

max_sum_chr_hist+ max_sum_chr_box +
  plot_annotation("Sum per chromosome and max chrom homozygosity per sample") +
  plot_layout(guides = "collect") -> max_sum_chr



sum + sum_phom + max + sum_1000kb + sum_500kb + max_sum_chr +
  plot_layout(ncol = 3, guides = "collect")


sum_hist + sum_box +   
  sum_phom_hist + sum_phom_box + 
  max_hist + max_box +
  sum_1000kb_hist + sum_1000kb_box +
  sum_500kb_hist + sum_500kb_box +
  max_sum_chr_hist + max_sum_chr_box +
  plot_layout(ncol = 4, guides = "collect") 
dev.off()

# save homozygosity plot to svg file
svglite("results/homozygosity/homozygosity-prune-50-5-0.5.svg", width = 16, height = 10)
sum_hist + sum_box +   
  max_hist + max_box +
  plot_layout(ncol = 2, guides = "collect") 
dev.off()


###############################################################################

############################################
# homozygosity between speed and endurance #
############################################

my_comparisons <- list(c("speed", "endurance"))


homozygosity_results_05 %>%  
  group_by(FID) %>%
  nest() %>% 
  mutate(id_sum = map(data, ~sum(.$KB))) %>%
  unnest(id_sum) %>% 
  left_join(., sportsmen_control_polish, by = c("FID" ="sample")) %>%  
  filter(group == "sportsman") %>% 
  {ggplot(., aes(x = id_sum)) +
      geom_histogram(aes(y=..density.., fill = pop), alpha = 0.3, position = "identity") +
      geom_density(aes(y=..density.., color = pop)) +
      theme(legend.position = "none")} -> sum_hist

homozygosity_results_05 %>%
  group_by(FID) %>%
  nest() %>% 
  mutate(id_sum = map(data, ~sum(.$KB))) %>%
  unnest(id_sum) %>% 
  left_join(., sportsmen_control_polish, by = c("FID" ="sample")) %>% 
  filter(group == "sportsman") %>% 
  {ggboxplot(., x = "pop", y = "id_sum",
             color = "pop",
             add = "jitter") + 
      guides(color = guide_legend(nrow = 2)) + 
      theme(legend.title=element_blank(),
            legend.position = "none") + 
      stat_compare_means(method = "t.test", comparisons = my_comparisons, label.y = 25000)} -> sum_box


#################################
# sum homozygosity for PHOM = 1 #
#################################
homozygosity_results_05 %>%
  filter(PHOM == 1) %>%
  group_by(FID) %>%
  nest() %>%
  mutate(id_sum_phom1 = map(data, ~sum(.$KB))) %>%
  unnest(id_sum_phom1) %>% 
  left_join(., sportsmen_control_polish, by = c("FID" ="sample")) %>% 
  mutate(group = factor(group, levels = c("control", "polish_control", "sportsman"), ordered = TRUE)) %>% 
  filter(group == "sportsman") %>% 
  {ggplot(., aes(x = id_sum_phom1)) +
      geom_density(aes(y=..density.., color = pop)) +
      geom_histogram(aes(y=..density.., fill = pop), alpha = 0.3, position = "identity") +
      theme(legend.position = "none")} -> sum_phom_hist


homozygosity_results_05 %>%
  filter(PHOM == 1) %>%
  group_by(FID) %>%
  nest() %>%
  mutate(id_sum_phom1 = map(data, ~sum(.$KB))) %>%
  unnest(id_sum_phom1) %>% 
  left_join(., sportsmen_control_polish, by = c("FID" ="sample")) %>% 
  filter(group == "sportsman") %>% 
  {ggboxplot(., x = "pop", y = "id_sum_phom1",
             color = "pop",
             add = "jitter") + 
      guides(color = guide_legend(nrow = 2)) + 
      theme(legend.title=element_blank(),
            legend.position = "none") +
      stat_compare_means(method = "t.test", comparison = my_comparisons, label.y = 15000, label.x = 1.2)} -> sum_phom_box 


sum_phom_hist + sum_phom_box +
  plot_annotation("Sum of homozygous regions per sample for PHOM=1") +
  plot_layout(guides = "collect") -> sum_phom

###############################
# max per sample homozygosity #
###############################
homozygosity_results_05 %>%  
  group_by(FID) %>%
  nest() %>% 
  mutate(id_max = map(data, ~max(.$KB))) %>%
  unnest(id_max) %>%  
  left_join(., sportsmen_control_polish, by = c("FID" ="sample")) %>%
  mutate(group = factor(group, levels = c("control", "polish_control", "sportsman"), ordered = TRUE)) %>% 
  filter(group == "sportsman") %>% 
  {ggplot(., aes(x = id_max)) +
      geom_histogram(aes(y=..density.., fill = pop), alpha = 0.3, position = "identity") +
      geom_density(aes(y=..density.., color = pop))} -> max_hist


homozygosity_results_05 %>%  
  group_by(FID) %>%
  nest() %>% 
  mutate(id_max = map(data, ~max(.$KB))) %>%
  unnest(id_max) %>%  
  left_join(., sportsmen_control_polish, by = c("FID" ="sample")) %>%
  filter(group == "sportsman") %>% 
  {ggboxplot(., x = "pop", y = "id_max",
             color = "pop",
             add = "jitter") + 
      guides(color = guide_legend(nrow = 2)) + 
      theme(legend.title=element_blank(),
            legend.position="none") +
      stat_compare_means(method = "t.test", comparisons = my_comparisons, label.y = c(10000, 12000))} -> max_box 


max_hist + max_box +
  plot_annotation("Max of homozygous regions per sample") +
  plot_layout(guides = "collect") -> max


#############################
# sum per sample, Kb > 1000 #
#############################
homozygosity_results_05 %>%
  filter(KB > 1000) %>%
  group_by(FID) %>%
  nest() %>%
  mutate(id_sum_1000kb = map(data, ~sum(.$KB))) %>%
  unnest(id_sum_1000kb) %>% 
  left_join(., sportsmen_control_polish, by = c("FID" ="sample")) %>%
  filter(group == "sportsman") %>% 
  {ggplot(., aes(x = id_sum_1000kb)) +
      geom_histogram(aes(y=..density.., fill = pop), alpha = 0.3, position = "identity") +
      geom_density(aes(y=..density.., color = pop))} -> sum_1000kb_hist


homozygosity_results_05 %>%
  filter(KB > 1000) %>%
  group_by(FID) %>%
  nest() %>%
  mutate(id_sum_1000kb = map(data, ~sum(.$KB))) %>%
  unnest(id_sum_1000kb) %>% 
  left_join(., sportsmen_control_polish, by = c("FID" ="sample")) %>%
  filter(group == "sportsman") %>% 
  {ggboxplot(., x = "pop", y = "id_sum_1000kb",
             color = "pop",
             add = "jitter") + 
      guides(color = guide_legend(nrow = 2)) + 
      theme(legend.title=element_blank(),
            legend.position="none") +
      stat_compare_means(method = "t.test", comparison = my_comparisons, label.y = 20000, label.x = 1.2)} -> sum_1000kb_box 

sum_1000kb_hist + sum_1000kb_box +
  plot_annotation("Sum of homozygous regions per sample for region > 1000kb") +
  plot_layout(guides = "collect") -> sum_1000kb


############################
# sum per sample, Kb > 500 #
############################
homozygosity_results_05 %>%
  filter(KB > 500) %>%
  group_by(FID) %>%
  nest() %>%
  mutate(id_sum_500kb = map(data, ~sum(.$KB))) %>%
  unnest(id_sum_500kb) %>%
  as.data.frame() %>% 
  left_join(., sportsmen_control_polish, by = c("FID" ="sample")) %>%
  filter(group == "sportsman") %>% 
  {ggplot(., aes(x = id_sum_500kb)) +
      geom_histogram(aes(y=..density.., fill = pop), alpha = 0.3, position = "identity") +
      geom_density(aes(y=..density.., color = pop))} -> sum_500kb_hist


homozygosity_results_05 %>%
  filter(KB > 500) %>%
  group_by(FID) %>%
  nest() %>%
  mutate(id_sum_500kb = map(data, ~sum(.$KB))) %>%
  unnest(id_sum_500kb) %>%
  as.data.frame() %>% 
  left_join(., sportsmen_control_polish, by = c("FID" ="sample")) %>%
  filter(group == "sportsman") %>% 
  {ggboxplot(., x = "pop", y = "id_sum_500kb",
             color = "pop",
             add = "jitter") + 
      guides(color = guide_legend(nrow = 2)) + 
      theme(legend.title=element_blank(), 
            legend.position = "none") +
      stat_compare_means(method = "t.test", comparison = my_comparisons, label.y = 25000, label.x = 1.2)} -> sum_500kb_box

sum_500kb_hist + sum_500kb_box +
  plot_annotation("Sum of homozygous regions per sample for region > 500kb") +
  plot_layout(guides = "collect") -> sum_500kb

############################################################
# sum per chromosome and max chrom homozygosity per sample #
############################################################
homozygosity_results_05 %>%
  group_by(FID, CHR) %>%
  nest() %>%
  mutate(id_chr_sum = map(data, ~sum(.$KB))) %>%
  unnest(data, id_chr_sum) %>%
  ungroup() %>% 
  as.data.frame() %>% 
  group_by(FID) %>%
  nest() %>%
  mutate(id_chr_max = map(data, ~max(.$id_chr_sum))) %>%
  unnest(id_chr_max) %>%
  left_join(., sportsmen_control_polish, by = c("FID" ="sample")) %>%
  filter(group == "sportsman") %>% 
  {ggplot(., aes(x = id_chr_max)) + 
      geom_histogram(aes(y=..density.., fill = pop), alpha = 0.3, position = "identity") +
      geom_density(aes(y=..density.., color = pop))} -> max_sum_chr_hist


homozygosity_results_05 %>%
  group_by(FID, CHR) %>%
  nest() %>%
  mutate(id_chr_sum = map(data, ~sum(.$KB))) %>%
  unnest(data, id_chr_sum) %>%
  ungroup() %>% 
  as.data.frame() %>% 
  group_by(FID) %>%
  nest() %>%
  mutate(id_chr_max = map(data, ~max(.$id_chr_sum))) %>%
  unnest(id_chr_max) %>%
  left_join(., sportsmen_control_polish, by = c("FID" ="sample")) %>%
  filter(group == "sportsman") %>% 
  {ggboxplot(., x = "pop", y = "id_chr_max",
             color = "pop",
             add = "jitter") + 
      guides(color = guide_legend(nrow = 2)) + 
      theme(legend.title=element_blank(),
            legend.position = "none") +
      stat_compare_means(method = "t.test", comparison = my_comparisons, label.y = 15000, label.x = 1.2)} -> max_sum_chr_box

max_sum_chr_hist+ max_sum_chr_box +
  plot_annotation("Sum per chromosome and max chrom homozygosity per sample") +
  plot_layout(guides = "collect") -> max_sum_chr


sum + sum_phom + max + sum_1000kb + sum_500kb + max_sum_chr +
  plot_layout(ncol = 3, guides = "collect")

sum_hist + 
  theme(axis.text = element_text(size=12),
       axis.title=element_text(size = 14))

dev.off()
svglite("results/homozygosity/homozygosity-endurance-speed-prune-50-5-0.5.svg", width = 16, height = 10)
sum_hist + sum_box +   
  sum_phom_hist + sum_phom_box + 
  max_hist + max_box +
  sum_1000kb_hist + sum_1000kb_box +
  sum_500kb_hist + sum_500kb_box +
  max_sum_chr_hist + max_sum_chr_box +
  plot_layout(ncol = 4, guides = "collect") 
dev.off()

rm(sum, sum_phom, max, sum_1000kb, sum_500kb, max_sum_chr, sum_hist, sum_box,    
       sum_phom_hist, sum_phom_box,  
       max_hist, max_box, 
       sum_1000kb_hist, sum_1000kb_box, 
       sum_500kb_hist, sum_500kb_box, 
       max_sum_chr_hist, max_sum_chr_box)

