require(stringr)
require(magrittr)

samples <- data.frame(read.table('sample_list.tsv.csv', header = TRUE))


samples$sample_id <- str_replace(samples$sample_id, 'b', 'B')   

unique(samples$sample_id) %>% length()


frequency <- as.data.frame(table(samples$sample_id))

res <- vector()
for (i in frequency$Freq) {
     res <- c(res, seq(1,i))
}

samples$fq_index <- res

samples$ifpan_sample_id <- paste(samples$sample_id, c(rep("_", length(res))), samples$fq_index, c(rep(".fq.gz", length(res))), sep="")


samples <- data.frame(samples$original_file_name, samples$ifpan_sample_id)
write.table(samples, "samples_naming.tsv")
