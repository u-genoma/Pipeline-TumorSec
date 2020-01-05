library(vcfR)
library(reshape2)
library(ggplot2)

args <- commandArgs(trailingOnly = TRUE)
print(args)
all_samples_vcf=args[1]
output=args[2]
#output="/Users/evelin/Desktop/Reporte_Variantes/190617_TumorSec"
#all_samples_vcf="/Users/evelin/Desktop/Reporte_Variantes/190617_TumorSec/9_annotate/ALL_SAMPLES.annovar.hg19_multianno.vcf"
vcf <- vcfR::read.vcfR(all_samples_vcf, verbose = FALSE)
dp <- extract.gt(vcf, element='DP4', as.numeric = TRUE)

dp <- extract.gt(vcf, element='DP4', as.list(TRUE))
for(i in 1:length(dp)) 
  if(!is.na(dp[i]))
    dp[i]<-as.numeric(sum(as.numeric(unlist(strsplit(dp[i],",")))))

dpf <- melt(dp, varnames=c('Index', 'Sample'),value.name ='Depth', na.rm=TRUE)
dpf$Depth<-as.numeric(as.character(dpf$Depth))
p <- ggplot(dpf, aes(x=Sample, y=Depth)) + geom_boxplot() + geom_segment(aes(x=dpf$Sample[1], y=400, xend=dpf$Sample[length(dpf$Sample)], yend=400), colour="red") 
p <- p + theme_bw()
p <- p + ylab('DP')
p <- p + theme(axis.title.x = element_blank(),axis.text.x = element_text(angle = 60, hjust = 1))

png(filename=paste0(output,"/dp_boxplot.png"), height = 5, width = 5, res = 200, units = "in")
p
dev.off()
print(paste0("Box plot de la profundidad por muestra: ---> LISTO!!"))
