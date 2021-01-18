#!/usr/bin/env python
# coding: utf-8
#/usr/bin/python
#########################
#  01/07/2019
#  EVELIN GONZALEZ FELIU
#  DESCRIPCION:
#
#  python Reporte_variantes.py -i Users/evelin/Desktop/Reporte_Variantes/190617_TumorSec -s PUCOv013_S1 PUCOv014_S2 PUCOv015_S3 PUCOv016_S4 PUCOv017_S5 PUCOv018_S6 PUCOv019_S7 PUCOv020_S8 Undetermined_S0
#
########################

import numpy as np
import sys
import pandas as pd # to use of dataframe data structure
import csv # to import csv files
from fpdf import FPDF
import time
import argparse

def main():
    parser = argparse.ArgumentParser(description='Script que genera un reporte con los resultados de las variantes identificadas por muestras en una corrida de secuenciación')

    parser.add_argument('-i', '--input', help='ruta de carpeta de entrada', required='True')
    parser.add_argument('-s', '--samples', nargs='+', help='lista ID de muestras', required='True')
    parser.add_argument('-l', '--logo', help='Imagen logo laboratorio', required='True')
    parser.add_argument('-m', '--img', help='Carpteta de salida de los plots', required='True')
    parser.add_argument('-opdf', '--outputpdf', help='Carpteta de salida del reporte en PDF', required='True')
    parser.add_argument('-ocov', '--ocov', help='Carpteta de salida archivo de cobertura por region target', required='True')

    args=parser.parse_args()

    path_input =args.input
    samples = args.samples
    logo = args.logo
    output_coverage = args.ocov
    output_plots = args.img
    output_pdf = args.outputpdf

    #path_input='/Users/evelin/Desktop/Reporte_Variantes/190617_TumorSec'
    corrida=path_input.split('/')[-1]

    ##### GEN SUMMARY
    #data =output_coverage+"/gene_summary.csv"
    #gen_summary = pd.read_csv(data,delimiter=',', skip_blank_lines=True)
    #df_gen_summary = pd.DataFrame(gen_summary)

    #### NUM VARIANTS BY SAMPLE
    data =output_coverage+"/summary_variantes_per_sample.csv"
    variants_by_sample = pd.read_csv(data,delimiter=',', skip_blank_lines=True)
    df_variants_by_sample = pd.DataFrame(variants_by_sample)
    pdf_report(corrida,path_input,df_variants_by_sample,output_pdf,output_plots,logo)
    print("Reporte de variantes ---> LISTO!!!")
def pdf_report(corrida,path_input,df_variants_by_sample,output_pdf,output_plots,logo):
    pdf = FPDF()
    pdf.add_page()

    ################ PAGINA 1 #############################################
    pdf.set_xy(0, 0)
    pdf.set_font('Arial', 'I', 8)
    # Print centered page number
    pdf.cell(0, 10, 'Página 1 - TumorSec - Laboratorio de Genómica del Cáncer, Universidad de Chile. ', 0, 2, 'C')

    pdf.set_font('arial', 'B', 14)
    pdf.ln(8)
    pdf.image(logo, 10, 8, 33)
    pdf.ln(5)
    #pdf.cell(60)
    pdf.cell(75, 10, "Reporte TumorSec: Variantes identificadas.", 0, 1, 'L')
    pdf.ln(5)

    pdf.set_font('arial', '', 10)
    pdf.cell(90, 8,"En el siguiente reporte es un resumen de las variantes somáticas identificadas por muestra en la corrida "+corrida+"", 0, 1, 'L')
    pdf.cell(90, 8,"Generado el día "+time.strftime("%d/%m/%y")+" por el pipeline bioinformático de TumorSec, desarollado por el laboratorio", 0, 1, 'L')
    pdf.cell(90, 8,"de Genómica del Cáncer, Universidad de Chile.", 0, 1, 'L')

    #pdf.cell(60)
    pdf.set_font('arial', 'B', 12)
    pdf.cell(75, 10, "1.- Tabla resumen del número de variantes por muestras:", 0, 2,'L')## REPORTE DE LA PODA DE DATOS.
    pdf.ln(5)
    pdf.set_font('arial', 'B', 8)
    pdf.cell(30, 6, 'Muestra', 1, 0, 'C')
    pdf.cell(10, 6, 'DEL', 1, 0, 'C')
    pdf.cell(10, 6, 'INS', 1, 0, 'C')
    pdf.cell(10, 6, 'SNV', 1, 0, 'C')
    pdf.cell(10, 6, 'Total', 1, 0, 'C')
    pdf.cell(30, 6, 'CADD>30', 1, 0, 'C')
    pdf.cell(30, 6, '30>CADD>25', 1, 0, 'C')
    pdf.cell(30, 6, '25>CADD>20', 1, 0, 'C')
    pdf.cell(25, 6, 'Nº Presc_drogas', 1, 2, 'C')
    pdf.cell(-160)
    pdf.set_font('arial', '', 8)
    
    for i in range(0, len(df_variants_by_sample)):
    	pdf.cell(30, 6, '%s' % (str(df_variants_by_sample['Tumor_Sample_Barcode'][i])), 1, 0, 'C')
    	pdf.cell(10, 6, '%s' % (str(df_variants_by_sample['DEL'][i])), 1, 0, 'C')
    	pdf.cell(10, 6, '%s' % (str(df_variants_by_sample['INS'][i])), 1, 0, 'C')
    	pdf.cell(10, 6, '%s' % (str(df_variants_by_sample['SNP'][i])), 1, 0, 'C')
    	pdf.cell(10, 6, '%s' % (str(df_variants_by_sample['total'][i])), 1, 0, 'C')
    	pdf.cell(30, 6, '%s' % (str(df_variants_by_sample['Num_very_hight_patogenic'][i])), 1, 0, 'C')
    	pdf.cell(30, 6, '%s' % (str(df_variants_by_sample['Num_hight_patogenic'][i])), 1, 0, 'C')
    	pdf.cell(30, 6, '%s' % (str(df_variants_by_sample['Num_medium_patogenic'][i])), 1, 0, 'C')
    	pdf.cell(25, 6, '%s' % (str(df_variants_by_sample['Num_drug_prescription'][i])), 1, 2, 'C')
    	pdf.cell(-160)

    pdf.cell(100, 5, "Tabla 1: Resumen de variantes no filtradas: DEL: Deleción. INS: Insersión. SNV: Variante de un solo nucleotido. CADD (Combined Annotation",0, 2, 'L')
    pdf.cell(100, 5, "Dependant Depletion), asigna un puntaje de deleteriedad; Muy alta (CADD > 30); Alta (30 > CADD > 25); Mediana (25 > CADD > 20). Métricas de ", 0, 2, 'L')
    pdf.cell(100, 5, "variantes intrónicas/exónicas con VAF (Variant Allelic Frequency) >0.",0, 2, 'L')
    #pdf.cell(100, 10, "con MAF <= 1% en PVDs: Polulation Variants Databases", 0, 1, 'L')

    pdf.ln(5)
    pdf.image(output_plots+'/dp_boxplot.png', x = None, y = None, w = 100, h = 100, type = 'png', link = '')
    pdf.cell(120, 5,"Imagen 1: Profundidad (DP) de secuenciación del total las variantes identificadas por muestra (no filtradas). Linea roja indica profundidad de 300X", 0, 2, 'L')

    #############  PAGINA 2 ############################################
    pdf.set_xy(0,0)
    pdf.cell(-40)
    pdf.set_y(-15)
    # Select Arial italic 8
    pdf.set_font('Arial', 'I', 8)
    # Print centered page number
    pdf.cell(0, 10, 'Página 2 - TumorSec - Laboratorio de Genómica del Cáncer, Universidad de Chile. ', 0, 2, 'C')
    pdf.set_xy(0, 0)
    pdf.set_font('arial', 'B', 12)
    pdf.ln(10)
    pdf.image(logo, 10, 8, 33)
    pdf.ln(10)
    pdf.cell(-40)
    pdf.ln(5)
    ##### GRAFICO TRIMMING
    pdf.set_font('arial', 'B', 12)
    pdf.cell(75, 10, "2.- Oncoplot: Variantes identificadas por gen blanco", 0, 2,'L')## REPORTE DE LA PODA DE DATOS.
    pdf.set_font('arial', '', 8)
    pdf.ln(1)
    pdf.image(output_plots+'/1_ONCOPLOT_S_PS_PSN_G_PS_PGN_LabelGERM.png', x = None, y = None, w = 95, h = 95, type = 'png', link = '')
    pdf.cell(120, 5,"Imagen 2: Oncoplot derivado de la anotación de ANNOVAR que permite la visualización de mutaciones por muestra y por gen. Se observan las mutaciones", 0, 2, 'L')
    pdf.cell(120, 5,"clasificadas como somática (Somática, Posible Somática y Posible Somática Novel) o germinal (Germinal, Posible Germinal y Posible Germinal Novel)", 0, 2, 'L')
    pdf.cell(120, 5,"que producen un cambio en la proteína, con VAF >= 5%  y MAF (Minor allele frequency) <= 1% en PVDs (Population Variant Databases). Mutaciones clasi-", 0, 2, 'L')
    pdf.cell(120, 5,"ficadas como germinal se encuentran marcadas con un círculo. PVDs: GnomAD, ExAC, ESP6500 y 1000G", 0, 2, 'L')
    pdf.ln(1)

    pdf.image(output_plots+'/1_ONCOPLOT_S_PS_PSN_G_PS_PGN_LabelDRIVER.png', x = None, y = None, w = 95, h = 95, type = 'png', link = '')
    pdf.cell(120, 5,"Imagen 3:  Oncoplot derivado de la anotación de ANNOVAR y CGI. Las mutaciones predichas/conocidas como drivers por CGI (Cancer Genome Interpreter)", 0, 2, 'L')
    pdf.cell(120, 5,"se encuentran marcadas con un circulo. El detalle de la anotación para cada variante se encuentra en el archivo \"All_samples_clasificacion-variantes.xlsx\"", 0, 2, 'L') # en carpeta 7_variants_report/7.1_excel"
    pdf.cell(120, 5,"en la carpeta \"7_variants_report/7.1_excel\". Color negro (Multi_Hit) indica más de una mutación no sinónima en un gen.", 0, 2, 'L')


    #############  PAGINA 4 ############################################
    pdf.set_xy(0, 0)
    pdf.cell(-40)
    pdf.set_y(-15)
    # Select Arial italic 8
    pdf.set_font('Arial', 'I', 8)
    # Print centered page number
    pdf.cell(0, 10, 'Página 3 - TumorSec - Laboratorio de Genómica del Cáncer, Universidad de Chile. ', 0, 2, 'C')
    pdf.set_xy(0, 0)
    pdf.set_font('arial', 'B', 12)
    pdf.ln(10)
    pdf.image(logo, 10, 8, 33)
    pdf.ln(15)
    pdf.cell(-40)
    pdf.ln(5)
    pdf.set_font('arial', '', 8)
    pdf.image(output_plots+'/2_PLOT_SUMMARY_S_PS_PSN_G_PS_PGN.png', x = None, y = None, w = 150, h = 150, type = 'png', link = '')
    pdf.cell(120, 5,"Imagen 4: Resumen de las mutaciones que se observan en la imagen 2 y 3 (Oncoplot). Ver legenda en imagen 2/3 ", 0, 2, 'L')

    pdf.output(output_pdf+'/Reporte_Variantes'+corrida+'.pdf', 'F')

if __name__ == '__main__':
   main()



