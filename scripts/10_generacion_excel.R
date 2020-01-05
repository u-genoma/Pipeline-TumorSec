#!/usr/bin/env Rscript
############################
# 
# Script parte del pipeline TumorSec 
# Evelin Gonzalez
#
# Fecha: 26 Junio 2019
#
# Descripcion: Este programa utiliza como input el archivo; drug description, mutation analysis
# de CGI, y de numero de reads por regiones target. Genera como salida un excel  
# con 3 pesta??as, 1_mutation_analysis, 2_drug_description, 3_targets_regions
#
# EXAMPLE: Rscript --vanilla annotated_VCF.R /Users/egonzalez/Desktop/Reporte_Variantes/PUCOv001_S1_CGI/drug_prescription.tsv
# /Users/egonzalez/Desktop/Reporte_Variantes/PUCOv001_S1_CGI/mutation_analysis.tsv 
# /Users/egonzalez/Desktop/Reporte_Variantes/PUCOv003_S3.mosdepth.regions.bed.gz
# /Users/egonzalez/Desktop/Reporte_Variantes/PUCOv001_S1 
#
############################
library(writexl)

#options(echo=TRUE) # if you want see commands in output file
args <- commandArgs(trailingOnly = TRUE)
print(args)
annovar_multiano=args[1]
drug_rescrption_file=args[2]
mutation_analisys_file=args[3]
regions_target_file=args[4]
output=args[5]

#annovar_multiano="/Users/evelin/Desktop/Reporte_Variantes/190617_TumorSec/9_annotate/PUCOv013_S1.annovar.hg19_multianno.txt"
#drug_rescrption_file="/Users/evelin/Desktop/Reporte_Variantes/190617_TumorSec/11_CGI/PUCOv013_S1/drug_prescription.tsv"
#mutation_analisys_file="/Users/evelin/Desktop/Reporte_Variantes/190617_TumorSec/11_CGI/PUCOv013_S1/mutation_analysis.tsv"
#regions_target_file="/Users/evelin/Desktop/Reporte_Variantes/190617_TumorSec/4_dedup/PUCOv013_S1.mosdepth.regions.bed.gz"
#output="/Users/evelin/Desktop/Reporte_Variantes/190617_TumorSec/12_variants_report/excel/PUCOv013_S1.xlsx"

mutation_analysis <- read.csv(file=mutation_analisys_file, header=TRUE, sep ='\t')
drug_prescription <- read.csv(file=drug_rescrption_file, header=TRUE, sep ='\t')
targets_regions <- read.csv(file=regions_target_file, header=TRUE, sep =',')
annovar <- read.csv(file=annovar_multiano, header=TRUE, sep =',') ### INPUT VCF, PROCESAR CON MAFTOOLS.
#names(targets_regions) <- c("CHR","POS_INI","POS_END","REGION","MEAN_COVERAGE")

mutation_analysis$FILTER<-NULL
mutation_analysis$FORMAT<-NULL
mutation_analysis$ID<-NULL
mutation_analysis$INFO<-NULL
mutation_analysis$QUAL<-NULL
mutation_analysis$TUMOR<-NULL

drug_prescription$SAMPLE <- NULL ### ELIMINAMOS COLUMNA SAMPLE 1_PDF_report 2_plots_and_tables 3_excel
sheets <- list("1_annovar_annotation"=annovar,"2_mutation_analysis" = mutation_analysis, "3_drug_prescription" = drug_prescription, "4_targets_regions" = targets_regions) #assume sheet1 and sheet2 are data frames
write_xlsx(sheets,output)
