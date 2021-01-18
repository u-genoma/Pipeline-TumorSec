library(vcfR)
library(reshape2)
library(ggplot2)
library(dplyr)
library(tidyr)

args <- commandArgs(trailingOnly = TRUE)
print(args)
all_samples_vcf=args[1]
output=args[2]
#output="/Users/evelin/Desktop/Reporte_Variantes/190617_TumorSec"
#all_samples_vcf="ALL_SAMPLES.annovar.hg19_multianno.vcf"
vcf <- vcfR::read.vcfR(all_samples_vcf, verbose = FALSE)
dp <- extract.gt(vcf, element='DP4', as.numeric = TRUE)

dp <- extract.gt(vcf, element='DP4', as.list(TRUE))
for(i in 1:length(dp)) 
  if(!is.na(dp[i]))
    dp[i]<-as.numeric(sum(as.numeric(unlist(strsplit(dp[i],",")))))

dpf <- melt(dp, varnames=c('Index', 'Sample'),value.name ='Depth', na.rm=TRUE)
dpf$Sample <- gsub("TUMOR.","",dpf$Sample)

df.order<-data.frame(row=unique(dpf$Sample),Sample=unique(dpf$Sample))
df.order<-df.order %>% separate(row, c("X","order"), "[_]")
df.order.sorted<-df.order[order(df.order$order),]


dpf$Depth<-as.numeric(as.character(dpf$Depth))

dpf$Sample<- factor(dpf$Sample, levels = df.order.sorted$Sample)

p <- ggplot(dpf, aes(x=Sample, y=Depth)) + geom_boxplot() + geom_hline(yintercept=300, linetype="dashed", color = "red", size=0.7) 
p <- p + theme_bw()
p <- p + ylab('DP')
p <- p + theme(axis.title.x = element_blank(),axis.text.x = element_text(angle = 60, hjust = 1))
png(filename=paste0(output,"/dp_boxplot.png"), height = 5, width = 5, res = 200, units = "in")
p
dev.off()
print(paste0("Box plot: profundidad de variantes por muestra: ---> LISTO!!"))