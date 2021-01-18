library(ggplot2)
library(reshape2)
library(gridExtra)
library(grid)
library(ggrepel)

args <- commandArgs(trailingOnly = TRUE)
print(args)
regions_target_file=args[1]
output=args[2]
sample=args[3]
output_csv=args[4]

#regions_target_file="/Users/egonzalez/Desktop/PUCOv061_S3.mosdepth.thresholds.bed.gz"
#sample="PUCOv061_S3"
#output="/Users/egonzalez/Desktop"
#output_csv="/Users/egonzalez/Desktop"
targets_regions <- read.csv(file=regions_target_file, header=TRUE, sep ='\t')

targets_regions$length <- as.numeric(targets_regions$end - targets_regions$start)
targets_regions$pct_100X <- as.integer(targets_regions$X100X*100/targets_regions$length)
targets_regions$pct_200X <- as.integer(targets_regions$X200X*100/targets_regions$length)
targets_regions$pct_300X <- as.integer(targets_regions$X300X*100/targets_regions$length)
targets_regions$pct_400X <- as.integer(targets_regions$X400X*100/targets_regions$length)
targets_regions$pct_500X <- as.integer(targets_regions$X500X*100/targets_regions$length)
targets_regions$pct_600X <- as.integer(targets_regions$X600X*100/targets_regions$length)
targets_regions$pct_700X <- as.integer(targets_regions$X700X*100/targets_regions$length)
targets_regions$pct_800X <- as.integer(targets_regions$X800X*100/targets_regions$length)
targets_regions$pct_1000X <- as.integer(targets_regions$X1000X*100/targets_regions$length)

targets_regions$X100X<-NULL
targets_regions$X200X<-NULL
targets_regions$X300X<-NULL
targets_regions$X400X<-NULL
targets_regions$X500X<-NULL
targets_regions$X600X<-NULL
targets_regions$X700X<-NULL
targets_regions$X800X<-NULL
targets_regions$X900X<-NULL
targets_regions$X1000X<-NULL

write.csv(targets_regions,paste0(output_csv,'/',sample,'_by_target_region.csv'))
dpf1 <- melt(targets_regions, id.vars='region',measure.vars =c('pct_100X','pct_200X','pct_300X','pct_400X'), na.rm=TRUE)
etiquetas<-dpf1[dpf1$value < 80 & dpf1$variable=='pct_300X',]
etiquetas$label<-etiquetas$region
dpf1<-merge(dpf1, etiquetas, by="region",all=TRUE)
num<-length(unique(dpf1$label)) - 1 
dpf1$label2<-dpf1$label
dpf1$label2[dpf1$variable.x!="pct_300X"]<-NA

#print(dpf1)

if(num < 20 && num > 0){
  p1 <- ggplot(dpf1, aes(x =variable.x, y=value.x, group = region, colour = label)) 
  p1 <- p1 + ylim(0, 100) + xlab('Profundidad mínima') + ylab('Porcetaje cubierto de la región blanco') 
  p1 <- p1 + geom_line() 
  p1 <- p1 + ggtitle(sample) 
  p1 <- p1 + geom_label_repel(aes(label = dpf1$label2,fill = factor(dpf1$label)), color = 'white',size =1.5) 
  p1 <- p1 + geom_hline(yintercept=80, linetype="dashed", color = "grey", size=0.7) 
  p1 <- p1 + theme_linedraw() + theme(legend.position="none")
  p1
  ggsave(paste0(output,"/",sample,"_coverage_by_targets_region.png"), plot = p1, width=5, height=5, unit = "in")  
  print("Muestra con < 20 regiones a 80% en 300X")
}
if(num >= 20){
  p2 <- ggplot(dpf1, aes(x =variable.x, y=value.x, group = region, colour = label))
  p2 <- p2 + ylim(0, 100) + xlab('Profundidad mínima') + ylab('Porcetaje cubierto de la región blanco')
  p2 <- p2 + geom_line()
  p2 <- p2 +  ggtitle(sample)
  p2 <- p2 +  geom_hline(yintercept=80, linetype="dashed", color = "grey", size=0.7)
  p2 <- p2 +  annotation_custom(grob = textGrob(paste0(num," regiones bajo 80% a 300X")),xmin = 1, xmax = 2, ymin = 5, ymax = 5)
  p2 <- p2 +  theme_linedraw() + theme(legend.position="none") 
  p2
  ggsave(paste0(output,"/",sample,"_coverage_by_targets_region.png"), plot = p2, width=5, height=5, unit = "in")  
  print("Muestra con > 20 regiones a 80% en 300X")
}
if(num <= 0){
  dpf1 <- melt(targets_regions, id.vars='region',measure.vars =c('pct_100X','pct_200X','pct_300X','pct_400X'), na.rm=TRUE)
  p3 <- ggplot(dpf1, aes(x =variable, y=value, group = region)) 
  p3 <- p3 + ylim(0, 100) + xlab('Profundidad mínima') + ylab('Porcetaje cubierto de la región blanco')
  p3 <- p3 + geom_line(color = "darkgrey")
  p3 <- p3 +  ggtitle(sample)
  p3 <- p3 +  geom_hline(yintercept=80, linetype="dashed", color = "grey", size=0.7)
  p3 <- p3 +  annotation_custom(grob = textGrob(paste0(num," regiones bajo 80% a 300X")),xmin = 1, xmax = 2, ymin = 5, ymax = 5)
  p3 <- p3 +  theme_linedraw() + theme(legend.position="none") 
  p3
  ggsave(paste0(output,"/",sample,"_coverage_by_targets_region.png"), plot = p3, width=5, height=5, unit = "in")  
  print("Muestra con 0 regiones a 80% en 300X")
}
print(paste0("Grafico de profundidad y amplitud por region target, muestra:",sample," ---> LISTO!!"))

dpf1 <- melt(targets_regions, id.vars='region',measure.vars =c('pct_100X','pct_200X','pct_300X','pct_400X'), na.rm=TRUE)

###numero de regiones bajo 100% en 400X
mean <-mean(dpf1$value[dpf1$variable=="pct_300X"])
##Numero de regiones bajo 90% en 400X
m_100<-sum(ifelse(dpf1$value[dpf1$variable=="pct_300X"]<100,TRUE,FALSE))
m_90<-sum(ifelse(dpf1$value[dpf1$variable=="pct_300X"]<90,TRUE,FALSE))
#Numero de regiones bajo 80 en 400X
m_80<-sum(ifelse(dpf1$value[dpf1$variable=="pct_300X"]<80,TRUE,FALSE))
m_70<-sum(ifelse(dpf1$value[dpf1$variable=="pct_300X"]<70,TRUE,FALSE))

x <- data.frame("Sample" =sample,"mean"=mean,"70" = m_70, "80" = m_80, "90"=m_90, "100"=m_100)
write.table(x, file = paste0(output_csv,"/",sample,"_300X.csv"),row.names = F, col.names=F, sep=',')