#########################
#   30 Junio 2019
#   Evelin Gonzalez
#
#   Descripcion: Este scrip produce graficos y metricas de las variantes anotadas con annovar y CGI. 
#   realiza el oncoplot y el plot resumen por corrida a partir los archivos de annovar. Genera metricas 
#   con respecto al resultado del CGI, por muestra. Diseñado para ser integrado en el pipeline de TumorSec.
#
#   Rscript 7_plots_and_csv_variantes.R /Users/evelin/Desktop/Reporte_Variantes/190617_TumorSec PUCOv013_S1 PUCOv014_S2 PUCOv015_S3 PUCOv016_S4 PUCOv017_S5 PUCOv018_S6 PUCOv019_S7 PUCOv020_S8 Undetermined_S0
#
#########################
library(maftools)
library(dplyr)
library(tidyr)

args <- commandArgs(trailingOnly = TRUE)
#print(args)
path_input=args[1]
Samples=args[2:length(args)]


filenames <- Sys.glob(paste0(path_input,"/6_annotate/6.1_ANNOVAR/*.annovar.hg19_multianno.txt"))
annovar_mafs = lapply(filenames, annovarToMaf) #convert to MAFs using annovarToMaf
annovar_mafs = data.table::rbindlist(l = annovar_mafs, fill = TRUE) #Merge into single MAF
colnames(annovar_mafs) <- make.unique(names(annovar_mafs))

vcNames <- names(table(annovar_mafs$Variant_Classification))
annovar_mafs = read.maf(maf = annovar_mafs)

Summary<-mafSummary(annovar_mafs) ### METRICS
By_sample_summary<-Summary$variant.type.summary

columnas<-c("Tumor_Sample_Barcode","Num_very_hight_patogenic","Num_hight_patogenic","Num_medium_patogenic","Num_drug_prescription")
CGI_summary<-data.frame(matrix(NA, nrow =1, ncol = length(columnas)))## cambiar por numero de muestras +1
colnames(CGI_summary) <- columnas

#### Ingresamos la ruta del CGI
for(sample in Samples){
  
  mutation_analysis_file<-paste0(path_input,"/6_annotate/6.2_CGI/",sample,"/mutation_analysis.tsv")
  drug_rescrption_file<-paste0(path_input,"/6_annotate/6.2_CGI/",sample,"/drug_prescription.tsv")

  mutation_analysis <- read.csv(file=mutation_analysis_file, header=TRUE, sep ='\t')
  drug_prescription <- read.csv(file=drug_rescrption_file, header=TRUE, sep ='\t')

  Num_drug_prescription<-length(drug_prescription$SAMPLE)
  #### NUMERO DE VARIANTES VERY HIGTH PATOGENIC (CADD_phred > 20)
  very_higth_patogenic<-mutation_analysis$cadd_phred >30
  Num_very_higth_patogenic<-sum(very_higth_patogenic==TRUE, na.rm=TRUE)

  ### NUMERO DE VARIANTES HIGTH PATOGENIC (CADD < 20 and > 15)
  higth_patogenic<-mutation_analysis$cadd_phred < 30 & mutation_analysis$cadd_phred > 25
  Num_higth_patogenic<-sum(higth_patogenic==TRUE, na.rm=TRUE)

  ### NUMEOR DE VARIANTES MEDIUM PATOGENICS
  med_patogenic<-mutation_analysis$cadd_phred < 25 & mutation_analysis$cadd_phred > 20
  Num_med_patogenic<-sum(med_patogenic==TRUE, na.rm=TRUE)

  nueva_fila<-list(sample,Num_very_higth_patogenic,Num_higth_patogenic,Num_med_patogenic,length(drug_prescription$SAMPLE))
  CGI_summary<-rbind(CGI_summary,nueva_fila)
  ### contamos el numero de variante patogenicas muy alto, alto, medio. 
}

total <- merge(By_sample_summary,CGI_summary,by="Tumor_Sample_Barcode")
total$SAMPLE<-total$Tumor_Sample_Barcode

df.total<- total %>% separate(SAMPLE, c("Sample","order"), "[_]")
df.total.sorted<-df.total[order(df.total$order),]
write.csv(df.total.sorted,paste0(path_input,"/7_variants_report/7.3_summary_output/summary_variantes_per_sample.csv"))
print("summary_variantes_per_sample CSV ----> LISTO !!!")



