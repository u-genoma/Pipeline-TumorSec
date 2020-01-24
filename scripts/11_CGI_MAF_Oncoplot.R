# AUTORA: Evelin Gonzalez
# Fecha: 14 Diciembre 2019
#
# DESCRIPCION: Este programa toma archivo que contiene una lista de archivos CGI, la ruta de salida
# donde se almacenarán los resultados, y los parametros de AF, ExAC y depth de alteracion para filtrar
# las variantes
# OUTPUT: Archivo MAF sin filtrar, archivo MAF filtrado (por AF, ExAC y DP_ALT)
# oncoplot de variantes son efecto en la proteina, y otro oncoplot + silent.

## para ejecutar el scrip ejecutar en terminar Rscript --vanilla CGI_oncoplot.R [FILE_LIST_CGI_FILES] [OUTPUT DIRECTORY] [AF] [ExAC] [DP_ALT]
##EJEMPLO: Rscript --vanilla CGI_oncoplot.R list_CGI_inputs.txt /Users/evelin/Dropbox/CGI_oncoplot 0.02 0.01 12

library(maftools)
library(gtools)
library(dplyr)
library(tidyr)
library(stringr)

#options(echo=TRUE) # if you want see commands in output file
args <- commandArgs(trailingOnly = TRUE)
print(args)
list_CGI_inputs=args[1]
path_output=args[2]
path_output_maf=args[3]
AF=args[4]
ExAC=args[5]
DP_ALT=args[6]

#list_CGI_inputs="/Users/evelin/Dropbox/CGI_oncoplot/list_CGI_inputs.txt" ### cambiar la ruta
#path_output="/Users/evelin/Dropbox/CGI_oncoplot" ### oncoplot de salida.
all.data.merge = data.frame()
#AF<-0.02
#ExAC<-0.01
#DP_ALT<-12
#laml.maf = system.file('extdata',path_input, package = 'maftools') 
### ajusta el formato de entrada unico. CGI entrega dos formatos de salida (orden de las columnas), por tanto, antes de procesar la información, es necesario ajustar le formato.
format_CGI<-function(x){
  CGI<-read.csv(x, header = T, sep = "\t")
  CGI_sorted <- CGI[sort(names(CGI))]
  return(CGI_sorted)
}
CGI_to_maft<-function(all.data.merge){
  all.data.merge<-all.data.merge[1:52]
  all.data.merge<- all.data.merge %>% separate(TUMOR, c("GT","DP4","CD4","refMQ","altMQ","refBQ","altBQ","refNM","altNM","fetSB","fetCD","zMQ","zBQ","MQ0","VAF"),"[:]")
  all.data.merge<- all.data.merge %>% separate(DP4 , c("DP_REF1","DP_REF2","DP_ALT1", "DP_ALT2"), "[,]")
  all.data.merge<- all.data.merge %>% separate(INFO, c("AF","MVDLPK","NUM_TOOLS"), "[;]")
  all.data.merge$AF<- gsub('AF=','', all.data.merge$AF)
  all.data.merge$MVDLPK<- gsub('MVDLPK=','', all.data.merge$MVDLPK)
  all.data.merge$MVDLPK<- gsub('MVDLK=','', all.data.merge$MVDLPK)
  all.data.merge$NUM_TOOLS<- gsub('NUM_TOOLS=','', all.data.merge$NUM_TOOLS)
  all.data.merge$input<-as.factor(all.data.merge$input)
  all.data.cgi<-all.data.merge %>% separate(input, c("Chromosome","Start_Position","Reference_Allele","Tumor_Seq_Allele2"), "[|]")
  all.data.cgi$End_Position<-all.data.cgi$Start_Position ## modificar
  all.data.cgi<-all.data.cgi %>% rename(Hugo_Symbol = gene, Tumor_Sample_Barcode = sample)
  
  ### AGREGAR CLASIFICACION: INS, DELo SNP
  all.data.cgi$length_ref<-str_count(all.data.cgi$Reference_Allele)
  all.data.cgi$length_alt<-str_count(all.data.cgi$Tumor_Seq_Allele2)
  all.data.cgi$Variant_Type[all.data.cgi$length_ref == 1 & all.data.cgi$length_alt == 1] <-"SNP"
  all.data.cgi$Variant_Type[all.data.cgi$length_ref > all.data.cgi$length_alt]<- "DEL"
  all.data.cgi$Variant_Type[all.data.cgi$length_ref < all.data.cgi$length_alt]<- "INS"
  
  all.data.cgi$Variant_Classification[all.data.cgi$consequence == "3-UTRDeletion"  | all.data.cgi$consequence == "3-UTRInsertion"| all.data.cgi$consequence == "3-UTRSNV" ] <-"3'UTR"
  all.data.cgi$Variant_Classification[all.data.cgi$consequence == "5-UTRDeletion"  | all.data.cgi$consequence == "5-UTRInsertion"| all.data.cgi$consequence == "5-UTRSNV" ] <-"5'UTR"
  all.data.cgi$Variant_Classification[all.data.cgi$consequence == "IntronicDeletion" | all.data.cgi$consequence == "IntronicInsertion"| all.data.cgi$consequence == "IntronicSNV"] <- "Intron"
  all.data.cgi$Variant_Classification[all.data.cgi$consequence == "Synonymous"] <- "Silent"
  all.data.cgi$Variant_Classification[all.data.cgi$consequence == "Missense"] <- "Missense_Mutation"
  all.data.cgi$Variant_Classification[all.data.cgi$consequence == "InFrameInsertion"] <-"In_Frame_Ins"
  all.data.cgi$Variant_Classification[all.data.cgi$consequence == "InFrameDeletion"] <-"In_Frame_Del"
  all.data.cgi$Variant_Classification[all.data.cgi$consequence == "Nonsense"] <-"Nonsense_Mutation"
  all.data.cgi$Variant_Classification[all.data.cgi$consequence == "Frameshift" & all.data.cgi$Variant_Type == "DEL"] <-"Frame_Shift_Del"
  all.data.cgi$Variant_Classification[all.data.cgi$consequence == "Frameshift" & all.data.cgi$Variant_Type == "INS"] <-"Frame_Shift_Ins"
  
  return(all.data.cgi)
}
save_maf<-function(maf.object,path_output){
write.table(maf.object, file=path_output, quote=FALSE, sep='\t', row.names = F)
}
filter_CGI<-function(all.data.cgi,AF,ExAC,DP_ALT){ ## filtro por frecuencia alélica de la variante, profundidad de alteriacion (DP_ALT) y freuencia alélica en ExAC 
  all.cgi_filter<-all.data.cgi[all.data.cgi$VAF >= AF,]
  all.cgi_filter$DP_ALT<-as.numeric(as.character(all.cgi_filter$DP_ALT1)) + as.numeric(as.character(all.cgi_filter$DP_ALT2))
  all.cgi_filter<-all.cgi_filter[all.cgi_filter$DP_ALT > DP_ALT,]
  all.cgi_filter<-all.cgi_filter[is.na(all.cgi_filter$exac_af) | all.cgi_filter$exac_af < AF,]
  return(all.cgi_filter)
}
create_oncoplots<-function(maf.object,path_output){
  
  laml = read.maf(maf = maf.object)
  png(file=paste0(path_output,"/VAF_CGI.png"), width=5.5, height=5, res=600, unit = "in")
  plotVaf(maf = laml, vafCol = 'VAF')
  dev.off()
  png(file=paste0(path_output,"/GENE_CLOUD_CGI.png"), width=5.5, height=5, res=600, unit = "in")
  geneCloud(input = laml, minMut = 1)
  dev.off()
  png(file=paste0(path_output,"/1_oncoplot_CGI_filter.png"), width=7, height=5, res=600, unit = "in")
  oncoplot(laml, showTumorSampleBarcodes = TRUE,SampleNamefontSize = 0.6, legendFontSize = 1.5, sortByMutation = TRUE,sampleOrder = sort(unique(maf.object$Tumor_Sample_Barcode)))
  dev.off()
  ### oncoplot + silent variants
  vcNames<-c("Frame_Shift_Del","Frame_Shift_Ins","Missense_Mutation","Nonsense_Mutation","In_Frame_Del","In_Frame_Ins","Silent")
  laml = read.maf(maf = maf.object, vc_nonSyn=vcNames)
  png(file=paste0(path_output,"/2_oncoplot_CGI_filter_silent.png"), width=7, height=5, res=600, unit = "in")
  oncoplot(maf =laml, showTumorSampleBarcodes = TRUE, SampleNamefontSize = 0.6,legendFontSize = 1.5, sortByMutation = TRUE, sampleOrder = sort(unique(maf.object$Tumor_Sample_Barcode)))
  dev.off()
}
### MAIN
CGIs<-read.csv(list_CGI_inputs, header = T, sep = "\t")
###sort columns
for (i in 1:nrow(CGIs)){
  aux<-format_CGI(as.character(CGIs[i,1]))
  all.data.merge<-smartbind(all.data.merge,aux)
}
all.data.cgi<-CGI_to_maft(all.data.merge)
### guardar datos sin filtrar
save_maf(all.data.cgi,paste0(path_output_maf,"/MAF_CGI_no_filter.maf"))
### Filtrar datos
data.cgi.filter<-filter_CGI(all.data.cgi,AF,ExAC,DP_ALT)
### guardar datos filtrados
save_maf(data.cgi.filter,paste0(path_output_maf,"/MAF_CGI_filter.maf"))

create_oncoplots(data.cgi.filter,path_output)