library(ggplot2)
library(reshape2)
library(gridExtra)
library(grid)

args <- commandArgs(trailingOnly = TRUE)
print(args)
regions_target_file=args[1]
output=args[2]
sample=args[3]
output_csv=args[4]

#mutation_analisys_file=args[3]
#regions_target_file="/Users/egonzalez/Desktop/PUCOv013_S1.mosdepth.thresholds.bed.gz"
#sample="PUCOv013_S1"
#output_csv=""

targets_regions <- read.csv(file=regions_target_file, header=TRUE, sep ='\t')

targets_regions$length <- as.numeric(targets_regions$end - targets_regions$start)
targets_regions$pct_100X<- as.integer(targets_regions$X100X*100/targets_regions$length)
targets_regions$pct_200X<- as.integer(targets_regions$X200X*100/targets_regions$length)
targets_regions$pct_300X<- as.integer(targets_regions$X300X*100/targets_regions$length)
targets_regions$pct_400X<- as.integer(targets_regions$X400X*100/targets_regions$length)
targets_regions$pct_500X<- as.integer(targets_regions$X500X*100/targets_regions$length)
targets_regions$pct_600X<- as.integer(targets_regions$X600X*100/targets_regions$length)
targets_regions$pct_700X<- as.integer(targets_regions$X700X*100/targets_regions$length)
targets_regions$pct_800X<- as.integer(targets_regions$X800X*100/targets_regions$length)
targets_regions$pct_1000X<- as.integer(targets_regions$X1000X*100/targets_regions$length)

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

p1<-ggplot(dpf1, aes(x =variable, y=value, group = region, colour = region)) + 
  ylim(0, 100) +
  #geom_text(aes(label=ifelse(value<90,as.character(region),''))) +
  geom_text(aes(label=ifelse(value<90,ifelse(variable=='pct_400X',as.character(region),''),''),hjust = 0, vjust = 0, size = 0.2),check_overlap = FALSE) +
  #geom_text(aes(label = ifelse(value<90,ifelse(variable=='pct_400X',as.character(region),''),'')),vjust = 1.4, color = "red", size = 2) +
  xlab('Profundidad') +
  ylab('Porcetaje cubierto de la region blanco') +
  geom_line() +
  theme(legend.position="none",text = element_text(size=16))

png(filename=paste0(output,"/",sample,"_coverage_by_targets_region.png"), height = 12, width = 10, res = 200, units = "in")
p1
dev.off()
print(paste0("Gr??fico de profundidad y amplitud por region target, muestra:",sample," ---> LISTO!!"))

###numero de regiones bajo 100% en 400X
mean <-mean(dpf1$value[dpf1$variable=="pct_400X"])
##Numero de regiones bajo 90% en 400X
m_100<-sum(ifelse(dpf1$value[dpf1$variable=="pct_400X"]<100,TRUE,FALSE))
m_90<-sum(ifelse(dpf1$value[dpf1$variable=="pct_400X"]<90,TRUE,FALSE))
#Numero de regiones bajo 80 en 400X
m_80<-sum(ifelse(dpf1$value[dpf1$variable=="pct_400X"]<80,TRUE,FALSE))
m_70<-sum(ifelse(dpf1$value[dpf1$variable=="pct_400X"]<70,TRUE,FALSE))

x <- data.frame("Sample" =sample,"mean"=mean,"70" = m_70, "80" = m_80, "90"=m_90, "100"=m_100)
write.table(x, file = paste0(output_csv,"/",sample,"_400X.csv"),row.names = F, col.names=F, sep=',')
  

