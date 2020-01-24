#!/bin/sh
############################
# 
# Pipeline TumorSec V2.0 
# Evelin Gonzalez
# Date: 2019-25-04
# Descripción: Bash parte del pipeline de TumorSec, que genera un reporte de calidad de secuenciación.
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
set -e

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
    -b|--baseSpace)
      shift&&BASESPACE=$1
      #echo "2:$#"
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

    cd "${INDIR}/${FASTQ}"
	SAMPLES=$(ls *R1_*.fastq.gz| awk '{split($0,array,"_")} {print array[1]"_"array[2]}')

	 
#################################
#                               #
#            FASTQC             #
#################################
	
	cd "${INDIR}/${FASTQ}"

	zcat *L001_R1_001.fastq.gz > ALL_SAMPLES_L001_R1_001.fastq
	zcat *L001_R2_001.fastq.gz > ALL_SAMPLES_L001_R2_001.fastq
	
	fastqc ALL_SAMPLES_L001_R1_001.fastq
	fastqc ALL_SAMPLES_L001_R2_001.fastq
	
	unzip -o ALL_SAMPLES_L001_R1_001_fastqc.zip
	unzip -o ALL_SAMPLES_L001_R2_001_fastqc.zip
	
	rm ALL_SAMPLES_L001_R1_001_fastqc.zip
	rm ALL_SAMPLES_L001_R2_001_fastqc.zip
	
###########################################
#                                         #
#   QUALIMAP, MOSDEPTH, PICARD, SAMTOOLS  #
###########################################

	for sample in $SAMPLES
	do
		dedup_resorted_bam="${INDIR}/${DEDUP}/${sample}.resorted.bam"
		output_qualimap="${INDIR}/${DEDUP}/${sample}-qualimap"
		hs_metrics="${INDIR}/${DEDUP}/${sample}.hs_metrics.txt"
		output_mosdepth="${INDIR}/${DEDUP}/${sample}.mosdepth"
		output_ontarget="${INDIR}/${DEDUP}/${sample}.ontarget.txt"
		output_per_target_cov="${INDIR}/${DEDUP}/${sample}.target_coverage.txt"
                
        # QUALITY OF MAPPING (qualimap) #
        qualimap bamqc -bam $dedup_resorted_bam \
        -gff $qualimap_targets \
        -outdir $output_qualimap &

        # COVERAGE OF MAPPING (mosdepth) #
    	mosdepth -b $HG19_OncoChile_bed -T 100,200,300,400,500,600,700,800,900,1000 $output_mosdepth $dedup_resorted_bam &
		
		java -jar $PICARD CollectHsMetrics \
		I=$dedup_resorted_bam \
		O=$hs_metrics \
		R=$hg19_fa \
      	BAIT_INTERVALS=$TARGET_INTERVALS \
      	TARGET_INTERVALS=$TARGET_INTERVALS \
		PER_TARGET_COVERAGE=$output_per_target_cov

		intersectBed -a $dedup_resorted_bam -b $HG19_OncoChile_bed | samtools view -c - > $output_ontarget
		samtools view -c $dedup_resorted_bam >> $output_ontarget
	done

##############
#            #
#   MULTIQC  #
##############

        # MERGE OF REPORTS (multiqc)#
        cd ${INDIR}
        multiqc -f "${INDIR}" -p 

#####################################
#                                   #
#        CREATE DIRECTORIES         #
#####################################


  if [ ! -d "${INDIR}/${METRICS}" ]; then
                mkdir "${INDIR}/${METRICS}"
        else
                echo "the ${INDIR}/${METRICS} directory alredy exists"
        fi
  if [ ! -d "${INDIR}/${PLOTS}" ]; then
                mkdir "${INDIR}/${PLOTS}"
        else
                echo "the ${INDIR}/${PLOTS} directory alredy exists"
        fi
 if [ ! -d "${INDIR}/${REPORT}" ]; then
                mkdir "${INDIR}/${REPORT}"
        else
                echo "the ${INDIR}/${REPORT} directory alredy exists"
        fi
 if [ ! -d "${INDIR}/${OUTPUT_COV_TARGET}" ]; then
                mkdir "${INDIR}/${OUTPUT_COV_TARGET}"
        else
                echo "the ${INDIR}/${OUTPUT_COV_TARGET} directory alredy exists"
        fi

        
#####################################
#                              		# 
#  INTEROP (QUALITY OF SEQUENCING)  #
#####################################

		cd "${INDIR}/${OUTPUT_COV_TARGET}" 
		interop_summary "${BASESPACE}/Files" > interop_summary.tsv
		cd "${INDIR}/${PLOTS}"
		interop_plot_qscore_histogram "${BASESPACE}/Files" | gnuplot ##histogram
		interop_plot_qscore_heatmap "${BASESPACE}/Files"| gnuplot
		interop_plot_by_lane "${BASESPACE}/Files" | gnuplot
		interop_plot_by_cycle "${BASESPACE}/Files" | gnuplot
		 
		#DESMONTAR BASEMOUNT 
		#basemount --unmount $BASEMOUNT_DIR

#####################################
#                                   #
#   MAKE REPORTS  AND PLOTS         #
#####################################
        
        ######## GENERATE TABLES AND PLOTS
        python $PLOTS_TRIMMING -i $INDIR -o $INDIR/$PLOTS
        echo "python ${PLOTS_TRIMMING} -i ${INDIR} -o ${INDIR}/${PLOTS}"
        python $PLOTS_UNIFORMITY_AND_RANG -i $INDIR/$DEDUP -s $SAMPLES -o $INDIR/$PLOTS
        echo "python ${PLOTS_UNIFORMITY_AND_RANG} -i ${INDIR} -s $SAMPLES -o ${INDIR}/${PLOTS}"
        
        for sample in $SAMPLES
		do
			INPUT="${INDIR}/${DEDUP}/${sample}.mosdepth.thresholds.bed.gz"
			OUTPUT="${INDIR}/${PLOTS}"
			OUTPUT_CSV="${INDIR}/${OUTPUT_COV_TARGET}"
			Rscript $BY_REGION_PLOT $INPUT $OUTPUT $sample $OUTPUT_CSV
		done

		
		I="${INDIR}/${OUTPUT_COV_TARGET}/*_400X.csv"
		O="${INDIR}/${OUTPUT_COV_TARGET}/ALL_SAMPLES_400X.csv"
		
		
		if [ -f $O ]; then
    		rm $O
		fi
		
		cat $I > $O
		
        ######## COMPLEMENT REPORT 
        python $COMPLEMENT_REPORT -i $INDIR/$DEDUP -s $SAMPLES -opdf $INDIR/$REPORT -ocov $INDIR/$OUTPUT_COV_TARGET -l $LOGO -m $INDIR/$PLOTS

        ######## GENERATE REPORT OF RUN, WITH THE TABLES AND PLOTS
        echo "python $GENERAL_REPORT -i $INDIR -s $SAMPLES -opdf $INDIR/$REPORT -ocov $INDIR/$OUTPUT_COV_TARGET -l $LOGO -m $INDIR/$PLOTS"
        python $GENERAL_REPORT -i $INDIR -s $SAMPLES -opdf $INDIR/$REPORT -ocov $INDIR/$OUTPUT_COV_TARGET -l $LOGO -m $INDIR/$PLOTS -kit $KIT_SEC
                 
trap : 0

echo >&2 '
************
*** DONE *** 
************
'
