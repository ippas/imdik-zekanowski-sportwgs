

#################
# read vcf file #
#################
vcf <- read.vcfR("data/prs-data/dimensionality-data/sportsmen-id-signif-models.vcf.gz", convertNA = T)

# vcf <- read.vcfR("data/prs-data/dimensionality-data/sportsmen-id-impact-0.25.vcf.gz", convertNA = T)

snps_num <- extract.gt(vcf,
                       element = "GT",
                       IDtoRowNames = T,
                       as.numeric = F,
                       convertNA = T, 
                       return.alleles = F)

name_col <- colnames(snps_num)
name_row <- rownames(snps_num)

#######################
# prepare data to pca #
#######################
# recode genotype to number
snps_num %>% 
  apply(., 1, function(x){str_replace(x, "/", "|")}) %>% t %>% 
  apply(., 1, function(x){recode(x, 
                                 "1|1" = 2, "0|1" = 1,  "0|0" = 0, "1|2" = 2, "2|2" = 2, "1|3" = 2, "0|2" = 1, 
                                 "1|4" = 2, "2|1" = 2,  "1|5" = 2, "2|4" = 2, "2|5" = 2, "1|6" = 2, "1|7" = 2, "2|3" = 2, 
                                 "2|8" = 2, "2|6" = 2,  "2|7" = 2, "0|5" = 1, "4|2" = 2, "1|8" = 2) }) %>% t -> snps_num

colnames(snps_num) <- name_col
rownames(snps_num) <- name_row

snps_num_t <- t(snps_num)

snps_num_df <- data.frame(snps_num_t) 

# function find all NA in data frame and tell where they are NA places
find_NAs <- function(x){
  NAs_TF <- is.na(x)
  i_NA <- which(NAs_TF == TRUE)
  N_NA <- length(i_NA)
  
  cat("Results:",N_NA, "NAs present\n.")
  return(i_NA)
}

# N_rows
# number of rows (individuals)
N_rows <- nrow(snps_num_t)

# N_NA
# vector to hold output (number of NAs)
N_NA   <- rep(x = 0, times = N_rows)

# N_SNPs
# total number of columns (SNPs)
N_SNPs <- ncol(snps_num_t)

# the for() loop
for(i in 1:N_rows){
  
  # for each row, find the location of
  ## NAs with snps_num_t()
  i_NA <- find_NAs(snps_num_t[i,]) 
  
  # then determine how many NAs
  ## with length()
  N_NA_i <- length(i_NA)
  
  # then save the output to 
  ## our storage vector
  N_NA[i] <- N_NA_i
}

cutoff50 <- N_SNPs*0.5

percent_NA <- N_NA/N_SNPs*100

# Call which() on percent_NA
i_NA_50percent <- which(percent_NA > 50) 


snps_num_t02 <- snps_num_t[-i_NA_50percent, ]

# function to delate columns with the same value
invar_omit <- function(x){
  cat("Dataframe of dim",dim(x), "processed...\n")
  sds <- apply(x, 2, sd, na.rm = TRUE)
  i_var0 <- which(sds == 0)
  
  
  cat(length(i_var0),"columns removed\n")
  
  if(length(i_var0) > 0){
    x <- x[, -i_var0]
  }
  
  ## add return()  with x in it
  return(x)                      
}

# removed column with the same value
snps_no_invar <- invar_omit(snps_num_t) 

snps_noNAs <- snps_no_invar

N_col <- ncol(snps_no_invar)
for(i in 1:N_col){
  
  # get the current column
  column_i <- snps_noNAs[, i]
  
  # get the mean of the current column
  mean_i <- mean(column_i, na.rm = TRUE)
  
  # get the NAs in the current column
  NAs_i <- which(is.na(column_i))
  
  # record the number of NAs
  N_NAs <- length(NAs_i)
  
  # replace the NAs in the current column
  column_i[NAs_i] <- mean_i
  
  # replace the original column with the
  ## updated columns
  snps_noNAs[, i] <- column_i
  
}

#######################################
# claculate pca and visualize results #
#######################################
require(vegan)


SNPs_cleaned <- snps_noNAs

# execute pca
pca_scaled <- prcomp(SNPs_cleaned, scale. = T, center = T)

# create screeplot
screeplot(pca_scaled, 
          ylab  = "Relative importance",
          main = "give me a basic title")


# create plot for first five PC
pca_scaled$x %>% 
  as.data.frame() %>% 
  rownames_to_column(var = "sample") %>% 
  left_join(dim_prs$df_metadata_sportsmen, ., by = "sample")  %>% 
  ggpairs(
    .,
    columns = c(9:13),
    aes(colour = pop),
    progress = FALSE,
    upper = list(continuous = "density", combo = "facetdensity"),
    lower = list(combo = "facetdensity"),
    diag = list(continuous = "blank")
  ) -> pca_variants_plot

# calculate statistics for PC
pca_scaled$x %>%
  as.data.frame() %>%
  rownames_to_column(var = "sample") %>%
  left_join(test_dimensionality_class$df_metadata_sportsmen, ., by = "sample")  %>%
  gather("PC", "value", -c(sample, pop, super_pop, gender, group, sport, age, n)) %>%
  group_by(PC) %>%
  nest() %>%
  mutate(t.test = map(data, ~t.test(.x[.$pop == "endurance",]$value,
                                    .x[.$pop == "speed",]$value,
                                    var.equal = TRUE)[[3]])) %>%
  unnest(t.test) %>%
  select(-data) %>% 
  as.data.frame() -> pca_variants_stat

##########################
# save results to report #
##########################
output_file <- paste0(getwd(), "/analysis/reports-prs/report-dimensional-analysis.html")

rmarkdown::render(input = "preprocessing/prs-preprocessing/r-analysis/dimensionality-analysis/report-dimensional-analysis.Rmd", 
                  output_file = output_file,
                  params = list(dim_class = dim_prs,
                                pca_variants_plot = pca_variants_plot,
                                pca_variants_stat = pca_variants_stat))

 
# pca_scaled$x %>%
#   as.data.frame() %>%
#   rownames_to_column(var = "sample") %>%
#   left_join(test_dimensionality_class$df_metadata_sportsmen, ., by = "sample")  %>%
#   .[, c("sample", "pop", "super_pop", "gender", "group", "sport", "age", "n", signif_pc)] %>%
#   ggpairs(
#     .,
#     columns = c(9:13),
#     aes(colour = pop),
#     progress = FALSE,
#     upper = list(continuous = "density", combo = "facetdensity"),
#     lower = list(combo = "facetdensity"),
#     diag = list(continuous = "blank")
#   ) 


