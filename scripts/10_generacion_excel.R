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
library(tidyr)
library(maftools)


#options(echo=TRUE) # if you want see commands in output file
args <- commandArgs(trailingOnly = TRUE)
print(args)
annovar_multiano=args[1]
drug_rescrption_file=args[2]
mutation_analisys_file=args[3]
regions_target_file=args[4]
output=args[5]

#annovar_multiano="/Users/evelin/Dropbox/R-plots/Excel_reporte/1590TFFPE_S1.annovar.hg19_multianno.txt"
#drug_rescrption_file="/Users/evelin/Dropbox/R-plots/Excel_reporte/drug_prescription.tsv"
#mutation_analisys_file="/Users/evelin/Dropbox/R-plots/Excel_reporte/mutation_analysis_rename.tsv"
#regions_target_file="/Users/evelin/Dropbox/R-plots/Excel_reporte/1590TFFPE_S1_by_target_region.csv"
#output="/Users/evelin/Dropbox/R-plots/Excel_reporte/1590TFFPE.xlsx"

mutation_analysis <- read.table(file=mutation_analisys_file, header=TRUE, sep ='\t', check.names = FALSE)
colnames(mutation_analysis) <- make.unique(names(mutation_analysis))


drug_prescription <- read.table(file=drug_rescrption_file, header=TRUE, sep ='\t')
targets_regions <- read.table(file=regions_target_file, header=TRUE, sep =',')

mutation_analysis$FORMAT<-NULL
mutation_analysis$ID<-NULL
mutation_analysis$QUAL<-NULL

mutation_analysis <- mutation_analysis %>% separate(TUMOR, c("GT","DP4","CD4","refMQ","altMQ","refBQ","altBQ","refNM","altNM","fetSB","fetCD","zMQ","zBQ","MQ0","VAF"),"[:]")
mutation_analysis <- mutation_analysis %>% separate(DP4 , c("DP_REF1","DP_REF2","DP_ALT1", "DP_ALT2"), "[,]")
mutation_analysis <- mutation_analysis %>% separate(INFO, c("AF","MVDLPK","NUM_TOOLS"), "[;]")
mutation_analysis$AF<- gsub('AF=','', mutation_analysis$AF)
mutation_analysis$MVDLPK<- gsub('MVDLPK=','', mutation_analysis$MVDLPK)
mutation_analysis$MVDLPK<- gsub('MVDLK=','', mutation_analysis$MVDLPK)
mutation_analysis$NUM_TOOLS<- gsub('NUM_TOOLS=','', mutation_analysis$NUM_TOOLS)

drug_prescription$SAMPLE <- NULL ### ELIMINAMOS COLUMNA SAMPLE 1_PDF_report 2_plots_and_tables 3_excel

var.annovar.maf <- annovarToMaf(annovar =annovar_multiano, Center = 'CSI-NUS', refBuild = 'hg19',tsbCol = 'Tumor_Sample_Barcode', table = 'refGene')
colnames(var.annovar.maf) <- make.unique(names(var.annovar.maf))
var.annovar.maf <- var.annovar.maf %>% separate(V144, c("GT","DP4","CD4","refMQ","altMQ","refBQ","altBQ","refNM","altNM","fetSB","fetCD","zMQ","zBQ","MQ0","VAF"),"[:]")
var.annovar.maf <- var.annovar.maf %>% separate(DP4 , c("DP_REF1","DP_REF2","DP_ALT1", "DP_ALT2"), "[,]")
var.annovar.maf$DP_ALT<-as.numeric(var.annovar.maf$DP_ALT1) + as.numeric(var.annovar.maf$DP_ALT2)
var.annovar.maf <- var.annovar.maf %>% separate(V142, c("AF","MVDLPK","NUM_TOOLS"), "[;]")
var.annovar.maf$AF<- gsub('AF=','', var.annovar.maf$AF)
var.annovar.maf$MVDLPK<- gsub('MVDLPK=','', var.annovar.maf$MVDLPK)
var.annovar.maf$MVDLPK<- gsub('MVDLK=','', var.annovar.maf$MVDLPK)
var.annovar.maf$NUM_TOOLS<- gsub('NUM_TOOLS=','',var.annovar.maf$NUM_TOOLS)

#var.annovar.maf$V115<-NULL
#var.annovar.maf$V116<-NULL
#var.annovar.maf$V117<-NULL
#var.annovar.maf$V118<-NULL
#var.annovar.maf$V119<-NULL
#var.annovar.maf$V120<-NULL
#var.annovar.maf$V121<-NULL
#var.annovar.maf$V122<-NULL
#var.annovar.maf$V125<-NULL

sheets <- list("1_ANNOVAR"=var.annovar.maf,"2_mutation_analysis" = mutation_analysis, "3_drug_prescription" = drug_prescription, "4_targets_regions" = targets_regions) #assume sheet1 and sheet2 are data frames
write_xlsx(sheets,output)
