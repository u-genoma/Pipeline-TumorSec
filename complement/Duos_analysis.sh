#!/bin/sh
###########
# 
# Pipeline TumorSec V1.0 
# Evelin Gonzalez
# Date: 2019-25-04
# Descripcion: Bash que a partir de la ruta absoluta de tres archivos, 
# compara los ID que se intersectan y calcula el perfomance de la muestra, basada en la muestra de TF
# 
# EXAMPLE: sh Trio_analysis.sh --tf /path/to/TF/from/CGI --ffpe /path/to/FFPE/from/CGI --af 0.05 --exac 1 -o /path/to/output/dir
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

#set positional arguments in their proper place
eval set -- "$PARAMS"

    	### split para obtener nombre de la muestra. 
    	### Ejemple de input /home/egonzalez/workSpace/runs_TumorSec/191017_TumorSec/11_CGI/1293Torg_S5/mutation_analysis.tsv
    	aux_FFPE=${FFPE%/mutation_analysis.tsv}
    	name_FFPE=${aux_FFPE##*/}
    	
    	### TF
    	aux_TF=${TF%/mutation_analysis.tsv}
    	name_TF=${aux_TF##*/}
    	
    	if [ ! -d "${OUTPUT}/DUO_${name_FFPE}" ]; then 
			mkdir "${OUTPUT}/DUO_${name_FFPE}"
		else 
			echo "La carpeta ${OUTPUT}/TRIO_${name_FFPE} ya existe"
    	fi

OUTPUT_ID_FFPE="${OUTPUT}/DUO_${name_FFPE}/${name_FFPE}_${AF}_1_filter_ID_CGI.tsv"
OUTPUT_ID_TF="${OUTPUT}/DUO_${name_FFPE}/${name_TF}_${AF}_2_filter_ID_CGI.tsv"

    ##### Filtro de variantes por frecuencia alélica. DP_ALT>12 sin AF en ExAC, y variantes con cambio a nivel de proteina.  # $13!="Synonymous" 
	cat $FFPE | awk -F "\t" '{print $7"\t"$0}'| awk -F ":" '{if ($15 > "'$AF'") print $0}' |  awk -F ":" '{print $2","$0}'| awk -F "," '{print $0}' | awk -F '\t' '{print $0}' | awk -F "\t" '{print $28":"$1}'| awk -F ":" '{print $1" "$16}' > $OUTPUT_ID_FFPE
	cat $TF | awk -F "\t" '{print $7"\t"$0}'| awk -F ":" '{if ($15 > "'$AF'" ) print $0}' |  awk -F ":" '{print $2","$0}'| awk -F "," '{print $0}' | awk -F '\t' '{print $0}' | awk -F "\t" '{print $28":"$1}' | awk -F ":" '{print $1" "$16}' > $OUTPUT_ID_TF

echo "Archivos del trio"
echo $OUTPUT_ID_FFPE
echo $OUTPUT_ID_TF

INTERSECT_IDS="${OUTPUT}/DUO_${name_FFPE}/Intersect_ids_${name_FFPE}_${AF}_${EXAC}.txt"

#FFPE_TF
echo "[FFPE_TF]" > $INTERSECT_IDS
bash -c "comm -12 <(sort $OUTPUT_ID_FFPE) <(sort $OUTPUT_ID_TF)" >> $INTERSECT_IDS
N_FFPE_TF=$(bash -c "comm -12 <(sort $OUTPUT_ID_FFPE) <(sort $OUTPUT_ID_TF)| wc -l")

#FFPE
echo "[FFPE]" >> $INTERSECT_IDS
bash -c "comm -23 <(sort $OUTPUT_ID_FFPE) <(sort $OUTPUT_ID_TF)" >> $INTERSECT_IDS
N_FFPE=$(bash -c "comm -23 <(sort $OUTPUT_ID_FFPE) <(sort $OUTPUT_ID_TF) | wc -l ")

#TF
echo "[TF]" >> $INTERSECT_IDS
bash -c "comm -13 <(sort $OUTPUT_ID_FFPE) <(sort $OUTPUT_ID_TF)" >> $INTERSECT_IDS
N_TF=$(bash -c "comm -13 <(sort $OUTPUT_ID_FFPE) <(sort $OUTPUT_ID_TF) | wc -l ")

echo "SAMPLE AF FFPE_TF FFPE TF" > "${OUTPUT}/DUO_${name_FFPE}_${AF}.txt"
echo "${name_FFPE} ${AF} ${N_FFPE_TF} ${N_FFPE} ${N_TF}"  >> "${OUTPUT}/DUO_${name_FFPE}_${AF}.txt"
	

trap : 0

echo >&2 '
************
*** DONE *** 
************
'






