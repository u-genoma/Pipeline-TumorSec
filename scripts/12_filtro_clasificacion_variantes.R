########################
#  Evelin Gonzalez Feliú
#  Descripcion:  Este programa forma parte del pipeline de TumorSec. A partir de la anotacion con annovar, cgi y 
#  la lista de variantes germinales, se realiza el filtro (MAF>1% en PDVs son eliminadas)  y clasificacion de variantes (somatica y germinal conocida o nueva)
#  Finalmente el dataframe resultado se almacena en un archivo  excel de salida.
#
## Se eliminan variantes con MAF sobre 1% en PDVs (popupation variant databases) GnomAD, ExAC, 1000G y ESP6500

##FUNCION 1: Elimnar variantes que presenten una AF poblacional sobre 1% en GnomAD (genomas y exomas), ExAC, ESP6550 y 1000G (en algunas de las subpoblaciones)
library(maftools)
library(dplyr)
library(tidyr)
library(writexl)
library(gtools)# smartbind


format_CGI<-function(x,colnames){
  CGI<-read.csv(x, header = T, sep = "\t")
  CGI_sorted <- CGI[sort(names(CGI))]
  CGI_sorted1<-subset(CGI_sorted,select = colnames)

  return(CGI_sorted1)
}


filtro_variantes<-function(protein_aff){
  protein_aff<-protein_aff %>%
    naniar::replace_with_na_if(.predicate = is.character,
                               condition = ~.x %in% ("."))
  AFpob<-protein_aff
  ##GnomAD GENOMA
  AFpob<-AFpob[as.numeric(AFpob$AF.1)<=0.01 | is.na(AFpob$AF.1),]
  AFpob<-AFpob[as.numeric(AFpob$AF_popmax.1)<=0.01 | is.na(AFpob$AF_popmax.1),]
  AFpob<-AFpob[as.numeric(AFpob$AF_male.1)<=0.01 | is.na(AFpob$AF_male.1),]
  AFpob<-AFpob[as.numeric(AFpob$AF_female.1)<=0.01 | is.na(AFpob$AF_female.1),]
  AFpob<-AFpob[as.numeric(AFpob$AF_raw.1)<=0.01 | is.na(AFpob$AF_raw.1),]
  AFpob<-AFpob[as.numeric(AFpob$AF_afr.1)<=0.01 | is.na(AFpob$AF_afr.1),]
  AFpob<-AFpob[as.numeric(AFpob$AF_sas.1)<=0.01 | is.na(AFpob$AF_sas.1),]
  AFpob<-AFpob[as.numeric(AFpob$AF_amr.1)<=0.01 | is.na(AFpob$AF_amr.1),]
  AFpob<-AFpob[as.numeric(AFpob$AF_eas.1)<=0.01 | is.na(AFpob$AF_eas.1),]
  AFpob<-AFpob[as.numeric(AFpob$AF_nfe.1)<=0.01 | is.na(AFpob$AF_nfe.1),]
  AFpob<-AFpob[as.numeric(AFpob$AF_fin.1)<=0.01 | is.na(AFpob$AF_fin.1),]
  AFpob<-AFpob[as.numeric(AFpob$AF_asj.1)<=0.01 | is.na(AFpob$AF_asj.1),]
  AFpob<-AFpob[as.numeric(AFpob$AF_oth.1)<=0.01 | is.na(AFpob$AF_oth.1),]
  AFpob<-AFpob[as.numeric(AFpob$non_topmed_AF_popmax.1)<=0.01 | is.na(AFpob$non_topmed_AF_popmax.1),]
  AFpob<-AFpob[as.numeric(AFpob$non_neuro_AF_popmax.1)<=0.01 | is.na(AFpob$non_neuro_AF_popmax.1),]
  AFpob<-AFpob[as.numeric(AFpob$non_cancer_AF_popmax.1)<=0.01 | is.na(AFpob$non_cancer_AF_popmax.1),]
  
  #GnomAD EXOMA
  AFpob<-AFpob[as.numeric(AFpob$AF)<=0.01 | is.na(AFpob$AF),]
  AFpob<-AFpob[as.numeric(AFpob$AF_popmax)<=0.01 | is.na(AFpob$AF_popmax),]
  AFpob<-AFpob[as.numeric(AFpob$AF_male)<=0.01 | is.na(AFpob$AF_male),]
  AFpob<-AFpob[as.numeric(AFpob$AF_female)<=0.01 | is.na(AFpob$AF_female),]
  AFpob<-AFpob[as.numeric(AFpob$AF_raw)<=0.01 | is.na(AFpob$AF_raw),]
  AFpob<-AFpob[as.numeric(AFpob$AF_afr)<=0.01 | is.na(AFpob$AF_afr),]
  AFpob<-AFpob[as.numeric(AFpob$AF_sas)<=0.01 | is.na(AFpob$AF_sas),]
  AFpob<-AFpob[as.numeric(AFpob$AF_amr)<=0.01 | is.na(AFpob$AF_amr),]
  AFpob<-AFpob[as.numeric(AFpob$AF_eas)<=0.01 | is.na(AFpob$AF_eas),]
  AFpob<-AFpob[as.numeric(AFpob$AF_nfe)<=0.01 | is.na(AFpob$AF_nfe),]
  AFpob<-AFpob[as.numeric(AFpob$AF_fin)<=0.01 | is.na(AFpob$AF_fin),]
  AFpob<-AFpob[as.numeric(AFpob$AF_asj)<=0.01 | is.na(AFpob$AF_asj),]
  AFpob<-AFpob[as.numeric(AFpob$AF_oth)<=0.01 | is.na(AFpob$AF_oth),]
  AFpob<-AFpob[as.numeric(AFpob$non_topmed_AF_popmax)<=0.01 | is.na(AFpob$non_topmed_AF_popmax),]
  AFpob<-AFpob[as.numeric(AFpob$non_neuro_AF_popmax)<=0.01 | is.na(AFpob$non_neuro_AF_popmax),]
  AFpob<-AFpob[as.numeric(AFpob$non_cancer_AF_popmax)<=0.01 | is.na(AFpob$non_cancer_AF_popmax),]
  
  ## 1000 GENOMAS
  AFpob<-AFpob[as.numeric(AFpob$esp6500siv2_all)<=0.01 | is.na(AFpob$esp6500siv2_all),]
  AFpob<-AFpob[as.numeric(AFpob$AFR.sites.2015_08)<=0.01 | is.na(AFpob$AFR.sites.2015_08),]
  AFpob<-AFpob[as.numeric(AFpob$AMR.sites.2015_08)<=0.01 | is.na(AFpob$AMR.sites.2015_08),]
  AFpob<-AFpob[as.numeric(AFpob$EAS.sites.2015_08)<=0.01 | is.na(AFpob$EAS.sites.2015_08),]
  AFpob<-AFpob[as.numeric(AFpob$EUR.sites.2015_08)<=0.01 | is.na(AFpob$EUR.sites.2015_08),]
  AFpob<-AFpob[as.numeric(AFpob$SAS.sites.2015_08)<=0.01 | is.na(AFpob$SAS.sites.2015_08),]
  ## ExAC
  AFpob<-AFpob[as.numeric(AFpob$ExAC_ALL)<=0.01 | is.na(AFpob$ExAC_ALL),]
  AFpob<-AFpob[as.numeric(AFpob$ExAC_AFR)<=0.01 | is.na(AFpob$ExAC_AFR),]
  AFpob<-AFpob[as.numeric(AFpob$ExAC_AMR)<=0.01 | is.na(AFpob$ExAC_AMR),]
  AFpob<-AFpob[as.numeric(AFpob$ExAC_EAS)<=0.01 | is.na(AFpob$ExAC_EAS),]
  AFpob<-AFpob[as.numeric(AFpob$ExAC_FIN)<=0.01 | is.na(AFpob$ExAC_FIN),]
  AFpob<-AFpob[as.numeric(AFpob$ExAC_NFE)<=0.01 | is.na(AFpob$ExAC_NFE),]
  AFpob<-AFpob[as.numeric(AFpob$ExAC_OTH)<=0.01 | is.na(AFpob$ExAC_OTH),]
  AFpob<-AFpob[as.numeric(AFpob$ExAC_SAS)<=0.01 | is.na(AFpob$ExAC_SAS),]
  
  ##ESP6500
  AFpob<-AFpob[as.numeric(AFpob$esp6500siv2_all)<=0.01 | is.na(AFpob$esp6500siv2_all),] ##PAPER TUMORSEC: PVDS 245
  AFpob$ID_variante<-paste(AFpob$Start_Position,AFpob$Reference_Allele,AFpob$Tumor_Seq_Allele2,sep='|')
  
  ## Se retorna el dataframe con las variantes que pasaron los filtros.
  return(AFpob)
}

clasificacion_variantes<-function(AFpob, path_output, VAR_GERM){
  
  #FILTRO 2: CLASIFICACIÓN DE VARIANTES.
  ##FILTRO 2.1: Variantes encontradas en muestras de BC son clasificadas como variantes germinal  
  AFpob$clasificacion[AFpob$ID_variante %in% VAR_GERM]<-"Germinal"
  AFpob$motivo[AFpob$ID_variante %in% VAR_GERM]<-"variante_en_BC"

  ## FILTRO 2.2: Variantes no clasificadas y con Cosmic ID son clasificadas como somáticas
  AFpob$clasificacion[is.na(AFpob$clasificacion) & !is.na(AFpob$cosmic92)]<-"Somatica"
  AFpob$motivo[ AFpob$clasificacion=="Somatica" & !is.na(AFpob$cosmic92)]<-"CosmicID"

  ## FILTRO 2.3: Variantes no clasificadas y con ID en snp138NonFlagged  es clasificada como germinal
  ## snp138nonflagged: Si la variante tiene RSID, en la columna 
  ## snp138nonflagged ((flagged variants are those for which SNPs <1% MAF (or unknown), mapping only once to reference assembly, or flagged as “clinically associated”).)
  AFpob$clasificacion[ is.na(AFpob$clasificacion) & !is.na(AFpob$snp138NonFlagged)]<-"Germinal1"
  AFpob$motivo[ AFpob$clasificacion=="Germinal1" & !is.na(AFpob$snp138NonFlagged)]<-"snp138NonFlagged"
  AFpob$clasificacion[ AFpob$clasificacion=="Germinal1"]<-"Germinal"

  ## FILTRO 2.5: Variantes no clasificadas y con etiqueta Benign/Likely_benign en CLINVAR, son clasificadas como germinal
  AFpob$clasificacion[ is.na(AFpob$clasificacion) & (AFpob$CLNSIG=="Likely_benign" | AFpob$CLNSIG=="Benign" | AFpob$CLNSIG=="Benign/Likely_benign")]<-"Germinal1"
  AFpob$motivo[ AFpob$clasificacion=="Germinal1" & (AFpob$CLNSIG=="Likely_benign" | AFpob$CLNSIG=="Benign" | AFpob$CLNSIG=="Benign/Likely_benign")]<-"CLINVAR_Benign"
  AFpob$clasificacion[ AFpob$clasificacion=="Germinal1"]<-"Germinal"

  ## FILTRO 2.4: Variantes no clasificadas y con ID en avsnp150 y con AF en ExAC_nontcga_ALL es clasificada como variantes germinal
  AFpob$clasificacion[ is.na(AFpob$clasificacion) & !is.na(AFpob$avsnp150) & !is.na(AFpob$ExAC_nontcga_ALL)]<-"Posible_Germinal"
  AFpob$motivo[ AFpob$clasificacion=="Posible_Germinal" & !is.na(AFpob$avsnp150) & !is.na(AFpob$ExAC_nontcga_ALL)]<-"avsnp150_AND_ExAC_nontcga_ALL"

  ## FILTRO 3.6: Variantes no clasificadas y con ID en avsnp150, es clasificada como posible somatica
  AFpob$clasificacion[is.na(AFpob$clasificacion) & !is.na(AFpob$avsnp150) & as.numeric(AFpob$VAF)<=0.60]<-"Posible_Somatica"
  AFpob$motivo[ AFpob$clasificacion=="Posible_Somatica" & !is.na(AFpob$avsnp150)]<-"avsnp150_VAFlow0.6"

  AFpob$clasificacion[is.na(AFpob$clasificacion) & !is.na(AFpob$avsnp150) & as.numeric(AFpob$VAF)>0.60]<-"Posible_Germinal1"
  AFpob$motivo[AFpob$clasificacion=="Posible_Germinal1" & !is.na(AFpob$avsnp150)]<-"avsnp150_VAFover0.6"
  AFpob$clasificacion[ AFpob$clasificacion=="Posible_Germinal1"]<-"Posible_Germinal"

  ## FILTRO 3.7 Variantes con AF muy bajas en Bases de datos de frecuencias alélicas poblacionales, menor < 0.01, son clasificadas como posibles somáticas. 
  AFpob$clasificacion[is.na(AFpob$clasificacion) & (!is.na(AFpob$ExAC_ALL) | !is.na(AFpob$AF_popmax) | !is.na(AFpob$AF_popmax.1) | !is.na(AFpob$AMR.sites.2015_08) | !is.na(AFpob$CLNDN))]<-"PVDs"
  AFpob$motivo[AFpob$clasificacion=="PVDs" & as.numeric(AFpob$VAF)>0.60]<-"PDVs_VAFover0.6"
  AFpob$motivo[AFpob$clasificacion=="PVDs" & as.numeric(AFpob$VAF)<=0.60]<-"PDVs_VAFlow0.6"
  AFpob$clasificacion[AFpob$motivo=="PDVs_VAFover0.6"]<-"Posible_Germinal"
  AFpob$clasificacion[AFpob$motivo=="PDVs_VAFlow0.6"]<-"Posible_Somatica"

  ## Filtro 3.2 variantes con VAF entre 0.60-1, son clasificadas como germinal. 
  AFpob$clasificacion[is.na(AFpob$clasificacion) & as.numeric(AFpob$VAF)>=0.60]<-"Posible_Germinal_Novel"
  AFpob$motivo[AFpob$clasificacion=="Posible_Germinal_Novel" & as.numeric(AFpob$VAF)>=0.60]<-"Sin_info_BDs_VAF_over0.60"
  
  ## FILTRO 3.7: Aquellas variantes sin informacion en Bases de datos, son clasificadas como posibles variantes somáticas novel.
  AFpob$clasificacion[is.na(AFpob$clasificacion)]<-"Posible_Somatica_Novel"
  AFpob$motivo[AFpob$clasificacion=="Posible_Somatica_Novel"]<-"Sin_info_BDs_VAF_low0.60"
  
  ## CUENTO CUANTES VECES ESTA LA VARIANTES EN EL SET DE DATOS
  n_veces_IDvariante<-AFpob %>%                       
    group_by(ID_variante) %>%       
    tally()
  ### juntamos el dataframe con las variantes clasificadas mas el que contiene el numero de veces de la variante en el set de datos.
  AFpob_merge<-merge(AFpob,n_veces_IDvariante)
  
  AFpob_merge$clasificacion[(AFpob_merge$clasificacion=="Posible_Somatica_Novel" | AFpob_merge$clasificacion=="Posible_Somatica") & AFpob_merge$n>3]<-"Posible_Germinal1"
  AFpob_merge$motivo[AFpob_merge$clasificacion=="Posible_Germinal1" & AFpob_merge$n>3]<-"Var_mas_3_muestras"
  AFpob_merge$clasificacion[AFpob_merge$clasificacion=="Posible_Germinal1"]<-"Posible_Germinal"

  return(AFpob_merge)
}

## FUNCION N_clasificacion  OUTPUT: TABLA CON NÚMERO DE VARIANTES POR CLASIFICACIÓN
N_clasificacion<-function(dataframe.variantes,path_output){
  
  n_veces_clasificacion<-dataframe.variantes %>%                       
    group_by(clasificacion) %>%       
    tally()
  
  dedup<-dataframe.variantes[!duplicated(dataframe.variantes$ID_variante),]
  
  n_veces_clasificacion_dedup<-dedup %>%                       
    group_by(clasificacion) %>%       
    tally()
  
  N_by_clasificacion<-merge(n_veces_clasificacion_dedup,n_veces_clasificacion, by="clasificacion",suffixes = c(".unicas",".totales"))
  N_by_clasificacion <- rbind(N_by_clasificacion, c("Total", sum(N_by_clasificacion$n.unicas),sum(N_by_clasificacion$n.totales)))
  write.table(N_by_clasificacion,file = paste0(path_output,"/summary_variantClass.tsv"), sep ='\t', quote=FALSE, row.names = F)
  return(N_by_clasificacion)
}

##FUNTION: sea crea solo un dataframe que contenga resultados de cgi y annovar.
merge_cgi_annovar<-function(dataframe.annovar,dataframe.cgi){

  ## construimos id_merge para el dataframe.cgi
  dataframe.cgi$id_merge<-paste(dataframe.cgi$sample,dataframe.cgi$pos, dataframe.cgi$ref,dataframe.cgi$alt,sep="|")
  ## construimos id_merge para el dataframe.annovar
  dataframe.annovar$id_merge<-paste(dataframe.annovar$Tumor_Sample_Barcode,dataframe.annovar$V136,dataframe.annovar$V138,dataframe.annovar$V139,sep="|")
  
  ## juntamos los datos. 
  merge.cgi.annovar<-merge(dataframe.annovar,dataframe.cgi, by="id_merge",all = TRUE)
  return(merge.cgi.annovar)
}

## MAIN 
## Rscript 12_filtro_clasificacion_variantes.R /path/output/ path/annovar path/file/germline
args <- commandArgs(trailingOnly = TRUE)

print(args)
path_output=args[1]
path_annovar=args[2]
file_germline=args[3]
output_Excel=args[4]
list_CGI_inputs=args[5]

#path_output="/Users/evelin/Documents/9-12-20-Test_scripts_ClassVar_PipelineTumorSec/New_variant_report/plots_and_tables/" ##args[1]
#path_annovar="/Users/evelin/Documents/9-12-20-Test_scripts_ClassVar_PipelineTumorSec/New_variant_report/annovar/" #args[2] ##
#file_germline="/Users/evelin/Documents/9-12-20-Test_scripts_ClassVar_PipelineTumorSec/List_IDvariante_Germinal_PipelineTumorSec.tsv"#args[3]
#file_cgi="/Users/evelin/Documents/9-12-20-Test_scripts_ClassVar_PipelineTumorSec/New_variant_report/cgi_analysis181_results/mutation_analysis2.tsv" # args[4]

## Variantes germinales. 
annovar_germ.all<-read.csv(file_germline, header = T, sep = "\t")
VAR_GERM<-unique(annovar_germ.all$ID_variante)


## Crear dataframe con las anotación (ANNOVAR) de todas las muestras.
filenames <- Sys.glob(paste0(path_annovar,"/*.hg19_multianno.txt"))
annovar_mafs = lapply(filenames, annovarToMaf) #convert to MAFs using annovarToMaf
annovar_mafs = data.table::rbindlist(l = annovar_mafs, fill = TRUE) #Merge into single MAF
colnames(annovar_mafs) <- make.unique(names(annovar_mafs))

annovar_mafs<- annovar_mafs %>% separate(V144, c("GT","DP4","CD4","refMQ","altMQ","refBQ","altBQ","refNM","altNM","fetSB","fetCD","zMQ","zBQ","MQ0","VAF"),"[:]")
annovar_mafs<- annovar_mafs %>% separate(DP4 , c("DP_REF1","DP_REF2","DP_ALT1", "DP_ALT2"), "[,]")
annovar_mafs$DP_ALT<-as.numeric(as.character(annovar_mafs$DP_ALT1)) + as.numeric(as.character(annovar_mafs$DP_ALT2))
annovar_mafs$DP_REF<-as.numeric(as.character(annovar_mafs$DP_REF1)) + as.numeric(as.character(annovar_mafs$DP_REF2))
annovar_mafs<- annovar_mafs %>% separate(V142, c("VAF","MVDLPK","NUM_TOOLS"), "[;]")
annovar_mafs$VAF<- gsub('AF=','', annovar_mafs$VAF)
annovar_mafs$MVDLPK<- gsub('MVDLPK=','', annovar_mafs$MVDLPK)
annovar_mafs$MVDLPK<- gsub('MVDLK=','', annovar_mafs$MVDLPK)
annovar_mafs$NUM_TOOLS<- gsub('NUM_TOOLS=','', annovar_mafs$NUM_TOOLS)
annovar_mafs.sep.af<-annovar_mafs[annovar_mafs$DP_ALT>=12 & annovar_mafs$VAF >=0.05,]

###SOLO CONSERVAMOS LAS MUTACIONES QUE AFECTAN A LA PROTEÍNA.
annovar_mafs.sep.af.pro<-annovar_mafs.sep.af[(annovar_mafs.sep.af$Variant_Classification=="Missense_Mutation" |
                                                annovar_mafs.sep.af$Variant_Classification=="Splice_Site" |
                                                annovar_mafs.sep.af$Variant_Classification=="In_Frame_Del" |
                                                annovar_mafs.sep.af$Variant_Classification=="Frame_Shift_Ins" |
                                                annovar_mafs.sep.af$Variant_Classification=="Nonsense_Mutation" |
                                                annovar_mafs.sep.af$Variant_Classification=="Frame_Shift_Del" | 
                                                annovar_mafs.sep.af$Variant_Classification=="In_Frame_Ins"),]

## FUNCION: filtro de variantes.
protein_aff_filtered<-filtro_variantes(annovar_mafs.sep.af.pro)
## FUNCION: clasificacion de variantes. Guarda dataframe final en archivo de salida.
protein_aff_filtered_class<-clasificacion_variantes(protein_aff_filtered,path_output,VAR_GERM)
N_by_clasificacion<-N_clasificacion(protein_aff_filtered_class,path_output)



## MERGE ANOTACION, CGI.
CGIs<-read.csv(list_CGI_inputs, header = F, sep = "\t")

colnames<-c("alt_type","cadd_phred","cancer","cdna","consequence","disrupting_driver_mut_prediction","driver","driver_gene","driver_gene_source",             
           "driver_mut_prediction","driver_statement","exac_af","exon","gdna","gene","gene_role","inframe_driver_mut_prediction","input","is_in_cluster","is_in_delicate_domain","known_match","known_neutral","known_neutral_reference","known_neutral_source","known_oncogenic","known_oncogenic_reference","known_oncogenic_source","known_predisposing","known_predisposing_reference","known_predisposing_source","known_variant_reference","known_variant_source","missense_driver_mut_prediction","mutation_location","Pfam_domain","protein","protein_change","protein_pos","region","strand","transcript","transcript_aminoacids","transcript_exons","sample" )

for (i in 1:nrow(CGIs)){
  aux<-format_CGI(as.character(CGIs[i,1]),colnames)

  if(i!=1){
  all.data.cgi<-rbind(all.data.cgi,aux)
  }
  else{
  all.data.cgi<-aux
  }
}

aux<-data.frame(protein_aff_filtered_class)
aux$V135<- gsub('chr','',aux$V135)
protein_aff_filtered_class$id_merge<-paste0(aux$Tumor_Sample_Barcode,"|",aux$V135,"|",aux$V136,"|",aux$V138,"|",aux$V139)

all.data.cgi$id_merge<-paste(all.data.cgi$sample,all.data.cgi$input,sep="|")
#print(protein_aff_filtered_class$id_merge)
#print(all.data.cgi$id_merge)
df.merge.cgi.annovar<-merge(protein_aff_filtered_class,all.data.cgi,by="id_merge",all.x =TRUE)

write.table(df.merge.cgi.annovar,file = paste0(path_output,"/Filtered_variantClass-ANNOVAR-CGI.tsv"), sep ='\t', quote=FALSE, row.names = F)
## EXCEL CON RESULTADOS.
sheets <- list("1_Variantes_filt_class"=df.merge.cgi.annovar,"2_Num_por_clasificacion" = N_by_clasificacion) #assume sheet1 and sheet2 are data frames
write_xlsx(sheets,output_Excel)


