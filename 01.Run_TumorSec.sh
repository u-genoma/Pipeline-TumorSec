#!/bin/sh -x
############################
# 
# Pipeline TumorSec V2.0 
# Evelin Gonzalez
#
# Date: 2019-25-04
# Descripción: A partir de archivos fastq, este pipeline
# identifica las mutaciones somaticas SNVs e Indels. 
# ademas de una anotación funcional de las variantes identificadas.
# EXAMPLE: Comando: sh 01.Run_TumorSec.sh --input--dir ${INDIR} --threads ${THREAD} --baseSpace ${BASESPACE} --dendogram ${DENDOGRAM} --step ${STEP} --input--data ${INPUT_DATA}
############################

#### LOAD INPUT DATA
### SI OCURRE ALGUN ERROR DENTRO EL PIPELINE, ESTE SE DETIENE.

PIPELINE_TUMORSEC="/home/egonzalez/workSpace/PipelineTumorSec"


abort()
{
    echo >&3 '
***************
*** ABORTED ***
***************
'
    echo "An error occurred. Exiting..." >&3
    exit 1
}
trap 'abort' 0
#abort on error
set -e
#set -o errexit

### PARAMETROS DE ENTRADAS A TRAVES DE LINEA DE COMANDOS
PARAMS=""
#echo "1:$#"
while (( "$#" )); do
  case "$1" in
    -i|--input--dir)
      shift&&INDIR=$1
      #echo "1:$#"
      ;;
      -b|--baseSpace)
      shift&&BASESPACE=$1
      #echo "2:$#"
      ;;
    -t|--threads)
       shift&&THREAD=$1
       #echo "3:$#"
      ;;
    -d|--dendogram)
       shift&&DENDOGRAM=$1
       #echo "4:$#"
      ;;
    -s|--step)
       shift&&STEP=$1
       #echo "5:$#"
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
      echo "Error: Unsupported flag $1" >&3
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

if [ -z "$INDIR" ]; then
	echo ""
	echo "Enter the output directory:"
	read INDIR
fi

if [ -z "$BASESPACE" ]; then
	echo ""
	echo "Enter the BaseSpace directory:"
	read BASESPACE
fi

if [ -z "$STEP" ]; then
	echo ""
	echo "What steps do you want to execute?"
	echo "0. Demultiplexing"
	echo "1. Trimming"
	echo "2. Mapping"
	echo "3. Remove duplicates - QC report"
	echo "4. Realign of indels"
	echo "5. Recalibration" 
	echo "6. Varcall"
	echo "7. Annotation - Variants report"
	echo "8. Filter vcf (RGO Input)"
	echo "Example, all pipeline -> 0-8, only varcall -> 6, from trimming to realignment -> 1-4"
	read STEP
fi

if [ -z "$DENDOGRAM" ]; then	
	echo ""
	echo "Build sample dendogram (y / n)"
	read DENDOGRAM
fi

if [ -z "$THREAD" ]; then
	echo ""
	echo "Threads:"
	read THREAD
fi

if [ -z "$INPUT_DATA" ]; then
	echo ""
	echo "Enter input parameters (path) or by default (0):"
	read INPUT_DATA
fi

#### CARGAR VARIABLES Y DATOS DE ENTRADA 
if [ "$INPUT_DATA" -eq 0 ]; then

    INPUT_DATA="${PIPELINE_TUMORSEC}/00.inputs_TumorSec.ini"
	source $INPUT_DATA
else 
	source $INPUT_DATA
fi

## agregar log por paso. (funcion), cambiar entrada de pasos. agregar comandos al log. poner tiempo por paso ejecutado.
echo ""
echo "############################################"
echo "     Welcome to the TumorSec pipeline      "
echo "############################################"
echo ""
echo "== Search for somatic variants with oncological importance =="
echo "Developed by the Laboratory of Genomics of Cancer and GENOMELAB, School of Medicine. University of Chile"
echo ""
echo "Comando: sh ${PIPELINE_TUMORSEC}/01.Run_TumorSec.sh --input--dir ${INDIR} --threads ${THREAD} --baseSpace ${BASESPACE} --dendogram ${DENDOGRAM} --step ${STEP} --input--data ${INPUT_DATA}" 
echo ""   	

#set -xv
#trap read debug  

#### función de creación de log por cada paso del pipeline
#0 - stdin
#1 - stdout
#2 - stderr

exec 3>&1 4>&2

### funcion que revise que esta todo bien antes de correr el siguiente paso.
# en caso que no sea asi¡, debe enviar un mensaje de error.

step(){

	STEP=$1
 	START=$(echo $STEP | awk -F "-" '{print $1}')
	END=$(echo $STEP | awk -F "-" '{print $2}')

	if [ -z "$END" ]; then
		END=$START
	fi
	
	if (( $START > $END )); then
		echo "Error: The ${START} must by less than ${END} in step parameter ${STEP}" >&3
		exit
	fi
}

start_log(){
	n_step=$1
	string_step=$2
	
	if [ ! -d "${INDIR}/${LOG}" ]; then 
		mkdir "${INDIR}/${LOG}"
	fi
	
	log_output="${INDIR}/${LOG}/${n_step}_log_${string_step}.out"
	echo "$(date) : step ${n_step} - start - ${string_step}" >&3
	echo "$(date) : step ${n_step} - logfile - ${log_output}" >&3
	exec 1>$log_output 2>&1
}

end_log(){
	n_step=$1
	string_step=$2
	echo "$(date) : step ${n_step} - finished - ${string_step}" >&3
	echo "##############"
	echo "DONE-TumorSec"
	echo "##############"
}

check_log(){

	n_step=$1
	string_step=$2
	log_output="${INDIR}/${LOG}/${n_step}_log_${string_step}.out"

	## Si existe el archivo, se debe buscar el string "DONE-TuumorSec" en el log
	if [ ! -f "${log_output}" ]; then
           echo "$(date) : ## Error ## - file ${log_output} not found"
           exit
    fi
	check=$(grep "DONE-TumorSec" $log_output | wc -l)
	
	if (($check == 0)); then
		echo "$(date): ## Error ## - Step ${n_step} ${string_step} with error, it don't finished." >&3
		echo "$(date): ## Error ## - Check log : ${log_output}"
		exit
	fi 
}

get_samples(){
	cd "${INDIR}/${FASTQ}"
	echo $PWD
	#GET SAMPLES ID FROM FASTQ FILES
	SAMPLES=$(ls *R1_*.fastq.gz| awk '{split($0,array,"_")} {print array[1]"_"array[2]}')
}

step $STEP

####################################
#                                  #
#   DEMULTIPLEXING (BCL2FASTQ)     #
####################################


if (( $START == 0 )); then

start_log 0 "demultiplexing"

	if [ ! -d "${INDIR}/${FASTQ}" ]; then 
		mkdir "${INDIR}/${FASTQ}"
	else 
		echo "The ${INDIR}/${FASTQ} directory alredy exists"
    fi
    
    bcl2fastq -R "${BASESPACE}/Files" -o $INDIR/$FASTQ  
      
end_log 0 "demultiplexing"

fi

#################################
#                               #
#   TRIMMING OF DATA (FASTP)    #
#################################


if (( $START <= 1 )) && (( $END >= 1 )); then 

check_log 0 "demultiplexing"
start_log 1 "trimming"
get_samples

	if [ ! -d "${INDIR}/${TRIM}" ]; then
   		mkdir "${INDIR}/${TRIM}"
	else 
		echo "The ${INDIR}/${TRIM} directory alredy exists"
   	fi
   		
	for sample in $SAMPLES
	do
   		echo "Running fastp for $sample"
		fastq_R1="${INDIR}/${FASTQ}/${sample}_L001_R1_001.fastq.gz"
		fastq_R2="${INDIR}/${FASTQ}/${sample}_L001_R2_001.fastq.gz"
		trimmed_R1="${INDIR}/${TRIM}/${sample}_trimmed_R1.fastq.gz"
		trimmed_R2="${INDIR}/${TRIM}/${sample}_trimmed_R2.fastq.gz"
		output_json="${INDIR}/${TRIM}/${sample}_fastp.json"
		output_log="${INDIR}/${TRIM}/${sample}.log"
		
		### COMAND TO RUN FASTP
   		nice -n 11 fastp \
		-q $qual \
		-l $large \
		-5 -3 -M 20 -W $window \
		-i $fastq_R1 \
		-I $fastq_R2 \
		-o $trimmed_R1 \
		-O $trimmed_R2 \
		-j $output_json > $output_log #" >> "${INDIR}/comands_fastp.txt"
	done
	#run fastp in parallel for all samples	
	#cat "${INDIR}/comands_fastp.txt"| parallel -j $THREAD --tmpdir $TMP
	#rm "${INDIR}/comands_fastp.txt"
	
end_log 1 "trimming"

fi

#################################
#								#
#    MAPPING OF READS (BWA)     #
#################################

if (( $START <= 2 )) && (( $END >= 2 )); then

check_log 1 "trimming"
start_log 2 "mapping"
get_samples

	if [ ! -d "${INDIR}/${MAPPING}" ]; then
                mkdir "${INDIR}/${MAPPING}"
        else
                echo "The ${INDIR}/${MAPPING} directory alredy exists"
    fi
    
	for sample in $SAMPLES
	do	
		echo "Running bwa for $sample"
        mapping_sam="${INDIR}/${MAPPING}/${sample}.sam"
  		mapping_bam="${INDIR}/${MAPPING}/${sample}.bam"
		fastq_trimmed_R1="${INDIR}/${TRIM}/${sample}_trimmed_R1.fastq.gz"
		fastq_trimmed_R2="${INDIR}/${TRIM}/${sample}_trimmed_R2.fastq.gz"
		sorted_bam="${INDIR}/${MAPPING}/${sample}.sorted.bam"
		
		echo "time nice -n 11  bwa mem \
		-t $THREAD \
		-R \"@RG\tID:foo\tSM:tumor\tPL:Illumina\tPU:unit1\tLB:lib1\" \
		$hg19_fa \
		$fastq_trimmed_R1 \
		$fastq_trimmed_R2 > $mapping_sam"
		
		#work in parallel, quitar el echo
		time nice -n 11  bwa mem \
		-t $THREAD \
		-R "@RG\tID:foo\tSM:tumor\tPL:Illumina\tPU:unit1\tLB:lib1" \
		$hg19_fa \
		$fastq_trimmed_R1 \
		$fastq_trimmed_R2 > $mapping_sam
		           
		#work in parallel
        samtools view -@ $THREAD -bS $mapping_sam > $mapping_bam
		samtools sort -@ $THREAD -o $sorted_bam -O BAM $mapping_bam
		#don't work in parallel
		samtools index $sorted_bam
	done
	
end_log 2 "mapping"

fi

#################################
#                               #
#  DELETE DUPLICATES (PICARD)   #
#################################

if (( $START <= 3 )) && (( $END >= 3 )); then

check_log 2 "mapping"
start_log 3 "remove-Duplicates"
get_samples

	if [ ! -d "${INDIR}/${DEDUP}" ]; then
                mkdir "${INDIR}/${DEDUP}"
    else
                echo "The ${INDIR}/${DEDUP} directory alredy exists"
    fi
   
	for sample in $SAMPLES
	do      
		echo "Running PICARD MarkDuplicates for $sample"
		mapped_sorted_bam="${INDIR}/${MAPPING}/${sample}.sorted.bam"
		dedup_bam="${INDIR}/${DEDUP}/${sample}.dedup.bam"
		dedup_resorted_bam="${INDIR}/${DEDUP}/${sample}.resorted.bam" 
		output_metrics="${INDIR}/${DEDUP}/${sample}.metrics.txt"
		
		#work in parallel 
		nice -n 11 java -jar $PICARD MarkDuplicates \
		REMOVE_DUPLICATES=true \
		INPUT=$mapped_sorted_bam \
		OUTPUT=$dedup_bam \
		METRICS_FILE=$output_metrics

		#Sort and index the bam file
		samtools sort -@ $THREAD -o $dedup_resorted_bam -O BAM $dedup_bam
        samtools index $dedup_resorted_bam
		
	 done

	 
end_log 3 "remove-Duplicates"

fi

#################################
#                               #
#         QC REPORT             #
#################################

if (( $START <= 3 )) && (( $END >= 3 )); then

start_log "QC-Report-1" "quality-metrics"

	### agregar log.
	sh $PIPELINE_TUMORSEC/02.QC_Reports.sh --input--dir $INDIR -e $INPUT_DATA -b $BASESPACE &
	
end_log "QC-Report-1" "quality-metrics"

fi

#################################
#     REALIGN INDELS (GATK)     #
################################# 

if (( $START <= 4 )) && (( $END >= 4 )); then

check_log 3 "remove-Duplicates"
start_log 4 "realign-indels"
get_samples

	if [ ! -d "${INDIR}/${REALIGN}" ]; then
                mkdir "${INDIR}/${REALIGN}"
    else
                echo "the ${INDIR}/${REALIGN} directory alredy exists"
    fi
        
	for sample in $SAMPLES
	do 
		echo "Running GATK RealignerTargetCreator for $sample"
		dedup_resorted_bam="${INDIR}/${DEDUP}/${sample}.resorted.bam"
		sample_interval="${INDIR}/${REALIGN}/${sample}.intervals"
 		#run in parallel quitar el echo
		time java -jar $GATK \
		-T RealignerTargetCreator \
		-nt $THREAD \
		-dt NONE \
		-R $hg19_fa \
		-I $dedup_resorted_bam \
		-L $HG19_OncoChile_bed \
		-known $Mills_1000G_indels_hg19 \
		-o $sample_interval
	done

	for sample in $SAMPLES
	do 
		echo "Running GATK IndelRealiger for $sample"
		dedup_resorted_bam="${INDIR}/${DEDUP}/${sample}.resorted.bam"
		realign_resorted_bam="${INDIR}/${REALIGN}/${sample}.sorted.bam"
		sample_interval="${INDIR}/${REALIGN}/${sample}.intervals"
		#Not support parallel run
		echo "java -jar $GATK \
		-T IndelRealigner \
		-dt NONE \
		--maxReadsForRealignment 20000 \
		-R $hg19_fa \
		-I $dedup_resorted_bam \
		-L $HG19_OncoChile_bed \
		-targetIntervals $sample_interval \
		-o $realign_resorted_bam" >> "${INDIR}/comands_GATK_IndelRealigner.txt"
	done

	cat "${INDIR}/comands_GATK_IndelRealigner.txt"| parallel -j $THREAD
	rm "${INDIR}/comands_GATK_IndelRealigner.txt"
	
end_log 4 "realign-indels"

fi

####################################
#                                  #
#  RECALIBRATION OF BASES (GATK)   #
#################################### 


if (( $START <= 5 )) && (( $END >= 5 )); then

check_log 4 "realign-indels"
start_log 5 "recalibration"
get_samples

	if [ ! -d "${INDIR}/${BQSR}" ]; then
                mkdir "${INDIR}/${BQSR}"
        else
                echo "The ${INDIR}/${BQSR} directory alredy exists"
        fi
        
        for sample in $SAMPLES
        do
              realign_resorted_bam="${INDIR}/${REALIGN}/${sample}.sorted.bam" 
	      	  bqsr_table="${INDIR}/${BQSR}/${sample}.table"
              output_bqsr_resorted_bam="${INDIR}/${BQSR}/${sample}.resorted.bam"

         echo "Running GATK BaseRecalibrator for $sample"
                 #not support parallel run 
         echo " java -jar $GATK \
		 -T BaseRecalibrator \
		 -dt NONE \
		 -R $hg19_fa \
		 -I $realign_resorted_bam \
		 -L $HG19_OncoChile_bed \
		 -knownSites $dbsnp_138_hg19 \
		 -o $bqsr_table" >> "${INDIR}/comands_GATK_BaseRecalibrator.txt"
       	 done

	 cat "${INDIR}/comands_GATK_BaseRecalibrator.txt"| parallel -j $THREAD
	 sh "${INDIR}/comands_GATK_BaseRecalibrator.txt"
	 rm "${INDIR}/comands_GATK_BaseRecalibrator.txt"
	 
	 for sample in $SAMPLES
	 do
	 	    realign_resorted_bam="${INDIR}/${REALIGN}/${sample}.sorted.bam"
	 	    bqsr_table="${INDIR}/${BQSR}/${sample}.table"
	 	    output_bqsr_resorted_bam="${INDIR}/${BQSR}/${sample}.resorted.bam"
                    #try parallel run
            echo "Running GATK PrintReads for $sample"
	  	    
		    echo "java -jar $GATK \
		    -T PrintReads \
		    -dt NONE \
		    -R $hg19_fa \
		    -I $realign_resorted_bam \
		    -L $HG19_OncoChile_bed \
		    --BQSR $bqsr_table \
		    -o $output_bqsr_resorted_bam" >> "${INDIR}/comands_GATK_PrintReads.txt"
	  done
         cat "${INDIR}/comands_GATK_PrintReads.txt" | parallel -j $THREAD
         sh "${INDIR}/comands_GATK_PrintReads.txt"
         rm "${INDIR}/comands_GATK_PrintReads.txt"
         
end_log 5 "recalibration"

fi

####################################
#                                  #
#     DENDOGRAM PIPELINE           #
####################################

if [[ $DENDOGRAM == "y" ]]; then

check_log 5 "recalibration"	
start_log "QC-Report-2" "dendogram"
get_samples

	if [ ! -d "${INDIR}/${METRICS}" ]; then
            mkdir "${INDIR}/${METRICS}"
    else
            echo "The ${INDIR}/${METRICS} directory alredy exists"
    fi
    
    if [ ! -d "${INDIR}/${DEM_DIR}" ]; then
            mkdir "${INDIR}/${DEM_DIR}"
    else
            echo "The ${INDIR}/${DEM_DIR} directory alredy exists"
    fi
    
	LIST_BAM_FILE="${INDIR}/${DEM_DIR}/l_path_BAM.txt"
	
	cd "${INDIR}/${BQSR}"
	echo $PWD
	sh -c "ls ${PWD}/*resorted.bam" > $LIST_BAM_FILE
	
	### RUN DENDOGRAM
	sh ${PIPELINE_TUMORSEC}/04.QC_dendogram.sh -l $LIST_BAM_FILE -o $INDIR/$DEM_DIR -dp $DP -maf $MAF -gm $PCT_GT_SAMPLES -gs $PCT_GT_SNV -e $INPUT_DATA &
	echo "sh ${PIPELINE_TUMORSEC}/04.QC_dendogram.sh -l $LIST_BAM_FILE -o $INDIR/$DEM_DIR -dp $DP -maf $MAF -gm $PCT_GT_SAMPLES -gs $PCT_GT_SNV -e $INPUT_DATA"
	
fi

####################################
#                                  #
#           VARCALL                #
####################################

if (( $START <= 6 )) && (( $END >= 6 )); then

check_log 5 "recalibration"
start_log 6 "varcall"
get_samples

	if [ ! -d "${INDIR}/${VARCALL}" ]; then
            mkdir "${INDIR}/${VARCALL}"
    else
            echo "the ${INDIR}/${VARCALL} directory alredy exists"
    fi
        for sample in $SAMPLES
        do 
		 output_dir_varcall="${INDIR}/${VARCALL}/${sample}"
		 bqsr_resorted_bam="${INDIR}/${BQSR}/${sample}.resorted.bam"
		 
		 if [ ! -d $output_dir_varcall ]; then 
				mkdir $output_dir_varcall
			else 
				echo "the ${output_dir_varcall} directory alredy exists"
		fi
		    $SOMATICSEQ  --in-bam $bqsr_resorted_bam \
		    --human-reference $hg19_fa \
		    --output-dir $output_dir_varcall \
		    --dbsnp $dbsnp_138hg19_vcf \
		    --selector $HG19_OncoChile_bed \
		    --cosmic $cosmic_vcf \
		    --min-vaf 0.01 \
		    --action echo --mutect2 --varscan2 --vardict --lofreq --scalpel --strelka --somaticseq \
		
		done

	for sample in $SAMPLES
	do 
	  	cd "${INDIR}/${VARCALL}/${sample}/logs"
	  	for j in *.cmd
	  	do 
	     	echo "bash ${INDIR}/${VARCALL}/${sample}/logs/${j}" >> "${INDIR}/comands_somaticseq_part1_1.txt"
	  	done
	
	  	cd "${INDIR}/${VARCALL}/${sample}/SomaticSeq/logs/"
	  	for k in *.cmd
	  	do
	    	echo "bash ${INDIR}/${VARCALL}/${sample}/SomaticSeq/logs/${k}" >> "${INDIR}/comands_somaticseq_part2_2.txt"
 	  	done
    done
    
	cat "${INDIR}/comands_somaticseq_part1_1.txt" | parallel -j $THREAD
    cat "${INDIR}/comands_somaticseq_part2_2.txt" | parallel -j $THREAD
	rm "${INDIR}/comands_somaticseq_part1.txt"
	rm "${INDIR}/comands_somaticseq_part2.txt"
	
end_log 6 "varcall"

fi

#####################################
#                                   #
#   FUNTIONAL ANNOTATION (ANNOVAR)  #
#####################################

if (( $START <= 7 )) && (( $END >= 7 )); then

check_log 6 "varcall"
start_log 7 "annotation"
get_samples

	if [ ! -d "${INDIR}/${ANNOTATE}" ]; then
                mkdir "${INDIR}/${ANNOTATE}"
    else
                echo "the ${INDIR}/${ANNOTATE} directory alredy exists"
    fi	
        
    if [ ! -d "${INDIR}/${ANNOVAR_ANOT}" ]; then
                mkdir "${INDIR}/${ANNOVAR_ANOT}"
    else
                echo "the ${INDIR}/${ANNOVAR_ANOT} directory alredy exists"
    fi
        
        cd "${INDIR}/${ANNOVAR_ANOT}"
	
	for sample in $SAMPLES
	do 
	   	consensus_sSNV="${INDIR}/${VARCALL}/${sample}/SomaticSeq/Consensus.sSNV.vcf"
	   	consensus_sSNV_PASS="${INDIR}/${ANNOVAR_ANOT}/${sample}_sSNV.PASS.vcf"
	   	output_annovar="${INDIR}/${ANNOVAR_ANOT}/${sample}.annovar"
        consensus_sINDEL="${INDIR}/${VARCALL}/${sample}/SomaticSeq/Consensus.sINDEL.vcf"
	   	consensus_sINDEL_PASS="${INDIR}/${ANNOVAR_ANOT}/${sample}_sINDEL.PASS.vcf"
        consensus_sINDEL_sSNV_PASS="${INDIR}/${ANNOVAR_ANOT}/${sample}.Consensus.sINDEL.sSNV_PASS.vcf"

	   	 egrep "(NUM_TOOLS=(3|4|5|6))|(^#)" $consensus_sSNV | egrep "(^#)|PASS" > $consensus_sSNV_PASS &
         egrep "(NUM_TOOLS=(3|4|5|6))|(^#)" $consensus_sINDEL | egrep "(^#)|PASS" > $consensus_sINDEL_PASS

	   	#UNIQUIFY THE sINDEL and sSNV BY SAMPLE.	
        java -jar $GATK -T CombineVariants \
	   	-R $hg19_fa \
        --variant $consensus_sSNV_PASS \
        --variant $consensus_sINDEL_PASS \
        -o $consensus_sINDEL_sSNV_PASS --assumeIdenticalSamples
           
        rm $consensus_sSNV_PASS
        rm $consensus_sSNV_PASS.idx
        rm $consensus_sINDEL_PASS
        rm $consensus_sINDEL_PASS.idx
        
	   	#RUN ANNOVAR BY SAMLE.
	    # perl $SCRIPT_ANNOVAR $consensus_sINDEL_sSNV_PASS $ANNOVAR_HDB \
		#-buildver hg19 \
		#-thread $THREAD \
		#-out $output_annovar \
		#-protocol refGene,gnomad211_genome,gnomad211_exome,esp6500siv2_all,exac03,exac03nontcga,snp138NonFlagged,AFR.sites.2015_08,AMR.sites.2015_08,EAS.sites.2015_08,EUR.sites.2015_08,SAS.sites.2015_08,dbnsfp35c,cadd13,avsnp150,cosmic92,clinvar_20200316 \
		#-operation g,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f \
		#-nastring . -vcfinput
	done
	
fi


#####################################
#                                   #
#           ANNOTATION (CGI)        #
#####################################

if (( $START <= 7 )) && (( $END >= 7 )); then


	if [ ! -d "${INDIR}/${CGI}" ]; then
                mkdir "${INDIR}/${CGI}"
    else
             echo "the ${INDIR}/${CGI} directory alredy exists"
    fi	
        cd "${INDIR}/${CGI}"
        
	for sample in $SAMPLES
	do
	
		if [ ! -d "${INDIR}/${CGI}/${sample}" ]; then
            mkdir "${INDIR}/${CGI}/${sample}"
            
       	else
            echo "the ${INDIR}/${CGI}/${sample} directory alredy exists"
        fi	
        	
		VCF="${INDIR}/${ANNOVAR_ANOT}/${sample}.Consensus.sINDEL.sSNV_PASS.vcf"
		OUTPUT="${INDIR}/${CGI}/${sample}/${sample}.zip"
		CGI_remane="${INDIR}/${CGI}/${sample}/mutation_analysis_rename.tsv"
		CGI_MA="${INDIR}/${CGI}/${sample}/mutation_analysis.tsv"
		CGI_OUTPUT="${INDIR}/${CGI}/list_CGI_MA_rename.txt"
		
		#python $ANNOTATION_CGI_PY --vcf $VCF --output $OUTPUT
		
		cd "${INDIR}/${CGI}/${sample}"
		unzip -o $OUTPUT
		sed "s/default_id/${sample}/g" $CGI_MA > $CGI_remane
		
		if [ ! -f "$CGI_OUTPUT" ]; then
		
			echo ${CGI_remane} > ${CGI_OUTPUT}
		else
			echo ${CGI_remane} >> ${CGI_OUTPUT}
		fi
		
	done

#################################
#                               #
#         VARIANT REPORT        #
#################################

sh $PIPELINE_TUMORSEC/03.Variants_reports.sh --input--dir $INDIR --input--data $INPUT_DATA &

end_log 7 "annotation"

fi
############################
#                          #
#         VCF RGO          #
############################

if (( $START <= 8 )) && (( $END >= 8 )); then
check_log 6 "varcall"
start_log 8 "filter-vcf-RGO"
get_samples

	if [ ! -d "${INDIR}/${RGO}" ]; then
                mkdir "${INDIR}/${RGO}"
        else
                echo "the ${INDIR}/${RGO} directory alredy exists"
    fi	

	for sample in $SAMPLES
	do
		AF='0.05'
		consensus_sINDEL_sSNV_PASS="${INDIR}/${ANNOVAR_ANOT}/${sample}.Consensus.sINDEL.sSNV_PASS.vcf"
		vcf_filter="${INDIR}/${RGO}/${sample}_AF_${AF}_DPALT_${DP_ALT}.vcf"
		
		## DP_ALT>=12 y AF >=0.05
	    bcftools view -i 'AF>=0.05 && (DP4[0:2]+DP4[0:3])>=12' $consensus_sINDEL_sSNV_PASS > $vcf_filter
	done
<<HOLA
	### DELETE TEMP DIR
	if [ ! -d "${INDIR}/${DEDUP}" ]; then
    		echo "Delete tmp: ${INDIR}/${DEDUP} don't exist"
	else
	    rm -r ${INDIR}/${DEDUP}
	fi 

	if [ ! -d "${INDIR}/${MAPPING}" ]; then
    	echo "Delete tmp: ${INDIR}/${MAPPING} don't exist"
	else
	    rm -r ${INDIR}/${MAPPING}
	fi 

	if [ ! -d "${INDIR}/${REALIGN}" ]; then
    	echo "Delete tmp: ${INDIR}/${REALIGN} don't exist"
	else
	    rm -r ${INDIR}/${REALIGN}
	fi    

	if [ ! -f "${INDIR}/${FASTQ}/ALL_SAMPLES_L001_R1_001.fastq" ]; then
    	echo "Delete tmp: ${INDIR}/${FASTQ}/ALL_SAMPLES_L001_R1_001.fastq don't exist"
	else
	    rm -r ${INDIR}/${FASTQ}/ALL_SAMPLES_L001_R1_001.fastq
	fi 

	if [ ! -f "${INDIR}/${FASTQ}/ALL_SAMPLES_L001_R2_001.fastq" ]; then
    	echo "Delete tmp: ${INDIR}/${FASTQ}/ALL_SAMPLES_L001_R2_001.fastq don't exist"
	else
	    rm -r ${INDIR}/${FASTQ}/ALL_SAMPLES_L001_R2_001.fastq
	fi
HOLA

end_log 8 "filter-vcf-RGO"

fi

trap : 0

echo >&3 '
*********************
*** DONE-TumorSec *** 
*********************
'


