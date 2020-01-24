library(writexl)

#options(echo=TRUE) # if you want see commands in output file
args <- commandArgs(trailingOnly = TRUE)
print(args)
matriz=args[1]
Geno_SNP=args[2]
Geno_sample=args[3]
outputdir=args[4]

#gtseq <- read.delim("Genotipos_GenoCompile_v3_S_0.tsv", row.names=1, as.is=T)
gtseq <- read.table(matriz, header = T, sep = "\t")
rownames(gtseq)<-gtseq[,1]
gtseq<-gtseq[,-1]

#lgc <- read.delim("Genotipos_LGC.tsv", row.names=1, as.is=T)
#Función que ordena alelos en un vector de genotipos
gtsort <- function(gt,sep=":") {paste(sort(unlist(strsplit(gt,sep))),collapse=":")}
gtsort.vector <- function(gtvec, ...) sapply(gtvec, gtsort, ...)
gtsort.vector(c("TA", "GC"), sep="")

#Arreglar datos perdidos
gtseq.na <- gtseq
gtseq.na[gtseq.na==0] <- NA

#SNPs without GT% < 50%
#gtseq.missnp <- apply(!is.na(gtseq.na), 2, mean)<.5
gtseq.missnp <- apply(!is.na(gtseq.na), 2, mean)< Geno_SNP
table(gtseq.missnp)
# Samples with GT% < 50% 
#gtseq.nodata <- apply(!is.na(gtseq.na), 1, mean)<.5
gtseq.nodata <- apply(!is.na(gtseq.na), 1, mean)< Geno_sample

# There are 129 without data: REMOVE THEM
table(gtseq.nodata)
gtseq.na <- gtseq.na[!gtseq.nodata, !gtseq.missnp]

# Ordenar alelos en los genotipos de una matriz (usar sep=":" para TaqMan)
gtseq.na.sorted <- apply(gtseq.na, 2, gtsort.vector, sep="")
gtseq.na.sorted[gtseq.na.sorted==""] <- NA
gtseq.na.sorted.factor <- as.data.frame(gtseq.na.sorted, stringsAsFactors=T)
gtseq.na.sorted.numeric <- as.matrix(sapply(gtseq.na.sorted.factor, as.numeric))
rownames(gtseq.na.sorted.numeric) <- rownames(gtseq.na.sorted.factor)

# Comparar visualmente
gtseq.na.sorted.factor[1:10,1:6]
gtseq.na.sorted.numeric[1:10,1:6]

# Monomorphic SNPs
monorphic.snps <- apply(gtseq.na.sorted.numeric, 2, var, na.rm=T)==0
table(monorphic.snps)

# Remove one monomorphic SNPs
gtseq.na.sorted.numeric.polymorphic <- gtseq.na.sorted.numeric[,!monorphic.snps]

# Calcular distancia
#gtseq.dist <- as.dist(1-cor(t(gtseq.na.sorted.numeric.polymorphic), use="pairwise.complete.obs"))
#gtseq.dist <- dist(gtseq.na.sorted.numeric.polymorphic, method="manhattan") gtseq.na
gtseq.dist <- dist(gtseq.na.sorted.numeric.polymorphic, method="manhattan")
mclust <- hclust(gtseq.dist, method="average")
#lab_order <- aperm(mclust$labels, mclust$order)
lab_order <- mclust$labels[mclust$order]
pdf(paste0(outputdir,"/dendograma.pdf"), width=5, height=5)
  par(cex=.7, mar=c(8, 6, 2, 1))
  plot(as.dendrogram(mclust, hang=-1),
       leaflab = "none", xlab="", ylab="TumorSec samples", sub="manhattan distance", horiz=T)
  mtext(lab_order, side=4, at=1:length(mclust$labels), las=2, cex=.2, line=-1)
dev.off()


# Exportar los IDs de mismatches
matched.samps <- cutree(mclust,  h = 3)
matched.samps.ls  <- tapply(names(matched.samps), as.factor(matched.samps), c)
matched.samps.ls.2 <- matched.samps.ls[sapply(matched.samps.ls , length)<3]
are_diff_fx <- function(x) {length(unique(sub("_.+$", "", x)))>1}
matched.samps.ls.2.arediff <- sapply(matched.samps.ls.2, are_diff_fx)
matched.samps.ls.2.diff <- matched.samps.ls.2[matched.samps.ls.2.arediff]

matched.samps.ls.2.df <- data.frame(GTseq=sapply(matched.samps.ls.2.diff, grep, pattern="GTSEQ", value=T),
                                    KASPar=sapply(matched.samps.ls.2.diff, grep, pattern="Kaspar", value=T))

matched.samps.ls.2.df$GTseq <- sub("_.*$", "", matched.samps.ls.2.df$GTseq)
matched.samps.ls.2.df$KASPar <- sub("_.*$", "", matched.samps.ls.2.df$KASPar)

#write.csv(matched.samps.ls.2.df, file="Real matching IDs between GTseq and KASPar.csv", row.names=F)


