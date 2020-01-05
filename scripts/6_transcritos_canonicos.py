#!/usr/bin/env python
# coding: utf-8
##########################################################################################################################################
#   01/06/2019
#
# Descripción: a partir de un archivo txt de salida de anotación por ANNOVAR y la lista de transcritos canónicos de UCSC.
# crea un archivo de anotación txt solo con los transcritos canonicos.
# ejemplo de ejecucion:
# python Canonical_Transcript.py -o /Users/evelin/Desktop/8_annoate/Salida.txt -v /Users/evelin/Desktop/8_annoate/218190_S9.knownGene.annovar.hg19_multianno.txt -k /Users/evelin/Desktop/8_annoate/knownCanonical.txt
#  EVELIN GONZALEZ FEIU
##########################################################################################################################################
import numpy as np
import sys
import pandas as pd # to use of dataframe data structure
import csv # to import csv files
import argparse
import sys

def main():

    parser = argparse.ArgumentParser(description='Script seleciona los transcritos canonicos de UCSC')
    parser.add_argument('-a', '--annovar.txt', help='archivo input txt, salida de annovar', required='True')
    parser.add_argument('-o', '--output', help='archivo de salida', required='True')
    parser.add_argument('-k', '--UCSC', help='lista de genes canonicos', required='True')

    args=parser.parse_args()

    data =args.UCSC
    vcf = args.vcf
    output=args.output
    knownCanonical = pd.read_csv(data,delimiter='\t', skip_blank_lines=True, header=None, usecols=[5])

    with open(vcf) as fp:
        archivo = open(output, "w")

        for cnt, line in enumerate(fp): ## por cada linea.
            GeneDetail_knownGene=line.split('\t')[7]
            AAChange_knownGene=line.split('\t')[9]
            list_line=line.split('\t')

            if ((GeneDetail_knownGene!='.') and (GeneDetail_knownGene!='GeneDetail.knownGene')):

                GeneDetail_knownGene=GeneDetail_knownGene.split(';')## separo los transcritos de una linea

                if(len(GeneDetail_knownGene)> 1):## si hay mas de un transcrito
                    for transc in GeneDetail_knownGene: ## por cada transcrito , revisa si es canonico
                        for s in knownCanonical.values:
                            if transc.split(':')[0] in s:
                                list_line[7]=transc

            if ((AAChange_knownGene!='.') and (AAChange_knownGene!='GeneDetail.knownGene')):

                AAChange_knownGene=AAChange_knownGene.split(',')## separo los transcritos de una linea

                if(len(AAChange_knownGene)> 1):## si hay mas de un transcrito
                    for transc in AAChange_knownGene: ## por cada transcrito , revisa si es canonico
                        for s in knownCanonical.values:
                            if transc.split(':')[1] in s:
                                list_line[9]=transc

            line=('\t').join(list_line)
            archivo.write(line)

#fp.close()
#archivo.close()
if __name__ == '__main__':
   main()


