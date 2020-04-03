table_name = "/Users/brownm28/Documents/2020-Mar-4_WGSA/TASK_RUN/merged_summary.txt"
input_table=read.table(table_name, sep = "\t", header = TRUE)

wgsa_cost_plot = boxplot(cbind(input_table[grep("WGSA INDEL NO CALLER", input_table$task_name), ]$cost,
                               input_table[grep("WGSA INDEL ONLY", input_table$task_name), ]$cost,
                               input_table[grep("WGSA SNP INDEL ALL RPT", input_table$task_name), ]$cost),
                         col=c("purple","blue", "gray"), 
                         pch=19, main = "WGSA per sample cost (n=5)", names=c("INDEL DB ONLY", "INDEL DB PLUS CALLER", "SNP INDEL ALL"),
                         ylim = c(0,20))

caller_cost_plot = boxplot(cbind(input_table[grep("ONLY NO SNP TEST", input_table$task_name), ]$cost,
                      input_table[grep("ONLY TEST", input_table$task_name), ]$cost,
                    input_table[grep("W DB NO SNP TEST", input_table$task_name), ]$cost,
                    input_table[grep("W DB TEST", input_table$task_name), ]$cost),
                    col=c("red","green", "blue", "gray"), 
                    pch=19, main = "3 caller per sample cost (n=31)", names=c("NO DB NO SNP", "NO DB", "ALL DB NO SNP", "ALL DB ALL SNP"),
                    ylim = c(0,20))

wgsa_run_plot = boxplot(cbind(input_table[grep("WGSA INDEL NO CALLER", input_table$task_name), ]$run_hrs,
                               input_table[grep("WGSA INDEL ONLY", input_table$task_name), ]$run_hrs,
                               input_table[grep("WGSA SNP INDEL ALL RPT", input_table$task_name), ]$run_hrs),
                         col=c("purple","blue", "gray"), 
                         pch=19, main = "WGSA per sample run time in hours (n=5)", names=c("INDEL DB ONLY", "INDEL DB PLUS CALLER", "SNP INDEL ALL"),
                         ylim = c(0,20))

caller_run_plot = boxplot(cbind(input_table[grep("ONLY NO SNP TEST", input_table$task_name), ]$run_hrs,
                          input_table[grep("ONLY TEST", input_table$task_name), ]$run_hrs,
                          input_table[grep("W DB NO SNP TEST", input_table$task_name), ]$run_hrs,
                          input_table[grep("W DB TEST", input_table$task_name), ]$run_hrs),
                    col=c("red","green", "blue", "gray"), 
                    pch=19, main = "3 caller sample run time in hours (n=31)", names=c("NO DB NO SNP", "NO DB", "ALL DB NO SNP", "ALL DB ALL SNP"),
                    ylim = c(0,20))
