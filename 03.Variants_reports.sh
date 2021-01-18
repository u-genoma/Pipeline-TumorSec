#!/bin/sh
############################
# Pipeline TumorSec V2.0 
# Evelin Gonzalez
#
# Date: 2019-25-04
# Descripción: Bash parte del pipeline de TumorSec, que genera un reporte de variantes.
###########################

#### LOAD INPUT DATA 
#PIPELINE_TUMORSEC="/home/egonzalez/workSpace/PipelineTumorSec"
#INPUT_DATA="${PIPELINE_TUMORSEC}/00.inputs_TumorSec.ini"

abort()
{
    echo >&2 '
***************
*** ABORTED ***
***************
'
    echo "An error occurred. Exiting..." >&2
    exit 1
}

trap 'abort' 0
#abort on error
#set -e

PARAMS=""
echo "1:$#"
while (( "$#" )); do
  case "$1" in
    -i|--input--dir)
      shift&&INDIR=$1
      echo "1:$#"
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

source $INPUT_DATA

get_samples(){
	cd "${INDIR}/${FASTQ}"
	echo $PWD
	#GET SAMPLES ID FROM FASTQ FILES
	SAMPLES=$(ls *R1_*.fastq.gz| awk '{split($0,array,"_")} {print array[1]"_"array[2]}')
}

get_samples
   	
#####################################
#                                   #
#       REPORT OF VARIANTS          #
#####################################

### GENERAR EXCEL POR MUESTRAS CON LOS LOS RESULTADOS DE ANNOVAR, RESULTADOS DEL CGI Y LAS REGIONES CON BAJA COBERTURA.

  if [ ! -d "${INDIR}/${VARIANTS_REPORT}" ]; then
                mkdir "${INDIR}/${VARIANTS_REPORT}"
        else
                echo "the ${INDIR}/${VARIANTS_REPORT} directory alredy exists"
        fi
  if [ ! -d "${INDIR}/${EXCEL}" ]; then
                mkdir "${INDIR}/${EXCEL}"
        else
                echo "the ${INDIR}/${EXCEL} directory alredy exists"
        fi
 if [ ! -d "${INDIR}/${REPORT_PDF}" ]; then
                mkdir "${INDIR}/${REPORT_PDF}"
        else
                echo "the ${INDIR}/${REPORT_PDF} directory alredy exists"
        fi
 if [ ! -d "${INDIR}/${SUMMARY_OUTPUTS}" ]; then
                mkdir "${INDIR}/${SUMMARY_OUTPUTS}"
        else
                echo "the ${INDIR}/${SUMMARY_OUTPUTS} directory alredy exists"
        fi
 if [ ! -d "${INDIR}/${IMAGES_REPORT}" ]; then
                mkdir "${INDIR}/${IMAGES_REPORT}"
        else
                echo "the ${INDIR}/${IMAGES_REPORT} directory alredy exists"
        fi
        
        ### MAKE PLOTS (MAFTOOLS) AND CSV WITH THE NUMBER OF VARIANTES PER SAMPLE
    	echo "Rscript $PLOTS_TABLAS_VARIANTES ${INDIR} $SAMPLE"
        Rscript $PLOTS_TABLAS_VARIANTES ${INDIR} $SAMPLES
        
        #### ALL SAMPLES VCF
		cd ${INDIR}/${ANNOVAR_ANOT}
    	echo "java -jar ${GATK} -T CombineVariants -R ${hg19_fa} \\" >> merge_command.sh
    	for i in $SAMPLES; do echo "--variant:${i} ${i}.annovar.hg19_multianno.vcf \\" >> merge_command.sh ; done
    	echo "-o ALL_SAMPLES.annovar.hg19_multianno.vcf -genotypeMergeOptions UNIQUIFY" >> merge_command.sh
    	sh merge_command.sh
    	rm merge_command.sh
        
        INPUT_VCF="${INDIR}/${ANNOVAR_ANOT}/ALL_SAMPLES.annovar.hg19_multianno.vcf"
        Rscript $PLOT_DP $INPUT_VCF ${INDIR}/${IMAGES_REPORT}
        
        CGI_OUTPUT="${INDIR}/${CGI}/list_CGI_MA_rename.txt"
        CGI_ANNOVAR_OUTPUT="${INDIR}/${SUMMARY_OUTPUTS}/Filtered_variantClass-ANNOVAR-CGI.tsv"
        VAR_GERM="${PIPELINE_TUMORSEC}/complement/List_IDvariante_Germinal_PipelineTumorSec.tsv"
        CGI_OUTPUT="${INDIR}/${CGI}/list_CGI_MA_rename.txt"
        
        find ${INDIR} -name "*mutation_analysis_rename.tsv" > ${CGI_OUTPUT}
        
        Rscript $CLASS_FILTER_ANNOVAR_CGI "${INDIR}/${SUMMARY_OUTPUTS}" "${INDIR}/${ANNOVAR_ANOT}" $VAR_GERM "${INDIR}/${EXCEL}/All_samples_clasificacion-variantes.xlsx" $CGI_OUTPUT
        
        Rscript $PLOTS_VAR_REPORT $CGI_ANNOVAR_OUTPUT "${INDIR}/${IMAGES_REPORT}"

        Rscript $CGI_MAF_ONCOPLOT $CGI_OUTPUT "${INDIR}/${IMAGES_REPORT}/" "${INDIR}/${CGI}" $AF $ExAC $DP_ALT
        
        #### MAKE PDF WITH THE VARIANTS REPORT
        echo "python $REPORTE_VARIANTES -i ${INDIR} -s $SAMPLES"
        python $REPORTE_VARIANTES -i $INDIR -s $SAMPLES --logo $LOGO --img $INDIR/$IMAGES_REPORT --outputpdf $INDIR/$REPORT_PDF --ocov $INDIR/$SUMMARY_OUTPUTS

        #### MAKE EXCEL FILE PER SAMPLE WITH THE INFORMATION OF ANNOVAR, CGI ANNOTATION AND REGION TARGETS COVERAGE
        for sample in $SAMPLES
		do
			INPUT_VCF="${INDIR}/${ANNOVAR_ANOT}/${sample}.annovar.hg19_multianno.vcf"
			INPUT_TXT="${INDIR}/${ANNOVAR_ANOT}/${sample}.annovar.hg19_multianno.txt"
			CSV_OUTPUT="${INDIR}/${SUMMARY_OUTPUTS}/${sample}_annovar.csv"
			CGI_DRUG_PRESC="${INDIR}/${CGI}/${sample}/drug_prescription.tsv"
			CGI_MUTATION="${INDIR}/${CGI}/${sample}/mutation_analysis.tsv"
			TARGET_FILE="${INDIR}/${OUTPUT_COV_TARGET}/${sample}_by_target_region.csv"
			EXCEL_OUTPUT="${INDIR}/${EXCEL}/${sample}.xlsx"
		
			#echo"Rscript $CSV_ANNOVAR $INPUT_VCF $INPUT_TXT $CSV_OUTPUT"
        	#Rscript $CSV_ANNOVAR $INPUT_VCF $INPUT_TXT $CSV_OUTPUT
        	echo "Rscript $MAKE_EXCEL $INPUT_TXT $CGI_DRUG_PRESC $CGI_MUTATION $TARGET_FILE"
        	Rscript $MAKE_EXCEL $INPUT_TXT $CGI_DRUG_PRESC $CGI_MUTATION $TARGET_FILE $EXCEL_OUTPUT
        done
        
trap : 0

echo >&2 '
##############
DONE-TumorSec 
##############
'
