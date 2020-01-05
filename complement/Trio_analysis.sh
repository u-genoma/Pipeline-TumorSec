#!/bin/sh
###########
# 
# Pipeline TumorSec V1.0 
# Evelin Gonzalez
# Date: 2019-25-04
# Descripcion: Bash que a partir de la ruta absoluta de tres archivos, 
# compara los ID que se intersectan y calcula el perfomance de la muestra, basada en la muestra de TF
# EXAMPLE: sh Trio_analysis.sh --tf /path/to/TF/from/CGI --ffpe /path/to/FFPE/from/CGI --bc /path/to/BC/from/CGI --af 0.05 --exac 1 -o /path/to/output/dir
#
############

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

set -e

PARAMS=""
echo "1:$#"
while (( "$#" )); do
  case "$1" in
    -i|--tf)
      shift&&TF=$1
      echo "2:$#"
      ;;
    -f|--ffpe)
       shift&&FFPE=$1
       echo "3:$#"
      ;;
    -b|--bc)
       shift&&BC=$1
       echo "3:$#"
      ;;
    -a|--af)
       shift&&AF=$1
       echo "3:$#"
      ;;
    -e|--exac)
       shift&&EXAC=$1
       echo "3:$#"
      ;;
    -o|--output)
       shift&&OUTPUT=$1
       echo "3:$#"
      ;;
    --)# end argument parsing
      shift
      break
      ;;
    -*|--*=)# unsupported flags
      echo "Error: Unsupported flag $1" >&2
      exit 1
      ;;
    *) # preserve positional arguments
      PARAMS="$PARAMS $1"
      shift
      ;;
  esac
done

#set positional arguments in their proper place
eval set -- "$PARAMS"

    	### split para obtener nombre de la muestra. 
    	### Ejemple de input /home/egonzalez/workSpace/runs_TumorSec/191017_TumorSec/11_CGI/1293Torg_S5/mutation_analysis.tsv
    	aux_FFPE=${FFPE%/mutation_analysis.tsv}
    	name_FFPE=${aux_FFPE##*/}
    	### BC
    	aux_BC=${BC%/mutation_analysis.tsv}
    	name_BC=${aux_BC##*/}
    	
    	### TF
    	aux_TF=${TF%/mutation_analysis.tsv}
    	name_TF=${aux_TF##*/}
    	
    	if [ ! -d "${OUTPUT}/TRIO_${name_FFPE}" ]; then 
			mkdir "${OUTPUT}/TRIO_${name_FFPE}"
		else 
			echo "La carpeta ${OUTPUT}/TRIO_${name_FFPE} ya existe"
    	fi

OUTPUT_ID_FFPE="${OUTPUT}/TRIO_${name_FFPE}/${name_FFPE}_${AF}_filter_ID_CGI.tsv"
OUTPUT_ID_BC="${OUTPUT}/TRIO_${name_FFPE}/${name_BC}_${AF}_filter_ID_CGI.tsv"
OUTPUT_ID_TF="${OUTPUT}/TRIO_${name_FFPE}/${name_TF}_${AF}_filter_ID_CGI.tsv"

##### Filtro de variantes por frecuencia alélica. DP_ALT>12 sin AF en ExAC, y variantes con cambio a nivel de proteina.

	echo "$AF"
	cat $FFPE | awk -F "\t" '{print $7"\t"$0}'| awk -F ":" '{if ($15> "'$AF'" ) print $0}' |  awk -F ":" '{print $2","$0}'| awk -F "," '{if(($3+$4) >= 12) print $0}' | awk -F '\t' '{if($21==""){print $0}}' | awk -F "\t" '{if($45!="." && $13!="Synonymous")print $28}' > $OUTPUT_ID_FFPE
	#cat $BC | awk -F "\t" '{print $1}'| grep -v "input" > $OUTPUT_ID_BC
	cat $BC | awk -F "\t" '{print $7"\t"$0}'| awk -F ":" '{print $2","$0}' | awk -F "," '{if ($1+$2 >=12) print $0}' | awk -F "\t" '{print $5"\t"$0}'| awk -F ";" '{print $2"\t"$0}' | sed 's/AF=//g' | awk -F "\t" '{if($1 > "'$AF'") print $30}' > $OUTPUT_ID_BC
	
	### FILTER BC from SomaticSeq -> CGI
	#cat $BC | awk -F "\t" '{print $7"\t"$0}'| awk -F ":" '{if ($15> "'$AF'" ) print $0}' |  awk -F ":" '{print $2","$0}'| awk -F "," '{if(($3+$4) >= 12) print $28}'  > $OUTPUT_ID_BC
	cat $TF | awk -F "\t" '{print $7"\t"$0}'| awk -F ":" '{if ($15> "'$AF'" ) print $0}' |  awk -F ":" '{print $2","$0}'| awk -F "," '{if(($3+$4) >= 12) print $0}' | awk -F '\t' '{if($21==""){print $0}}' | awk -F "\t" '{if($45!="." && $13!="Synonymous")print $28}' > $OUTPUT_ID_TF

echo "Archivos del trio"
echo $OUTPUT_ID_FFPE
echo $OUTPUT_ID_BC
echo $OUTPUT_ID_TF

### archivo con los id que se encuentra en las intersecciones
INTERSECT_IDS="${OUTPUT}/TRIO_${name_FFPE}/Intersect_ids_${name_FFPE}_${AF}_${EXAC}.txt"

#FFPE_TF_BC
echo "[FFPE_TF_BC]" > $INTERSECT_IDS
bash -c "comm -12 <(comm -12 <(sort $OUTPUT_ID_FFPE | uniq ) <(sort $OUTPUT_ID_TF | uniq )) <(sort $OUTPUT_ID_BC | uniq  )"  >> $INTERSECT_IDS
N_FFPE_TF_BC=$(bash -c "comm -12 <(comm -12 <(sort $OUTPUT_ID_FFPE | uniq ) <(sort $OUTPUT_ID_TF | uniq  )) <(sort $OUTPUT_ID_BC | uniq )| wc -l")

#FFPE_TF
echo "[FFPE_TF]" >> $INTERSECT_IDS
bash -c "comm -23 <(comm -12 <(sort $OUTPUT_ID_FFPE | uniq ) <(sort $OUTPUT_ID_TF | uniq  )) <(sort $OUTPUT_ID_BC | uniq  )" >> $INTERSECT_IDS
N_FFPE_TF=$(bash -c "comm -23 <(comm -12 <(sort $OUTPUT_ID_FFPE | uniq ) <(sort $OUTPUT_ID_TF | uniq  )) <(sort $OUTPUT_ID_BC | uniq  )| wc -l")

#BC_TF
echo "[BC_TF]" >> $INTERSECT_IDS
bash -c "comm -12 <(comm -13 <(sort $OUTPUT_ID_FFPE | uniq ) <(sort $OUTPUT_ID_TF | uniq  )) <(sort $OUTPUT_ID_BC | uniq  )" >> $INTERSECT_IDS
N_BC_TF=$(bash -c "comm -12 <(comm -13 <(sort $OUTPUT_ID_FFPE | uniq ) <(sort $OUTPUT_ID_TF | uniq  )) <(sort $OUTPUT_ID_BC | uniq  )| wc -l")

#BC_FFPE
echo "[BC_FFPE]" >> $INTERSECT_IDS
bash -c "comm -12 <(comm -23 <(sort $OUTPUT_ID_FFPE | uniq ) <(sort $OUTPUT_ID_TF | uniq  )) <(sort $OUTPUT_ID_BC | uniq  )" >> $INTERSECT_IDS
N_BC_FFPE=$(bash -c "comm -12 <(comm -23 <(sort $OUTPUT_ID_FFPE | uniq ) <(sort $OUTPUT_ID_TF | uniq  )) <(sort $OUTPUT_ID_BC | uniq  ) | wc -l")

#FFPE
echo "[FFPE]" >> $INTERSECT_IDS
bash -c "comm -23 <(comm -23 <(sort $OUTPUT_ID_FFPE | uniq ) <(sort $OUTPUT_ID_TF | uniq  )) <(sort $OUTPUT_ID_BC | uniq  )" >> $INTERSECT_IDS
N_FFPE=$(bash -c "comm -23 <(comm -23 <(sort $OUTPUT_ID_FFPE | uniq ) <(sort $OUTPUT_ID_TF | uniq  )) <(sort $OUTPUT_ID_BC | uniq  ) | wc -l")

#TF
echo "[TF]" >> $INTERSECT_IDS
bash -c "comm -23 <(comm -13 <(sort $OUTPUT_ID_FFPE | uniq ) <(sort $OUTPUT_ID_TF | uniq  )) <(sort $OUTPUT_ID_BC | uniq  )" >> $INTERSECT_IDS
N_TF=$(bash -c "comm -23 <(comm -13 <(sort $OUTPUT_ID_FFPE | uniq ) <(sort $OUTPUT_ID_TF | uniq  )) <(sort $OUTPUT_ID_BC | uniq  )|wc -l")	

#BC
echo "[BC]" >> $INTERSECT_IDS
bash -c "comm -13 <(comm -12 <(sort $OUTPUT_ID_FFPE | uniq ) <(sort $OUTPUT_ID_TF | uniq  )) <(sort $OUTPUT_ID_BC | uniq )" >> $INTERSECT_IDS
N_BC=$(bash -c "comm -13 <(comm -12 <(sort $OUTPUT_ID_FFPE | uniq ) <(sort $OUTPUT_ID_TF | uniq  )) <(sort $OUTPUT_ID_BC | uniq ) | wc -l")

echo "SAMPLE AF FFPE_TF_BC FFPE_TF BC_TF BC_FFPE FFPE TF BC" > "${OUTPUT}/TRIO_${name_FFPE}_${AF}.txt"
echo "${name_FFPE} ${AF} ${N_FFPE_TF_BC} ${N_FFPE_TF} ${N_BC_TF} ${N_BC_FFPE} ${N_FFPE} ${N_TF} ${N_BC}"  >> "${OUTPUT}/TRIO_${name_FFPE}_${AF}.txt"
#Sensibilidad
	
#Presicion
trap : 0

echo >&2 '
************
*** DONE *** 
************
'






