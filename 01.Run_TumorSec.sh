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
PIPELINE_TUMORSEC="/home/egonzalez/workSpace/PipelineTumorSec"

### SI OCURRE ALGUN ERROR DENTRO EL PIPELINE, ESTE SE DETIENE.
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

if [ -z "$INDIR" ]; then
	echo ""
	echo "¿Cual es el directorio de salida (donde se almacenaran los resultados)?"
	read INDIR
fi

if [ -z "$BASESPACE" ]; then
	echo ""
	echo "¿Cual es el directorio de la corrida en BaseSpace?"
	read BASESPACE
fi

if [ -z "$STEP" ]; then
	echo ""
	echo "Desde que paso se correrá pipeline de TumorSec:"
	echo "0. Todo el pipeline (desde desmultilpexar datos)"
	echo "1. Desde trimming"
	echo "2. Mapeo de reads al genoma"
	echo "3. Eliminar duplicados"
	echo "4. Realineamiento de indels"
	echo "5. Recalibración de bases"
	echo "6. Llamado de variantes"
	echo "7. Anotación"
	echo "Ingresar número (0-7):"
	read STEP
fi

if [ -z "$DENDOGRAM" ]; then	
	echo ""
	echo "Desea construir dendograma de las muestras(y/n)"
	read DENDOGRAM
fi

if [ -z "$THREAD" ]; then
	echo ""
	echo "Ingrese número de procesadores:"
	read THREAD
fi

if [ -z "$INPUT_DATA" ]; then
	echo ""
	echo "Ingresar parámetros de entrada (path) o dejar por defecto (0):"
	read INPUT_DATA
fi

#### CARGAR VARIABLES Y DATOS DE ENTRADA 
if [ "$INPUT_DATA" -eq 0 ]; then
    INPUT_DATA="${PIPELINE_TUMORSEC}/00.inputs_TumorSec.ini"
	source $INPUT_DATA
else 
	source $INPUT_DATA
fi

echo ""
echo "############################################"
echo "     Bienvenido al pipeline de TumorSec      "
echo "############################################"
echo ""
echo "== Búsqueda de variantes somáticas de importancia oncológica =="
echo "Desarrollado por el Laboratorio de Genómica del Cáncer y GENOMEDLAB, Facultad de medicina. Universidad de Chile"
echo ""
echo "Comando: sh ${PIPELINE_TUMORSEC}/01.Run_TumorSec.sh --input--dir ${INDIR} --threads ${THREAD} --baseSpace ${BASESPACE} --dendogram ${DENDOGRAM} --step ${STEP} --input--data ${INPUT_DATA}" 
echo ""   	

#set -xv
#trap read debug  
	
####################################
#                                  #
#   DEMULTIPLEXING (BCL2FASTQ)     #
####################################

if [ $STEP -le 0 ]; then

	if [ ! -d "${INDIR}/${FASTQ}" ]; then 
		mkdir "${INDIR}/${FASTQ}"
	else 
		echo "The ${INDIR}/${FASTQ} directory alredy exists"
    fi
    #bcl2fastq -R "${BASESPACE}/Files" -o $INDIR/$FASTQ
fi

#################################
#                               #
#   TRIMMING OF DATA (FASTP)    #
#################################

if [ $STEP -le 1 ]; then

	if [ ! -d "${INDIR}/${TRIM}" ]; then
   		mkdir "${INDIR}/${TRIM}"
	else 
		echo "The ${INDIR}/${TRIM} directory alredy exists"
   	fi

	cd "${INDIR}/${FASTQ}"
	echo $PWD
	#GET SAMPLES ID FROM FASTQ FILES
	SAMPLES=$(ls *R1_*.fastq.gz| awk '{split($0,array,"_")} {print array[1]"_"array[2]}')
fi
<<HOLA
	
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
   		echo "nice -n 11 fastp \
		-q $qual \
		-l $large \
		-5 -3 -M 20 -W $window \
		-i $fastq_R1 \
		-I $fastq_R2 \
		-o $trimmed_R1 \
		-O $trimmed_R2 \
		-j $output_json > $output_log" >> "${INDIR}/comands_fastp.txt"
	done
	#run fastp in parallel for all samples
	cat "${INDIR}/comands_fastp.txt"| parallel -j $THREAD
	rm "${INDIR}/comands_fastp.txt"

fi

#################################
#								#
#    MAPPING OF READS (BWA)     #
#################################

if [ $STEP -le 2 ]; then

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
        rm "${INDIR}/${MAPPING}/${sample}.sam"
		samtools sort -@ $THREAD -o $sorted_bam -O BAM $mapping_bam
		#don't work in parallel
		samtools index $sorted_bam
	done
fi
#################################
#                               #
#  DELETE DUPLICATES (PICARD)   #
#################################

if [ $STEP -le 3 ]; then

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
        samtools index $dedup_resorted_bam &
		rm "${INDIR}/${MAPPING}/${sample}.sorted.bam"
		
	 done

	 
#################################
#                               #
#         QC REPORT             #
#################################

sh "${PIPELINE_TUMORSEC}/02.QC_Reports.sh --input--dir ${INDIR} -e ${INPUT_DATA} -b ${BASESPACE}" &

fi

#################################
#                               #
#     REALIGN INDELS (GATK)     #
################################# 
    
if [ $STEP -le 4 ]; then
    
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
		realign_resorted_bam="${INDIR}/${REALIGN}/${sample}.resorted.bam"
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
fi

####################################
#                                  #
#  RECALIBRATION OF BASES (GATK)   #
#################################### 

if [ $STEP -le 5 ]; then

	if [ ! -d "${INDIR}/${BQSR}" ]; then
                mkdir "${INDIR}/${BQSR}"
        else
                echo "The ${INDIR}/${BQSR} directory alredy exists"
        fi

        for sample in $SAMPLES
        do
              realign_resorted_bam="${INDIR}/${REALIGN}/${sample}.resorted.bam" 
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

	 #cat "${INDIR}/comands_GATK_BaseRecalibrator.txt"| parallel -j $THREAD
	 sh "${INDIR}/comands_GATK_BaseRecalibrator.txt"
	 rm "${INDIR}/comands_GATK_BaseRecalibrator.txt"
	 
	 for sample in $SAMPLES
	 do
	 	    realign_resorted_bam="${INDIR}/${REALIGN}/${sample}.resorted.bam"
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
fi
        
####################################
#                                  #
#     DENDOGRAM PIPELINE           #
####################################         
#if [[ $DENDOGRAM == "y" ]]; then
	### MAKE LIST OF BAMS
	if [ ! -d "${INDIR}/${DEM_DIR}" ]; then
            mkdir "${INDIR}/${DEM_DIR}"
    else
            echo "The ${INDIR}/${DEM_DIR} directory alredy exists"
    fi
    
	LIST_BAM_FILE="${INDIR}/${DEM_DIR}/l_path_BAM.txt"
	
	cd "${INDIR}/${BQSR}"
	echo $PWD
	sh -c "ls *resorted.bam" > $LIST_BAM_FILE
	
	### RUN DENDOGRAM
	#sh ${PIPELINE_TUMORSEC}/04.QC_dendogram.sh -l $LIST_BAM_FILE -o $INDIR/$DEM_DIR -dp $DP -maf $MAF -gm $PCT_GT_SAMPLES -gs $PCT_GT_SNV -e $INPUT_DATA &
	echo "sh ${PIPELINE_TUMORSEC}/04.QC_dendogram.sh -l $LIST_BAM_FILE -o $INDIR/$DEM_DIR -dp $DP -maf $MAF -gm $PCT_GT_SAMPLES -gs $PCT_GT_SNV -e $INPUT_DATA"

HOLA
####################################
#                                  #
#        VARCALL (SOMATICSEQ)      #
####################################


	if [ ! -d "${INDIR}/${VARCALL}" ]; then
            mkdir "${INDIR}/${VARCALL}"
        else
            echo "the ${INDIR}/${VARCALL} directory alredy exists"
    fi
        for sample in $SAMPLES
        do 
        	echo $sample
			output_dir_varcall="${INDIR}/${VARCALL}/${sample}"
			bqsr_resorted_bam="${INDIR}/${BQSR}/${sample}.resorted.bam"
			
			mkdir $output_dir_varcall
 		
			$SOMATICSEQ  --in-bam $bqsr_resorted_bam \
			--human-reference $hg19_fa \
			--output-dir $output_dir_varcall \
			--dbsnp $dbsnp_138hg19_vcf \
			--selector $HG19_OncoChile_bed \
			--cosmic $cosmic_vcf \
			--min-vaf 0.01 \
			--action echo --mutect2 --varscan2 --vardict --lofreq --somaticseq \
		
		done

	for sample in $SAMPLES
	do 
	  	cd "${INDIR}/${VARCALL}/${sample}/logs"
	  	for j in *.cmd
	  	do 
	     	echo "bash ${INDIR}/${VARCALL}/${sample}/logs/${j}" >> "${INDIR}/comands_somaticseq_part1.txt"
	  	done
	
	  	cd "${INDIR}/${VARCALL}/${sample}/SomaticSeq/logs/"
	  	for k in *.cmd
	  	do
	    	echo "bash ${INDIR}/${VARCALL}/${sample}/SomaticSeq/logs/${k}" >> "${INDIR}/comands_somaticseq_part2.txt"
 	  	done
    done
    
	cat "${INDIR}/comands_somaticseq_part1.txt" | parallel -j $THREAD
    cat "${INDIR}/comands_somaticseq_part2.txt" | parallel -j $THREAD
	rm "${INDIR}/comands_somaticseq_part1.txt"
	rm "${INDIR}/comands_somaticseq_part2.txt"

#####################################
#                                   #
#   FUNTIONAL ANNOTATION (ANNOVAR)  #
#####################################

	
	if [ ! -d "${INDIR}/${ANNOTATE}" ]; then
                mkdir "${INDIR}/${ANNOTATE}"
        else
                echo "the ${INDIR}/${ANNOTATE} directory alredy exists"
        fi	
      
        cd "${INDIR}/${ANNOTATE}"
	
	for sample in $SAMPLES
	do 
	   	consensus_sSNV="${INDIR}/${VARCALL}/${sample}/SomaticSeq/Consensus.sSNV.vcf"
	   	consensus_sSNV_PASS="${INDIR}/${ANNOTATE}/${sample}_sSNV.PASS.vcf"
	   	output_annovar="${INDIR}/${ANNOTATE}/${sample}.annovar"
        consensus_sINDEL="${INDIR}/${VARCALL}/${sample}/SomaticSeq/Consensus.sINDEL.vcf"
	   	consensus_sINDEL_PASS="${INDIR}/${ANNOTATE}/${sample}_sINDEL.PASS.vcf"
        consensus_sINDEL_sSNV_PASS="${INDIR}/${ANNOTATE}/${sample}.Consensus.sINDEL.sSNV_PASS.vcf"

	   	 egrep "(NUM_TOOLS=(2|3|4|5|6))|(^#)" $consensus_sSNV > $consensus_sSNV_PASS &
         egrep "(NUM_TOOLS=(2|3|4|5|6))|(^#)" $consensus_sINDEL > $consensus_sINDEL_PASS

	   	#UNIQUIFY THE sINDEL and sSNV BY SAMPLE.	
           	java -jar $GATK -T CombineVariants \
	   	    -R $hg19_fa \
           	--variant $consensus_sSNV_PASS \
           	--variant $consensus_sINDEL_PASS \
           	-o $consensus_sINDEL_sSNV_PASS --assumeIdenticalSamples
           
	   	#RUN ANNOVAR BY SAMLE.
	   	perl $SCRIPT_ANNOVAR $consensus_sINDEL_sSNV_PASS $ANNOVAR_HDB \
		-buildver hg19 \
		-out $output_annovar \
		-protocol refGene,AFR.sites.2015_08,AMR.sites.2015_08,EAS.sites.2015_08,EUR.sites.2015_08,SAS.sites.2015_08,exac03,dbnsfp35c,cadd13,avsnp150,cosmic70,clinvar_20180603 \
		-operation g,f,f,f,f,f,f,f,f,f,f,f \
		-nastring . -vcfinput

	done

#####################################
#                                   #
#        CANONICAL TRANSCRIPT       #
#####################################

	 if [ ! -d "${INDIR}/${CANONICAL}" ]; then
                mkdir "${INDIR}/${CANONICAL}"
        else
                echo "the ${INDIR}/${CANONICAL} directory alredy exists"
        fi
     
     for sample in $SAMPLES
     do
	 INPUT="${INDIR}/${ANNOTATE}/${sample}.knownGene.annovar.hg19_multianno.txt "
	 OUTPUT="${INDIR}/${CANONICAL}/${sample}.knownGene.annovar.hg19_multianno_canonical.txt"
	 #python $CANONICAL_TRANSCRIP -a $INPUT -o $OUTPUT -k $LIST_CANONICAL
     done

#####################################
#                                   #
#           ANNOTATION (CGI)        #
#####################################

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
        	
		VCF="${INDIR}/${ANNOTATE}/${sample}.Consensus.sINDEL.sSNV_PASS.vcf"
		OUTPUT="${INDIR}/${CGI}/${sample}/${sample}.zip"
		CGI_remane="${INDIR}/${CGI}/${sample}/mutation_analysis_rename.tsv"
		CGI_MA="${INDIR}/${CGI}/${sample}/mutation_analysis.tsv"
		CGI_OUTPUT="${INDIR}/${CGI}/list_CGI_MA_rename.txt"
		
		python $ANNOTATION_CGI_PY --vcf $VCF --output $OUTPUT
		
		cd "${INDIR}/${CGI}/${sample}"
		unzip -o $OUTPUT
		sed "s/default_id/${sample}/g" $CGI_MA > $CGI_remane
		echo $CGI_remane >> $CGI_OUTPUT		
	done
	
	    Rscript $CGI_MAF_ONCOPLOT $CGI_OUTPUT "${INDIR}/${CGI}/" $AF $ExAC $DP_ALT

#################################
#                               #
#         VARIANT REPORT        #
#################################

sh $PIPELINE_TUMORSEC/03.Variants_reports.sh --input--dir $INDIR --input--data $INPUT_DATA &


        for sample in $SAMPLES
        do 
        	echo $sample
			output_dir_varcall="${INDIR}/${VARCALL}/${sample}"
			bqsr_resorted_bam="${INDIR}/${BQSR}/${sample}.resorted.bam"
			#mkdir $output_dir_varcall
 		
			$SOMATICSEQ  --in-bam $bqsr_resorted_bam \
			--human-reference $hg19_fa \
			--output-dir $output_dir_varcall \
			--dbsnp $dbsnp_138hg19_vcf \
			--selector $HG19_OncoChile_bed \
			--cosmic $cosmic_vcf \
			--min-vaf 0.01 \
			--action echo --mutect2 --varscan2 --vardict --lofreq --somaticseq \
		
		done 

	

trap : 0

echo >&2 '
************
*** DONE *** 
************
'
