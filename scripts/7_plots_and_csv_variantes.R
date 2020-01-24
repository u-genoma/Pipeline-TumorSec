#########################
#   30 Junio 2019
#   Evelin Gonzalez
#
#   Descripcion: Este scrip produce graficos y metricas de las variantes anotadas con annovar y CGI. 
#   realiza el oncoplot y el plot resumen por corrida a partir los archivos de annovar. Genera metricas 
#   con respecto al resultado del CGI, por muestra. Diseñado para ser integrado en el pipeline de TumorSec.
#
#   Rscript maftools.R /Users/evelin/Desktop/Reporte_Variantes/190617_TumorSec \
#   PUCOv013_S1 PUCOv014_S2 PUCOv015_S3 PUCOv016_S4 PUCOv017_S5 PUCOv018_S6 PUCOv019_S7 PUCOv020_S8 Undetermined_S0
#
#########################
library(maftools)

args <- commandArgs(trailingOnly = TRUE)
#print(args)
path_input=args[1]
Samples=args[2:length(args)]

print(Samples)
col = c("#C93312", "#C27D38", "#899DA4", "#29211F", "#D8B70A", "#02401B", "#5B1A18", "#81A88D", "#F8AFA8", "#CCC591", "#C93312", "#FAEFD1", "#DC863B")

filenames <- Sys.glob(paste0(path_input,"/6_annotate/6.1_ANNOVAR/*.annovar.hg19_multianno.txt"))
annovar_mafs = lapply(filenames, annovarToMaf) #convert to MAFs using annovarToMaf
annovar_mafs = data.table::rbindlist(l = annovar_mafs, fill = TRUE) #Merge into single MAF

write.table(annovar_mafs,file = paste0(path_input,"/7_variants_report/7.3_summary_output/MAF_ANNOVAR.maf"), sep ='\t', quote=FALSE)

vcNames <- names(table(annovar_mafs$Variant_Classification))
annovar_mafs = read.maf(maf = annovar_mafs) #use read.maf to generate MAF object

Summary<-mafSummary(annovar_mafs) ### METRICS

write.csv(Summary$gene.summary,paste0(path_input,"/7_variants_report/7.3_summary_output/gene_summary.csv"))
print("gene_summary CSV ----> LISTO !!!")
write.csv(Summary$variants.per.sample,paste0(path_input,"/7_variants_report/7.3_summary_output/num_variants_by_sample.csv"))
print("num_variants_by_sample CSV ----> LISTO !!!")

By_sample_summary<-Summary$variant.type.summary

vcNames[length(vcNames)+1]='Multi_Hit'
names(col) = vcNames

png(filename=paste0(path_input,"/7_variants_report/7.4_Images/oncoplot_ANNOVAR.png"))
oncoplot(maf =annovar_mafs , top = 20, showTumorSampleBarcodes = TRUE, SampleNamefontSize = 0.6, legendFontSize = 1.5, removeNonMutated = FALSE, fontSize=0.8, annotationFontSize=0.3)
#dev.copy(png,paste0(path_input,"/12_variants_report/12.4_Images/oncoplot.png"))
dev.off()
print("Gráfico Oncoplot ---> LISTO!!")


png(filename=paste0(path_input,"/7_variants_report/7.4_Images/plot_summary.png"))
plotmafSummary(maf=annovar_mafs, rmOutlier = TRUE, addStat = 'median', dashboard = TRUE, titvRaw = FALSE, showBarcodes = TRUE, textSize = 0.6, color =col)# oncoplot(maf = laml, top = 10)
#dev.copy(png,paste0(path_input,"/12_variants_report/12.4_Images/plot_summary.png"))
dev.off()
print("Gráfico Summary de variantes por corrida ---> LISTO!!")


columnas<-c("Tumor_Sample_Barcode","Num_very_hight_patogenic","Num_hight_patogenic","Num_medium_patogenic","Num_drug_prescription")
CGI_summary<-data.frame(matrix(NA, nrow =1, ncol = length(columnas)))## cambiar por numero de muestras +1
colnames(CGI_summary) <- columnas

#for sample in Samples:
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
  #gatos <- rbind(gatos, nueva_fila
  nueva_fila<-list(sample,Num_very_higth_patogenic,Num_higth_patogenic,Num_med_patogenic,length(drug_prescription$SAMPLE))
  CGI_summary<-rbind(CGI_summary,nueva_fila)
  ### contamos el numero de variante patogenicas muy alto, alto, medio. 
}

total <- merge(By_sample_summary,CGI_summary,by="Tumor_Sample_Barcode")
write.csv(total,paste0(path_input,"/7_variants_report/7.3_summary_output/summary_variantes_per_sample.csv"))
print("summary_variantes_per_sample CSV ----> LISTO !!!")



