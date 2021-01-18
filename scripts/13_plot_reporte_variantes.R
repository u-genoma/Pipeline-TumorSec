## Evelin Gonzalez F. 01-12-20
## Graficos que se incluyen en el reporte de variantes del pipeline TumorSec. 
## Como entrada,se utilizará el archivo con todas las variantes de una corrida, con annotacion previa
## (ANNOVAR + CGI), filtrado (se eliminan variantes con MAF>1%, VAF<5%) y clasificacion de variantes:
## (Somatica, Posible Somatica, Posible Somatica Novel, Germinal, Posible Germinal y Posible Germinal Novel)

library(maftools)
library(dplyr)
library(tidyr)

## FUNCION 1: Oncoplot ANNOVAR, mutaciones somáticas (S, PS Y PSN)
plot_maftools<-function(dataframe.variantes,path_output){

dataframe.variantes$Hugo_Symbol<-as.character(dataframe.variantes$Hugo_Symbol)

dataframe.variantes$clasificacion<-gsub("Posible_Germinal","GERMINAL",dataframe.variantes$clasificacion)
dataframe.variantes$clasificacion<-gsub("Germinal","GERMINAL",dataframe.variantes$clasificacion)
dataframe.variantes$clasificacion<-gsub("Posible_Germinal","GERMINAL",dataframe.variantes$clasificacion)
dataframe.variantes$driver_mut_prediction<-gsub("TIER 1","DRIVER",dataframe.variantes$driver_mut_prediction)
dataframe.variantes$driver_mut_prediction<-gsub("TIER 2","DRIVER",dataframe.variantes$driver_mut_prediction)

df.order<-data.frame(row=unique(dataframe.variantes$Tumor_Sample_Barcode),Sample=unique(dataframe.variantes$Tumor_Sample_Barcode))
df.order<-df.order %>% separate(row, c("X","order"), "[_]")
df.order.sorted<-df.order[order(df.order$order),]

print(df.order.sorted)

laml = read.maf(maf = dataframe.variantes)

col =c("coral4","blue3","#33A02C","mediumpurple1","red","#A6CEE3","yellow","black")
names(col) = c('In_Frame_Del','Frame_Shift_Ins','Missense_Mutation', 'Frame_Shift_Del','Nonsense_Mutation','In_Frame_Ins','Splice_Site','Multi_Hit')
png(file=paste0(path_output,"/1_ONCOPLOT_S_PS_PSN_G_PS_PGN_LabelGERM.png"), width=5, height=5, res=400, unit = "in")
oncoplot(laml, showTumorSampleBarcodes = TRUE,SampleNamefontSize = 0.7, legendFontSize = 1.2,
         top = 200, drawColBar=TRUE,colors = col, additionalFeature = c("clasificacion","GERMINAL"),additionalFeatureCex=4,
         sampleOrder = df.order.sorted$Sample, legend_height = 3, barcode_mar= 6)
dev.off()
print("ONCOPLOT 1 DE VARIANTES FILTRADAS<- LISTO!")

png(file=paste0(path_output,"/1_ONCOPLOT_S_PS_PSN_G_PS_PGN_LabelDRIVER.png"), width=5, height=5, res=400, unit = "in")
oncoplot(laml, showTumorSampleBarcodes = TRUE, SampleNamefontSize = 0.7, legendFontSize = 1.2,
         top = 200, drawColBar=TRUE,colors = col, additionalFeature = c("driver_mut_prediction","DRIVER"),additionalFeatureCex=4,
         sampleOrder = df.order.sorted$Sample,legend_height = 3, barcode_mar=6)
dev.off()
print("ONCOPLOT 2 DE VARIANTES FILTRADAS<- LISTO!")

#--- Gráfico resumen de variantes.
png(file=paste0(path_output,"/2_PLOT_SUMMARY_S_PS_PSN_G_PS_PGN.png"), width=6.5, height=5, res=200, unit = "in")
plotmafSummary(laml, color = col, showBarcodes = TRUE, textSize=0.5)
dev.off()
print("SUMMARY DE VARIANTES FILTRADAS<- LISTO!")

}

## MAIN
args <- commandArgs(trailingOnly = TRUE)
print(args)
file_input=args[1]
path_output=args[2]

## Importar maft,  filtrado MAF en PDVs , con VAF=>0.05 , y con clasificacion de las variantes como somatica/germinal
merge.cgi.annovar<-read.csv(file_input, header = T, sep = "\t")


plot_maftools(merge.cgi.annovar,path_output)








