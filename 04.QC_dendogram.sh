#!/bin/sh
############################
# 
# Pipeline Calculo de distancia entre muestras V1.0 
# Evelin Gonzalez
# Date: 2019-09-09
#
# Descripcion: A partir de un archivo txt que contiene una lista de rutas absolutas de archivos .bam (una por linea)
# se calcula la distancia de manhatahn entre las diferentes muestras a partir de las variantes obtenidas por HaplotypeCaller
# 
# Ejemplo de ejecución: sh 01_quality_control_dendogram.sh -l /path/to/list_of_bam.txt -o path/to/output/directory -dp 250 -maf 0.05 -gm 0.5 -gs 0.8
#
# Los filtros por defecto que se realizan en este pipeline son los siguientes:
# 1) Solo SNV en regiones targets con una profundidad >=250.
# 3) Variantes con genotipado mayor 90% 
# 4) Muestras con genotipado mayor 50%
# 5) Se eliminaron los rsID con MAF < 0.05
# 6) Finalmente, se calcula la distancia de manhatan y se clusterizan los datos
#
############################

### INPUTS
#GATK="/opt/GenomeAnalysisTK.jar"
#hg19_fa="/datos/reference/Inputs_TumorSec/genome/hg19.fa"
#dbsnp_138_hg19="/datos/reference/Inputs_TumorSec/genome/dbsnp_138.hg19.vcf"
#HG19_OncoChile_bed="/datos/reference/Inputs_TumorSec/targets/180420_HG19_OncoChile_v1_EZ_primary_targets.bed"
#PICARD="/opt/picard.jar"
#TABULAR_GENOTIPOS="/home/egonzalez/workSpace/scripts/tabular_genotipos.py"


## OUTPUT DIRECTORY
HC="1_haplotypecaller"
VCF="2_vcfs"
PLINK="3_plink"
DENDO="4_dendogram"

abort()
{
    echo >&2'
***************
*** ABORTED ***
***************
'
    echo "An error occurred. Exiting..." >&2
    exit 1
}

trap 'abort' 0
#abort on error
set -e

PARAMS=""
echo "1:$#"
while (( "$#" )); do
  case "$1" in
     -o|--output-dir)
      shift&&OUTDIR=$1
      echo "2:$#"
      ;;
     -l|--list-bam)
       shift&&BAM=$1
       echo "3:$#"
      ;;
     -dp|--depth)
       shift&&DP=$1
       echo "3:$#"
      ;;
      -gs|--pct-gt-samples)
       shift&&PCT_GT_SAMPLES=$1 ## Porcentaje de genotipado por 50% por muestra
       echo "3:$#"
      ;;
      -maf|--maf)
       shift&&MAF=$1 ## Mínimo de frecuencia alélica del 5% para cada RSID
       echo "3:$#"
       ;;
      -gm|--pct-gt-snv) ## Porcentaje de genotipado del 90% por SNV (RSID).
       shift&&PCT_GT_SNV=$1
       echo "3:$#"
       ;;
       -e|--input--data)
       shift&&INPUT_DATA=$1
       #echo "6:$#"
      ;;
       --) # end argument parsing
       shift
       break
       ;;
       -*|--*=) # unsupported flags
       echo "Error: Unsupported flag $1" >&2
       exit 1
       ;;
       *) # preserve positional arguments
       PARAMS="$PARAMS $1"
       shift
       ;;
    esac
done
# set positional arguments in their proper place
eval set -- "$PARAMS"


FILES_BAM=$(cat $BAM )

source $INPUT_DATA
<<HOLA
####################################################
#                                                  #
# 1. RUN HAPLOTYPECALLER (GATK) AND RUN DP FILTER  #
####################################################

if [ ! -d "${OUTDIR}/${HC}" ]; then
                mkdir "${OUTDIR}/${HC}"
        else
                echo "The ${OUTDIR}/${HC} directory alredy exists"
        fi
        
	    #rm "${OUTDIR}/comand_dp.sh"
	    
		for file_bam in $FILES_BAM
		do
				bam_input=${file_bam##*/}
				sample=$(echo "$bam_input" | sed 's/.resorted.bam//g')
			
        		OUTFILE="${OUTDIR}/${HC}/${sample}_HC.g.vcf"
        		
        	     java -jar $GATK \
        		 -R $hg19_fa \
        		 -T HaplotypeCaller \
            	 -I $file_bam  \
        		 --dbsnp $dbsnp_138_hg19 \
        		 -L $HG19_OncoChile_bed \
        		 --emitRefConfidence GVCF \
           		 -o $OUTFILE
           		 
           		 INPUT=$OUTFILE
        		 OUTPUT="${OUTDIR}/${HC}/${sample}_HC_rename.g.vcf"
        		 
        		 ## add samples names
        		 java -jar $PICARD RenameSampleInVcf \
        		 INPUT=$INPUT \
        		 OUTPUT=$OUTPUT \
        		 NEW_SAMPLE_NAME=$sample
				 
				 ## dp filter fo variants
				 echo "Filtro DP $DP"
		         DP_select="'vc.getGenotype(\""$sample"\").getDP() > $DP'"
		         echo "$DP_select"
           		 echo "java -jar $GATK -T SelectVariants \
           		 -R $hg19_fa \
           		 -V $OUTPUT -select $DP_select \
           		 -o ${OUTDIR}/${HC}/${sample}.HC_rename_dp.g.vcf" >> ${OUTDIR}/comand_dp.sh
        done
        echo "Running DP filter of $DP for all samples"
        sh "${OUTDIR}/comand_dp.sh"

#######################################
#                                     #
# 2. MERGE GVCF (GATK GenotypeGVCFs)  #
#######################################

if [ ! -d "${OUTDIR}/${VCF}" ]; then
                mkdir "${OUTDIR}/${VCF}"
        else
                echo "The ${OUTDIR}/${VCF} directory alredy exists"
        fi
        
        #rm "$OUTDIR/$VCF/comand_merge_all_gVCF.sh"
        
        echo "java -jar $GATK -T GenotypeGVCFs -R $hg19_fa \\" > "$OUTDIR/$VCF/comand_merge_all_gVCF.sh"
        cd "${OUTDIR}/${HC}"
        
        echo "${OUTDIR}/${HC}"
        
		ls *HC_rename_dp.g.vcf | while read sample
        do
        		#aux=${sample##*/}
        		#echo $aux
				#sample_cut=$(echo "$aux" | sed 's/.HC_rename_dp.g.vcf//g')
				#echo $sample_cut
				echo "--variant $PWD/$sample \\" >> "${OUTDIR}/${VCF}/comand_merge_all_gVCF.sh"
		done
		
		echo "-o ${OUTDIR}/${VCF}/1_all_samples_TumorSec.vcf" >> "${OUTDIR}/${VCF}/comand_merge_all_gVCF.sh"
		
		echo "RUNING MERGE ALL GVCFs"
		sh "${OUTDIR}/${VCF}/comand_merge_all_gVCF.sh"


##################################
#                                #
# 3. ANNOTATE RSID FOR GVCF      #
##################################

			ALL_SAMPLES_VCF="${OUTDIR}/${VCF}/1_all_samples_TumorSec.vcf"
			ALL_SAMPLES_VCF_ANNOTATED="${OUTDIR}/${VCF}/2_all_samples_TumorSec_annotated.vcf"
			
			java -jar $GATK \
			-R $hg19_fa \
			-T VariantAnnotator \
			-V $ALL_SAMPLES_VCF \
			--dbsnp $dbsnp_138_hg19 \
			--out $ALL_SAMPLES_VCF_ANNOTATED 		

#############################################
#                                           #
# 4. SELECT INDELS AND DELETE MULTIALLELIC  #
#############################################

			ALL_SAMPLES_VCF_ANNOTATED_RSID="${OUTDIR}/${VCF}/3_all_samples_annotated_RSID.vcf"
			ALL_SAMPLES_VCF_ANNOTATED="${OUTDIR}/${VCF}/2_all_samples_TumorSec_annotated.vcf"
			
			java -jar $GATK \
			-R $hg19_fa \
			-T SelectVariants \
			--variant $ALL_SAMPLES_VCF_ANNOTATED \
			-selectType SNP \
			-o $ALL_SAMPLES_VCF_ANNOTATED_RSID 
			
			grep "^chr" $ALL_SAMPLES_VCF_ANNOTATED_RSID | awk -F "\t" '{if($3!=".") print $3}' > ${OUTDIR}/${VCF}/list_rsid.txt
			grep "^#" $ALL_SAMPLES_VCF_ANNOTATED_RSID > ${OUTDIR}/${VCF}/HEAD.txt
			grep "^chr" $ALL_SAMPLES_VCF_ANNOTATED_RSID | awk -F "\t" '{if($3!=".") print $0}' > ${OUTDIR}/${VCF}/BODY.txt
			cat ${OUTDIR}/${VCF}/HEAD.txt ${OUTDIR}/${VCF}/BODY.txt > ${OUTDIR}/${VCF}/4_all_samples_annotated_only_RSID.vcf

			
			echo ".................................."
			echo "Número de variantes con rsID:"
			cat ${OUTDIR}/${VCF}/list_rsid.txt | wc -l
			echo ".................................."
            
            FINAL_VCF="${OUTDIR}/${VCF}/4_all_samples_annotated_only_RSID.vcf"
			
			     
#############################################
#                                           #
# 5. GET GENOTYPES FOR ALL SAMPLES (PLINK)  #
#############################################

		if [ ! -d "${OUTDIR}/${PLINK}" ]; then
                mkdir "${OUTDIR}/${PLINK}"
        else
                echo "The ${OUTDIR}/${PLINK} directory alredy exists"
        fi
		
	   	plink1.9 --vcf $FINAL_VCF \
	   	--freq --out ${OUTDIR}/${PLINK}/freq_counts

	   
######################################
#                                    #
# 7. DELETE RSID WITH MAF < 0.05     #
######################################	   

  ## make list of rdID to Delete for MAF filter
  #DELETE RSID
  
        cat ${OUTDIR}/${PLINK}/freq_counts.frq | awk '{if($5<0.05) print $2}' > ${OUTDIR}/${VCF}/list_vcf_exclude.txt
        
        OUTPUT_VCF="${OUTDIR}/${VCF}/5_all_samples_annotated_only_RSID_MAF.vcf"
        FINAL_VCF="${OUTDIR}/${VCF}/4_all_samples_annotated_only_RSID.vcf"
        
        java -jar $GATK \
		-T SelectVariants \
		-R $hg19_fa \
		--variant $FINAL_VCF \
		--excludeIDs ${OUTDIR}/${VCF}/list_vcf_exclude.txt \
		-o $OUTPUT_VCF
        
  		plink1.9 --recode \
		--vcf $OUTPUT_VCF \
		--out ${OUTDIR}/${PLINK}/all_samples


################################
#                              #
# 8. CREATE GENOTYPE MATRIZ    #
################################
		source activate $PYTHON2_ENV
		python $TABULAR_GENOTIPOS ${OUTDIR}/${PLINK}/all_samples.ped > ${OUTDIR}/${PLINK}/SETPLINK.tsv
		awk '{print $2}' ${OUTDIR}/${PLINK}/all_samples.map | awk '{ORS=(NR?FS:RS)}1' | awk -v OFS="\t" '$1=$1' | awk '{print "Sample\t"$0}' > ${OUTDIR}/${PLINK}/SETPLINK.head

		cat ${OUTDIR}/${PLINK}/SETPLINK.head > ${OUTDIR}/${PLINK}/SETPLINK_2.tsv
		cat ${OUTDIR}/${PLINK}/SETPLINK.tsv >> ${OUTDIR}/${PLINK}/SETPLINK_2.tsv
        
        ### remplazar 00 por 0 en la matriz
        cat ${OUTDIR}/${PLINK}/SETPLINK_2.tsv | sed 's/00/0/g' > ${OUTDIR}/${PLINK}/SETPLINK_3.tsv
HOLA
#####################################
#                                   #
# 9. CREATE DENDOGRAM  AND PLOTS    #
#####################################

		if [ ! -d "${OUTDIR}/${DENDO}" ]; then
                mkdir "${OUTDIR}/${DENDO}"
        else
                echo "The ${OUTDIR}/${DENDO} directory alredy exists"
        fi       
        #INPUTS 1. MATRIZ OF GENO 2. % OF GENO FOR SNP 3. % OF GENO FOR SAMPLE 4. OUTOUTDIR
        echo "Rscript $GENERATE_DENDOGRAM ${OUTDIR}/${PLINK}/SETPLINK_3.tsv $PCT_GT_SNV $PCT_GT_SAMPLES ${OUTDIR}/${DENDO}"
        Rscript $GENERATE_DENDOGRAM ${OUTDIR}/${PLINK}/SETPLINK_3.tsv $PCT_GT_SNV $PCT_GT_SAMPLES ${OUTDIR}/${DENDO}
        
end_log "QC-Report-1" "quality-metrics"

echo "$(date) : step QC-Report-2 - finished - dendogram" >&3

        
trap : 0

echo >&2 '
************
*** DONE *** 
************
'
