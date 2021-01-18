library(vcfR)
library(reshape2)
library(ggplot2)
library(maftools)

#options(echo=TRUE) # if you want see commands in output file
args <- commandArgs(trailingOnly = TRUE)
print(args)
input_vcf=args[1]
input_txt=args[2]
output=args[3]

#input_vcf="PUCOv001_S1.annovar.hg19_multianno.vcf"
#input_txt="PUCOv001_S1.annovar.hg19_multianno.txt"
#output='PUCOv001_S1.annovar.hg19_multianno.csv'
### INPUT-> VCF ANNOVAR Y TXT, RUTA Y NOMBRE DE CSV DE SALIDA.
# Find and input VCF data.

vcf <- vcfR::read.vcfR(input_vcf, verbose = FALSE)

var.annovar.maf <- annovarToMaf(annovar =input_txt, Center = 'CSI-NUS', refBuild = 'hg19',tsbCol = 'Tumor_Sample_Barcode', table = 'refGene')
colnames(var.annovar.maf) <- make.unique(names(var.annovar.maf))

#Parse DP from the gt region.
#dp <- extract.gt(vcf, element='DP4', as.list(TRUE))
#for(i in 1:length(dp))
#  if(!is.na(dp[i]))
#    dp[i]<-sum(as.numeric(unlist(strsplit(dp[i],","))))
#INFO2df(vcf)
metaINFO <- metaINFO2df(vcf)

#numero de variantes largo 
HEAD=strsplit(vcf@gt[1,1], ":")
INFO <-c()
INFO2 <-c()
INFO3 <-c()
HEAD2 <-c()
LIST_TUMOR_INFO<-list()
#df$new.col <- a.vector

for(i in 1:(length(vcf@gt)/2)){
  INFO[i]=strsplit(vcf@gt[i,2], ":")
}

vcf@fix[1,]# CROM, # POS,ID, REF, ALT, QUAL, FILTER INFO_ANNOVAR
columnas<-c('CROM','POS', 'ID', 'REF','ALT','DP_REF','DP_ALT','GT','DP4ALL','CD4','refMQ', 'altMQ', 'refBQ', 'altBQ', 'refNM', 'altNM', 'fetSB', 'fetCD', 'zMQ','zBQ','MQ0','VAF','AF','MVDLPK','NUM_TOOLS')
df_vcf<-data.frame(matrix(NA, nrow =1, ncol = length(columnas)))
colnames(df_vcf) <- columnas

### OBTENEMOS LA INFORMACIÓN POR MUESTRA.
for(i in 1:(length(vcf@gt)/2)){
  INFO2[i]=strsplit(vcf@fix[i,8],";")
  for(x in 1:length(INFO2[[i]])){
    HEAD2[x]<-unlist(strsplit(as.character(INFO2[[i]][x]),"="))[1]
    INFO2[[i]][x]<-unlist(strsplit(as.character(INFO2[[i]][x]),"="))[2]
  }
}
### UNIMOS LAS DOS LITAS, INFO y INFO2
for(i in 1:(length(INFO))){

  dp4<-strsplit(INFO[[i]][2],",")
  aux<-c(vcf@fix[[i,1]],vcf@fix[[i,2]],vcf@fix[[i,3]],vcf@fix[[i,4]],vcf@fix[[i,5]],(as.numeric(dp4[[1]][1])+as.numeric(dp4[[1]][2])),(as.numeric(dp4[[1]][3])+as.numeric(dp4[[1]][4])))
  INFO3<-append(aux,INFO[[i]],after=length(aux))
  LIST_TUMOR_INFO<-append(INFO3, INFO2[[i]][1:3], after = length(INFO3))
  df_vcf <-rbind(df_vcf,LIST_TUMOR_INFO)
}

names(var.annovar.maf)[99] = "CROM"
names(var.annovar.maf)[100] = "POS"

### MERGE DATAFRAME OF MAFTOOLS OBJET, AND ANNOVAR DATAFRAME
total_ANNOVAR <- merge(df_vcf,var.annovar.maf,by=c("CROM","POS"))

total_ANNOVAR$V90<-NULL
total_ANNOVAR$Otherinfo<-NULL
total_ANNOVAR$V89<-NULL
total_ANNOVAR$V91<-NULL
total_ANNOVAR$V92<-NULL
total_ANNOVAR$V93<-NULL
total_ANNOVAR$V94<-NULL
total_ANNOVAR$V95<-NULL
total_ANNOVAR$V96<-NULL
total_ANNOVAR$V97<-NULL
total_ANNOVAR$V98<-NULL
total_ANNOVAR$V99<-NULL
total_ANNOVAR$V100<-NULL
print(total_ANNOVAR)
write.csv(total_ANNOVAR,output)










