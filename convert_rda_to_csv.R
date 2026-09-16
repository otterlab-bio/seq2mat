#!/usr/bin/env Rscript

# Convert R .rda gene database files to CSV format
# This script is run once to prepare the database for the Go application

# Get the directory where this script is located
args <- commandArgs(trailingOnly = FALSE)
script_path <- sub("--file=", "", args[grep("--file=", args)])
script_dir <- dirname(script_path)

# Paths to the R data files - relative to script directory
rda_human <- file.path(script_dir, "data", "Entrez_Gene_Id_db.rda")
rda_mouse <- file.path(script_dir, "data", "Entrez_Gene_Id_db_mmu.rda")

# Output CSV files - also relative to script directory
csv_human <- file.path(script_dir, "data", "gene_mapping_human.csv")
csv_mouse <- file.path(script_dir, "data", "gene_mapping_mouse.csv")

cat("Script directory:", script_dir, "\n")
cat("Human database:", rda_human, "\n")
cat("Mouse database:", rda_mouse, "\n")
cat("Output human CSV:", csv_human, "\n")
cat("Output mouse CSV:", csv_mouse, "\n\n")

# Check if R files exist
if (!file.exists(rda_human)) {
  stop(paste("Human database file not found:", rda_human))
}
if (!file.exists(rda_mouse)) {
  stop(paste("Mouse database file not found:", rda_mouse))
}

# Convert human database
cat("Converting human gene database to CSV...\n")
load(rda_human)
human_mapping <- data.frame(
  gene_id = Entrez_Gene_Id_db$ENSEMBL,
  symbol = Entrez_Gene_Id_db$SYMBOL,
  stringsAsFactors = FALSE
)
write.table(human_mapping, csv_human, sep = "\t", row.names = FALSE, quote = FALSE)
cat(sprintf("  Converted %d human gene mappings\n", nrow(human_mapping)))

# Convert mouse database
cat("Converting mouse gene database to CSV...\n")
load(rda_mouse)
mouse_mapping <- data.frame(
  gene_id = Entrez_Gene_Id_db_mmu$ENSEMBL,
  symbol = Entrez_Gene_Id_db_mmu$SYMBOL,
  stringsAsFactors = FALSE
)
write.table(mouse_mapping, csv_mouse, sep = "\t", row.names = FALSE, quote = FALSE)
cat(sprintf("  Converted %d mouse gene mappings\n", nrow(mouse_mapping)))

cat("\nDatabase conversion complete!\n")
cat("CSV files created:\n")
cat("  ", csv_human, "\n")
cat("  ", csv_mouse, "\n")
