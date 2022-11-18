#############################################################
## Stuff I have to do
## mateuszzieba97@gmail.com - Apr 2022
#############################################################
# This code is available for load packages and 
# prepare function to analysis results of prs

# prepare function to install and load package
install_load <- function (vector)  {   
  
  # convert arguments to vector
  packages <- vector
  
  # start loop to determine if each package is installed
  for(package in packages){
    
    # if package is installed locally, load
    if(package %in% rownames(installed.packages()))
      do.call('library', list(package))
    
    # if package is not installed locally, download, then load
    else {
      install.packages(package)
      do.call("library", list(package))
    }
  } 
}

# list of needed packages
list_of_packages <- c(
  "XML",
  "rvest",
  "purrr",
  "xml2",
  "dplyr",
  "stringr",
  "tidyr",
  "magrittr",
  "stringi",
  "rlang",
  "patchwork",
  "RColorBrewer",
  "strex",
  "stats",
  "pryr",
  "ggplot2",
  "tidyverse",
  "cape",
  # "dartR",
  "rmarkdown",
  "svglite",
  "tibble",
  "ggpubr"
)

install_load(list_of_packages)

# # install pacman package and load needed packages
# if (!require("pacman")) install.packages("pacman")
# pacman::p_load(list_of_packages)

########################################################################
# functions to get information from https://biobank.ndph.ox.ac.uk/ukb/ #
########################################################################

## function to get available category fields from biobank
get_type_field_biobank <- function() {
  field_listing <- read_html("https://biobank.ndph.ox.ac.uk/showcase/list.cgi")
  
  field_listing %>% 
    xml_find_all('.//div[@class = "tabbertab"][position() = 1]/ul/li[@class = "plain"]/a[@class = "basic"]') %>%
    html_text()-> link_category
  
  return(link_category)
}

# get_type_field_biobank()

## function to get data fields from biobank 
get_field_biobank <-
  function(category_field = c(
    "Integer",
    "Categorical (single)",
    "Categorical (multiple)",
    "Continuous",
    "Text",
    "Date",
    "Time",
    "Compound"
  )) {
    
    field_listing <- read_html("https://biobank.ndph.ox.ac.uk/showcase/list.cgi")
    
    field_listing %>%
      xml_find_all(
        './/div[@class = "tabbertab"][position() = 1]/ul/li[@class = "plain"]/a[@class = "basic"]'
      ) %>%
      html_attr("href") %>%
      paste("https://biobank.ndph.ox.ac.uk/showcase/", ., sep = "") -> link_category
    
    field_listing %>%
      xml_find_all(
        './/div[@class = "tabbertab"][position() = 1]/ul/li[@class = "plain"]/a[@class = "basic"]'
      ) %>%
      html_text() -> text_category
    
    category_df <- data.frame(link_category, text_category) %>%
      filter(text_category %in% category_field)
    
    category_df %>%
      .[, 1] %>%
      sapply(., function(x) {
        read_html(x) %>%
          xml_find_all('.//div[@class = "tabbertab"]/table') %>%
          html_table() %>%
          as.data.frame() %>%
          .[, 1]
      }) %>%
      unname() %>%
      unlist() %>%
      as.vector()
  }


# get_field_biobank()


## function to get data about field from biobank
data_field_biobank <- function(data_field) {
  
  not_all_na <- function(x) any(!is.na(x))
  
  data_field_list <- list()
  url_data_field <-
    paste("https://biobank.ndph.ox.ac.uk/showcase/field.cgi?id=",
          data_field,
          sep = "")
  
  html_data_field <- read_html(url_data_field)
  
  data_field_list$data_field <- data_field
  
  data_field_list$url_biobank <- url_data_field
  
  data_field_list$identification <- html_data_field %>% 
    html_elements(xpath = '//table[@summary = "Identification"]') %>% 
    html_table() %>%
    as.data.frame() %>% 
    set_colnames(c("type", "value")) %>%
    mutate(type = gsub("\\:", "", type))
  
  data_field_list$summary <-  html_data_field %>%
    html_elements(xpath = '//table[@summary = "Field properties"]') %>%
    html_table() %>%
    as.data.frame() %>%
    select(where(not_all_na)) %>%
    unname() %>%
    t() %>%
    matrix(byrow = T, 12, 2) %>%
    as.data.frame() %>%
    set_colnames(c("type", "value"))
  
  data_field_list$data <- html_data_field %>%
    xml_find_all('.//ul[@class = "tree"]') %>%
    xml_find_all(".//*") %>%
    xml_find_all('.//li/*[@class = "tree_desc" or @class = "tree_leaf tree_desc"]') %>% html_text() %>%
    as.data.frame() %>%
    set_colnames("category") %>%  {
      if (nrow(.) == 0)
        data.frame(category = as.character(data_field))
      else
        .
    }
  
  data_field_list$notes <- html_data_field %>%
    html_elements(xpath = './/div/div/div[@class = "tabbertab"]/h2[text() = "Notes"]')  %>%
    html_elements(xpath = '..') %>%
    html_text()
  
  data_field_list$categories <- html_data_field %>%
    html_elements(xpath = '//table[@class = "listing" and @summary = "List of categories"]') %>%
    html_table() %>%
    as.data.frame()
  
  return(data_field_list)
}

# data_field_biobank(data_field = 41270) 


## function to get data about field from biobank
get_category_biobank <- function(category_listing){
  
  get_category_table_biobank <- function(url){
    read_html(url) %>%
      html_elements(xpath = './/table[@summary = "List of data-fields"]') %>%
      html_table() %>% as.data.frame() %>% 
      .[, 1:2] %>% select(Field.ID) -> category_field_table
    
    return(category_field_table)
  }
  
  
  category_url <- read_html("https://biobank.ndph.ox.ac.uk/showcase/cats.cgi") %>%
    html_elements(xpath = paste0('.//div[@class = "tabbertab"]/h2[text() = "', category_listing , '"]')) %>% 
    html_elements(xpath = '..') %>%
    html_elements(xpath = './/table/tr/td[@class = "txt"]/a[@class = "alabel"]') %>%
    html_attr("href") %>% paste0("https://biobank.ndph.ox.ac.uk/showcase/", .)  
  
  category_table <- read_html("https://biobank.ndph.ox.ac.uk/showcase/cats.cgi") %>%
    html_elements(xpath = paste0('.//div[@class = "tabbertab"]/h2[text() = "', category_listing , '"]')) %>% 
    html_elements(xpath = '..') %>%
    html_elements(xpath = './/table') %>%
    html_table() %>% 
    as.data.frame() %>%
    mutate(url = category_url) %>%
    group_by(Category.ID) %>%
    mutate(fields_category = map(url, ~get_category_table_biobank(.x))) 
  
  
  return(category_table)
}

##################################
# function to preprocessing data #
##################################

## fucntion to preprocessing results fo statitics
prs_statistic_preprocessing <- function(statistics_prs) {
  statistics_prs %>% 
    select(-data) %>%
    as.data.frame() %>%
    mutate(model = as.character(model)) %>%
    mutate(code = {
      str_split_fixed(model, "-", n = 3)[, 2]
    }) %>%
    mutate(phenocode_description = {
      str_split_fixed(model, "-", n = 6)[, 5] %>% str_replace_all(., "_", " ")
    }) %>%
    mutate(code_dod = str_replace_all(code, "_", ".")) %>%
    left_join(., icd10[, c("icd", "icd_category", "field")], by = c("code_dod" = "icd")) %>%
    left_join(., icd10[, c("icd_category", "phecode", "field")], by = c("code_dod" = "phecode")) %>%
    mutate(icd10_category = ifelse(!is.na(icd_category.x), icd_category.x, icd_category.y)) %>%
    mutate(icd10_field = ifelse(!is.na(field.x), field.x, field.y)) %>%
    select(-c(icd_category.x, icd_category.y, field.x, field.y)) %>% # remove temporary column during merging icd10
    left_join(., icd9[, c("icd", "icd_category", "field")], by = c("code_dod" = "icd")) %>%
    left_join(., icd9[, c("icd_category", "phecode", "field")], by = c("code_dod" = "phecode")) %>%
    mutate(icd9_category = ifelse(!is.na(icd_category.x), icd_category.x, icd_category.y)) %>%
    mutate(icd9_field = ifelse(!is.na(field.x), field.x, field.y)) %>%
    select(-c(icd_category.x, icd_category.y, field.x, field.y)) %>% # remove temporary column during merging icd9
    mutate(icd_category = ifelse(!is.na(icd10_category), icd10_category, icd9_category) %>% tolower()) %>%
    mutate(icd_field = ifelse(!is.na(icd10_category), icd10_field, icd9_field)) %>%
    select(-c(icd9_category, icd10_category, icd9_field, icd10_field)) %>%
    left_join(., phenocode_data_preprocessing, by = c("code" = "phenocode")) %>%
    mutate(description = str_trim(phenocode_description)) %>%
    mutate(field = ifelse(
      !is.na(icd_field),
      icd_field,
      ifelse(!is.na(resource_field),
             resource_field, code)
    ))  %>%
    select(-c(code, description, code_dod, icd_category, icd_field, trait_type, resource_field)) %>%
    unique() -> statistics_results_preprocessing
  
  return(statistics_results_preprocessing)
  
}

## function which add biobank information about models
add_biobank_info <- function(results_preprocessing) {
  # download type of categories
  type_categories_biobank <- read_html("https://biobank.ndph.ox.ac.uk/showcase/cats.cgi") %>%
    html_elements(xpath = paste0('.//div[@class = "tabbertab"]')) %>% 
    html_elements(xpath = ".//h2") %>% 
    html_text() %>%
    str_replace_all(' ', '_')
  
  
  # prepare data frame with type categories
  read_html("https://biobank.ndph.ox.ac.uk/showcase/cats.cgi") %>%
    html_elements(xpath = paste0('.//div[@class = "tabbertab"]')) %>%
    # html_elements(xpath = ".//table") %>% html_table() 
    lapply(., function(x) {
      x %>%
        html_elements(xpath = ".//table") %>%
        html_table() %>% 
        as.data.frame()
    }) %>% 
    set_names(type_categories_biobank) %>%
    plyr::ldply(.id = "type_category") %>% 
    select(-Items) %>%
    set_colnames(c("type_category", "category_id", "category_description")) -> type_categories_df_biobank
  
  results_preprocessing %>%
    left_join({
      field_category_preprocessing[, c("category_id", "field_id")] %>% unique()
    }, by = c("field" = "field_id")) %>%
    left_join({
      field_category_preprocessing[, c("category_id", "category")] %>% unique()
    }, by = c("phenocode_description" = "category")) %>%
    mutate(category_id = ifelse(!is.na(category_id.x), category_id.x, category_id.y)) %>%
    select(-c(category_id.x, category_id.y)) %>%
    unique() %>%
    left_join(., type_categories_df_biobank, by = "category_id") -> results_biobank_category
  
  return(results_biobank_category)
  
}


## function to add info about number of cases EUR and filter by threshold
filter_n_cases <- function(results_biobank_category,
                                  n_cases_EUR = 2000) {
  
  options(dplyr.summarise.inform = FALSE)
  
  results_biobank_category %>%
    # prepare model_sign column to merge with phenocode data with number of EUR cases
    mutate(model_sign = {
      str_before_nth(as.character(.$model), "-", 4) %>% str_after_first(., "-") %>% tolower() %>% str_replace_all("-", " ") %>% str_squish() %>% str_replace_all(" ", "_")
    }) %>%
    # add column with number of EUR cases
    left_join(., {
      phenocode_data %>% select(c(model_sign, n_cases_EUR)) %>%
        mutate(model_sign = {
          tolower(model_sign) %>% str_replace_all("[[:punct:]]", " ") %>%
            str_replace_all(., "[[|]]", " ") %>%
            str_squish() %>%
            str_trim() %>%
            str_replace_all(., " ", "_")
        })
    }, by = "model_sign") %>%
    # filter by EUR cases
    filter(n_cases_EUR > {{n_cases_EUR}} |
             is.na(n_cases_EUR)) %>%
    select(-model_sign) %>%
    group_by(across(c(-n_cases_EUR))) %>% 
    summarise(n_cases_EUR = max(n_cases_EUR)) %>% 
    as.data.frame() -> filter_cases
  
  options(dplyr.summarise.inform = TRUE)
  
  return(filter_cases)
  
}


## function to add samples results
add_samples_results <- function(data,
                                prs_samples_results) {
  prs_samples_results %>%
    mutate(p.value_variants = as.character(p.value_variants)) %>%
    inner_join({
      data %>% mutate(p.value_variants = as.character(p.value_variants))
    }, by = c("model", "p.value_variants")) -> merge_data
  
  return(merge_data)
}


######################################
# functions to prepare visualization #
######################################
## function to prepare text for histogram
graph_labels <- function(data_frame, columns_name, prefix = "p", digits = 5) {
  data_frame %>%
    select(columns_name) %>% 
    unique() %>%
    mutate(t_test = paste0(prefix, " = ", round(get(columns_name[2]), digits = digits)))
}

## function to create plot for prs results
plot_prs <-
  function(data,
           prs_score,
           fill,
           color,
           title = "",
           graphLabels,
           size = 14,
           ncol = 3,
           palette,
           histogram,
           bins = 30) {
    
    data %>%
      ggplot(aes(x = {
        {
          prs_score
        }
      })) +
      geom_histogram(
        data = . %>% filter(group %in% c(histogram)),
        aes(y = ..density.., fill = {
          {
            fill
          }
        }),
        position = "identity",
        alpha = 0.4,
        bins = bins
      ) +
      geom_density(aes(y = ..density.., color = {
        {
          color
        }
      })) +
      scale_color_manual(values = {{palette}}) +
      scale_fill_manual(values = {{palette}}) +
      facet_wrap(
        model ~ .,
        scales = "free",
        ncol = ncol,
        drop = F,
        labeller = labeller(model = tidy_phenotypes(data$model))
      ) +
      theme(
        legend.position = "bottom",
        axis.title = element_text(size = size),
        legend.text = element_text(size = size),
        strip.text = element_text(size = size),
        title = element_text(size = size),
        axis.text = element_text(size = size / 1.5)
      ) +
      labs(
        x = "prs score",
        y = "density",
        fill = "",
        color = "",
        title = title
      ) +
      geom_text(
        data = graphLabels,
        aes(label = t_test, x = prs_midle, y = Inf),
        vjust = 2,
        hjust  = "midle",
        size = size / 3.5
      )
  }


## function to create boxplot 
boxplot_prs <- function(data, size = 18, stat_signif_df, levels) {
  data %>%
    ggplot(aes(x = factor(group, levels = levels), y = prs_score)) +
    geom_boxplot(aes(color = group)) +
    ggsignif::stat_signif(aes(xmin = xmin, xmax = xmax, y_position = y_position, annotations = text), data = stat_signif_df, manual = T, tip_length = 0, textsize = size/3.5) +
    scale_color_manual(values = palette_group) + 
    labs(
      x = "group",
      y = "prs score",
      fill = "",
      color = ""
    ) +
    theme(
      legend.position = "none",
      axis.title = element_text(size = size),
      plot.margin=unit(c(0,0,0,0), "cm"),
      axis.text = element_text(size = size / 1.5)
    )
}

## function to create histogram
histogram_prs <-
  function(data,
           prs_score,
           fill,
           color,
           title = "",
           graphLabels,
           size = 14,
           ncol = 3,
           palette,
           histogram,
           bins = 30) {
    
    data %>%
      ggplot(aes(x = {
        {
          prs_score
        }
      })) +
      geom_histogram(
        data = . %>% filter(group %in% c(histogram)),
        aes(y = ..density.., fill = {
          {
            fill
          }
        }),
        position = "identity",
        alpha = 0.4,
        bins = bins
      ) +
      geom_density(aes(y = ..density.., color = {
        {
          color
        }
      })) +
      scale_color_manual(values = {{palette}}) +
      scale_fill_manual(values = {{palette}}) +
      theme(
        legend.position = "bottom",
        axis.title = element_text(size = size),
        legend.text = element_text(size = size),
        strip.text = element_text(size = size),
        plot.margin=unit(c(0,0,0,0), "cm"),
        axis.text = element_text(size = size / 1.5)
      ) +
      labs(
        x = "prs score",
        y = "density",
        fill = "",
        color = ""
      ) +
      geom_text(
        data = graphLabels,
        aes(label = t_test, x = prs_midle, y = Inf),
        vjust = 2,
        hjust  = "midle",
        size = size / 3.5
      ) 
  }


## function to wrap text 
wrapit <- function(text, n_letters=60) {
  wtext <- paste(strwrap(text,width=n_letters),collapse=" \n ")
  return(wtext)
}

## function to prepare tidy name of phenotype
tidy_phenotypes <- function(phenotypes) {
  phenotype_names_vector <- c()
  for (phenotype in phenotypes) {
    strsplit(as.character(phenotype),
             split = "-",
             fixed = TRUE) %>%
      unlist %>% 
      {if_else(.[5] == "na", .[2], .[5])} %>%
      str_replace_all(., "_", " ") %>%
      wrapit() -> new_name
    phenotype_names_vector <- c(phenotype_names_vector, new_name)
  }
  
  names(phenotype_names_vector) <- phenotypes
  return(phenotype_names_vector)
} 

## function to prepare text for boxplot
stat_signif_create <- function(y_position, xmin = 1, xmax = 2, test_value, prefix = "p = ", digits = 5) {
  df_stat_signif <- data.frame(
    text = paste0(prefix, round(test_value, digits = digits)),
    y_position = range(y_position) %>% {max(.) - diff(. * 0.1)},
    xmin = xmin,
    xmax = xmax
  ) %>% unique()
  
  return(df_stat_signif)
  
}

## function go get legend from plot
get_legend<-function(myggplot){
  tmp <- ggplot_gtable(ggplot_build(myggplot))
  leg <- which(sapply(tmp$grobs, function(x) x$name) == "guide-box")
  legend <- tmp$grobs[[leg]]
  return(legend)
}


#############################################################
# function to calculate statistics: t.test and shapiro.test #
#############################################################
## function to calculate statistics for two groups
statistics_sportsmen_prs <- function(data, column_group, group1, group2) {
  shapiro_name1 <- paste0("shapiro.test_", group1)
  shapiro_name2 <- paste0("shapiro.test_", group2)
  
  data %>%
    group_by(model, p.value_variants) %>%
    nest() %>%
    mutate(
      t.test = map(data,
                   ~ ifelse(
                     inherits(try(t.test(.x[.[[column_group]] == group1, ]$prs_score,
                                         .x[.[[column_group]] == group2,]$prs_score,
                                         var.equal = TRUE))
                              , "try-error"),
                     1,
                     t.test(.x[.$group == group1, ]$prs_score,
                            .x[.$group == group2,]$prs_score,
                            var.equal = TRUE)[[3]]
                   )),
      "{shapiro_name1}" := map(data,  ~ ifelse(
        inherits(try(shapiro.test(.x[.[[column_group]] == group1,]$prs_score))
                 , "try-error"),
        0,
        shapiro.test(.x[.[[column_group]] == group1,]$prs_score)[[2]]
      )),
      "{shapiro_name2}" := map(data,  ~ ifelse(
        inherits(try(shapiro.test(.x[.[[column_group]] == group2,]$prs_score))
                 , "try-error"),
        0,
        shapiro.test(.x[.[[column_group]] == group2,]$prs_score)[[2]]
      )),
      prs_midle = map(data, ~ mean(range(.x$prs_score)))
    ) %>%
    unnest(-data) -> statistics_table
  
  return(statistics_table)
}


###################################
# function to create data to html #
###################################
## function to create table with summary about models
model_summary_prs <- function(data) {
  data %>%
    select(
      -c(
        sample,
        pop,
        super_pop,
        gender,
        group,
        genotyping_alleles_count,
        imputing_alleles_count,
        af_alleles_count,
        missing_alleles_count,
        prs_midle,
        type_category,
        prs_score
      )
    ) %>%
    unique() %>%
    mutate(p.value_variants = as.character(p.value_variants)) %>%
    relocate(c("phenocode_description" ,"field", "category_id", "category_description", "n_cases_EUR"),
             .after = "p.value_variants") -> stat_summary_model
  
  return(stat_summary_model)
}

## function to prepare table with numbers in each group
summary_group <- function(data) {
  data %>%
    select(c(pop, super_pop, group, category_id, category_description, prs_score)) %>%
    unique() %>%
    group_by(pop, super_pop, group, category_id, category_description) %>%
    nest() %>%
    mutate(n = map(data, ~ nrow(.x))) %>%
    unnest(n) %>%
    select(-data) %>%
    as.data.frame() -> summary_group
  
  return(summary_group)
}


## function to create df with number of sample in each group
number_group <- function(data) {
  data %>% 
    group_by(model) %>% 
    nest() %>% 
    .[1,] %>% 
    unnest(data) %>% 
    group_by(group) %>% 
    nest() %>% 
    mutate(n = map(data, ~nrow(.x))) %>% 
    unnest(n) %>% 
    select(-data) %>% 
    as.data.frame()
}




####################
# testing function #
####################
# function to get filed for category and for subcaegory
# Function not completed
get_fields_sub_category_biobank <- function(url) {
  get_category_table_biobank <- function(url) {
    read_html(url) %>%
      html_elements(xpath = './/table[@summary = "List of data-fields"]') %>%
      html_table() %>% as.data.frame() %>%
      .[, 1:2] %>% select(Field.ID) -> category_field_table
    
    return(category_field_table)
  }
  
  read_html(url) %>%
    html_elements(., xpath = './/table') %>%
    {
      if ({
        html_attr(., "summary") %>% .[1] == "List of categories"
      }) {
        html_elements(., xpath = '../table[@summary = "List of categories"]') %>% html_table() %>%
          as.data.frame() %>%
          mutate(url = paste0(
            "https://biobank.ndph.ox.ac.uk/showcase/label.cgi?id=",
            Category.ID
          )) %>%
          group_by(Category.ID) %>%
          mutate(fields_category = map(url, ~ get_category_table_biobank(.x))) %>%
          unnest(fields_category) %>%
          as.data.frame() %>%
          select(Field.ID)
      } else {
        html_elements(., xpath = '../table[@summary = "List of data-fields"]') %>% html_table() %>%
          as.data.frame() %>%
          select(Field.ID)
      }
    }
}



# get_fields_sub_category_biobank("https://biobank.ndph.ox.ac.uk/showcase/label.cgi?id=1")
# 
# 
# 
# read_html("https://biobank.ndph.ox.ac.uk/showcase/cats.cgi") %>%
#   html_elements(xpath = paste0('.//div[@class = "tabbertab"]/h2[text() = "', "277 Origin Categories", '"]')) %>% 
#   html_elements(xpath = '..') %>%
#   html_elements(xpath = './/table/tr/td[@class = "txt"]/a[@class = "alabel"]') %>%
#   html_attr("href") %>% paste0("https://biobank.ndph.ox.ac.uk/showcase/", .)  
# 
# read_html("https://biobank.ndph.ox.ac.uk/showcase/cats.cgi") %>%
#   html_elements(xpath = paste0('.//div[@class = "tabbertab"]/h2[text() = "', "277 Origin Categories", '"]')) %>% 
#   html_elements(xpath = '..') %>%
#   html_elements(xpath = './/table') %>%
#   html_table() %>% 
#   as.data.frame() %>% 
#   filter(grepl("[+]", Items)) 
# 
# get_category_biobank("277 Origin Categories")
