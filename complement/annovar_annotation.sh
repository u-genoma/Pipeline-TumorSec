#!/bin/sh -x
### Descripción. Anotación con annovar ingresando un archivo vcf y un directorio de salida

ANNOVAR="/datos/reference/annot/annovar/"
ANNOVAR_HDB="${ANNOVAR}humandb/"
SCRIPT_ANNOVAR="${ANNOVAR}table_annovar.pl"


### PARAMETROS DE ENTRADAS A TRAVES DE LINEA DE COMANDOS
PARAMS=""
#echo "1:$#"
while (( "$#" )); do
  case "$1" in
    -i|--input--dir)
      shift&&INDIR=$1
      #echo "1:$#"
      ;;
      -o|--output)
      shift&&OUTPUT=$1
      #echo "2:$#"
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

if [ -z "$OUTPUT" ]; then
	echo ""
	echo "Enter the output directory:"
	read OUTPUT
fi

echo ""
echo "############################################"
echo "     ANNOVAR ANNOTATION      "
echo "############################################"
echo ""

#RUN ANNOVAR BY SAMLE.
	   	perl $SCRIPT_ANNOVAR $INDIR $ANNOVAR_HDB \
		-buildver hg19 \
		-out $OUTPUT \
		-protocol refGene,gnomad211_genome,gnomad211_exome,esp6500siv2_all,exac03,exac03nontcga,snp138NonFlagged,AFR.sites.2015_08,AMR.sites.2015_08,EAS.sites.2015_08,EUR.sites.2015_08,SAS.sites.2015_08,dbnsfp35c,cadd13,avsnp150,cosmic92,clinvar_20200316 \
		-operation g,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f \
		-nastring . -vcfinput
	

