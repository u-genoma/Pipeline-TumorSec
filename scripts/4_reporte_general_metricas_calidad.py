#/usr/bin/python
######################################
#  26/06/2019
#  EVELIN GONZALEZ FELIU
#  DESCRIPCION:
# python Reporte_190607.py -i /Users/evelin/Documents/190617_TumorSec
######################################

import numpy as np
import sys
import pandas as pd
import csv
import matplotlib
from matplotlib import cm
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import json
import requests
from pylab import title, figure, xlabel, ylabel, xticks, bar, legend, axis, savefig
from fpdf import FPDF
import gzip
import time
import argparse


def sort_dataframe(df_input): 
    df_input[['aux_nombre','orden']] = df_input['Sample'].str.split('_S',expand=True)
    df_input["orden"] = pd.to_numeric(df_input["orden"])
    df_input=df_input.sort_values(by='orden', ascending=True)
    df_input.set_index('orden',inplace=True)
    df_input.reset_index(inplace=True)
    df_input=df_input.drop(['aux_nombre', 'orden'], axis=1)

    return df_input
    
    
def plot_pct_coverage(output_plots,df_HsMetrics,color):
    df_HsMetrics=sort_dataframe(df_HsMetrics)
    rango=[100,200,300,400,500,600,700,800,900,1000]
    with plt.style.context('bmh'):
        for i in range(0,df_HsMetrics.shape[0]):
            plt.plot(rango,df_HsMetrics.loc[i][1:],label='linear', linewidth=0.5)
            
    #Number of accent colors in the color scheme
    plt.title('Porcentaje de bases target con cobertura X')
    plt.xlabel('Cobertura(X)', fontsize=10)
    plt.ylabel('Porcentaje de bases', fontsize=10)
    plt.legend(df_HsMetrics['Sample'], loc='center left', bbox_to_anchor=(1, 0.5))
    plt.savefig(output_plots+'/pct_coverage_all.png',figsize=(50,100),dpi=200, bbox_inches = "tight")
    #plt.show()
    plt.clf()
    print("Gráfico del porcentaje de reads targets con cobertura X (100X - 1000X) ---> LISTO !!")

###### GRAFICO DE TRIMMNG DE DATOS
def plot_trimming(output_plots,df_trimming_metrics):
    df_trimming_metrics=sort_dataframe(df_trimming_metrics)
    with plt.style.context('bmh'):
        ind = np.arange(df_trimming_metrics.shape[0]) # the x locations for the groups
        width = 0.35       # the width of the bars: can also be len(x) sequence
        p1 = plt.bar(ind,df_trimming_metrics['Reads_before_trimming'])
        p2 = plt.bar(ind,df_trimming_metrics['Reads_after_trimming'])

        plt.ylabel('NÚMERO DE READS')
        plt.xlabel('MUESTRAS')
        plt.title('CANTIDAD DE READS ANTES Y DESPUES DEL TRIMMING')
        ind = np.arange(df_trimming_metrics.shape[0])
        plt.xticks(np.arange(df_trimming_metrics.shape[0]), df_trimming_metrics['Sample'],rotation='vertical')
        plt.legend((p1[0], p2[0]), ('Reads de Mala Calidad', 'Reads de Buena Calidad '))
        plt.savefig(output_plots+'/trimming.png',figsize=(50,50),dpi=200, bbox_inches = "tight")
        plt.clf()
        print("Gráfico del número de reads antes y despues del trimming ---> LISTO !!")

def plot_pct_ontarget(output_plots,df_ontarget,color):
    df_ontarget=sort_dataframe(df_ontarget)
    with plt.style.context('bmh'):
        n=df_ontarget.shape[0]
        color=cm.gist_earth(np.linspace(0,1,n))
        plt.bar(np.arange(df_ontarget.shape[0]),df_ontarget['pc_ontarget'],color=color)
        ind = np.arange(df_ontarget.shape[0])
        plt.xticks(ind, df_ontarget['Sample'],rotation='vertical')
        plt.ylabel('PORCENTAJE')
        plt.xlabel('MUESTRAS')
        plt.title('PORCENTAJE DE READS EN REGIONES TARGETS')
        savefig(output_plots+'/pct_reads_ontarget.png',figsize=(50,50),dpi=200, bbox_inches = "tight")
        plt.clf()
        print("Grafico del porcentaje de reads en regiones targets ---> LISTO !!")

def plot_dedup(output_plots,df_dedup_metrics,color):
    df_dedup_metrics=sort_dataframe(df_dedup_metrics)
    with plt.style.context('bmh'):
        plt.bar(np.arange(df_dedup_metrics.shape[0]),df_dedup_metrics['PERCENT_DUPLICATION'],color=color)#,edgecolor='black')
        ind = np.arange(df_dedup_metrics.shape[0])
        plt.xticks(ind, df_dedup_metrics['Sample'],rotation='vertical')
        plt.ylabel('PORCENTAJE')
        plt.xlabel('MUESTRAS')
        plt.title('PORCENTAJE DE LECTURAS DUPLICADAS')
        plt.tight_layout()
        savefig(output_plots+'/dedup.png',figsize=(50,50),dpi=200, bbox_inches = "tight")
        plt.clf()
        print("Grafico del porcentaje de duplicados ---> LISTO !!")

def plot_pct_bases100_500_1000(output_plots,df_HsMetrics,color):
    df_HsMetrics=sort_dataframe(df_HsMetrics)
    with plt.style.context('bmh'):
        plt.tight_layout()
        fig, (ax1, ax2, ax3) = plt.subplots(3)
        y = np.array(df_HsMetrics['PCT_TARGET_BASES_100X'])

        ###GRAFICO 100X DE COVERTURA (ax1)
        ax1.bar(np.arange(df_HsMetrics.shape[0]),df_HsMetrics['PCT_TARGET_BASES_100X'],color=color)  # Dibujamos el gráfico de barras
        ax1.set_title('100X')  #Colocamos el título
        plt.setp(ax1.get_xticklabels(), visible=False)
    
        ind = np.arange(df_HsMetrics.shape[0])
        plt.xticks(ind, df_HsMetrics['Sample'],rotation='vertical')

        ###GRAFICO 500X DE COVERTURA (ax2)
        ax2.bar(np.arange(df_HsMetrics.shape[0]),df_HsMetrics['PCT_TARGET_BASES_500X'],color=color)  # Dibujamos el gráfico de barras
        ax2.set_title('500X')  #Colocamos el título
        plt.setp(ax2.get_xticklabels(), visible=False)
        ax2.set_ylabel("PORCENTAJE")

        ###GRAFICO 100X DE COVERTURA (ax3)
        ax3.bar(np.arange(df_HsMetrics.shape[0]),df_HsMetrics['PCT_TARGET_BASES_1000X'],color=color)  # Dibujamos el gráfico de barras
        ax3.set_title('1000X')  #Colocamos el título
        ax3.set_xlabel("MUESTRAS")

        fig.suptitle("PORCENTAJE DE BASES CUBIERTAS POR MUESTRA")
        fig.subplots_adjust(hspace=0.5)
        fig.tight_layout(pad=15)
        fig.savefig(output_plots+'/porcentaje_bases.png',figsize=(80,80),dpi=200,bbox_inches = "tight")
        print("Grafico del porcentaje de bases en regiones target con cobertura mayor o igual: 100X, 500X, 1000X ---> LISTO !!")

def mean_coverage(output_plots,df_merge3,color):
    df_merge3=sort_dataframe(df_merge3)
    with plt.style.context('bmh'):
        plt.bar(np.arange(df_merge3.shape[0]),df_merge3['mean_coverage'], color=color)#color='#CEA408
        ind = np.arange(df_merge3.shape[0])
        plt.xticks(ind, df_merge3['Sample'],rotation='vertical')
        plt.ylabel('NÚMERO DE READS')
        plt.xlabel('MUESTRAS')
        plt.title('PROFUNDIDAD PROMEDIO EN REGIONES ON-TARGET')
        #plt.legend(df_merge3.Sample, loc='center left',  bbox_to_anchor=(1, 0.5),title="MUESTRAS",)
        savefig(output_plots+'/promedio_profundidad.png',figsize=(80,80),dpi=200,bbox_inches = "tight")
        plt.clf()
        print("Grafico del promedio de cobertura en regiones targets por muestra ---> LISTO !!")

def pdf_report(corrida,path_input,output_pdf,df_baseSpace,df_metric_lect,df_metric_linea,df_merge3,df_HsMetrics,df_400X,logo,output_plots):
    pdf = FPDF()
    pdf.add_page()
    ################ PAGINA 1 #############################################
    pdf.set_xy(0, 0)
    pdf.set_font('arial', 'B', 12)
    pdf.ln(8)
    pdf.image(logo, 10, 8, 33)
    pdf.ln(10)
    pdf.cell(60)
    pdf.cell(75, 10, "Reporte TumorSec: Control de calidad de los datos generados.", 0, 1, 'C') 
    pdf.set_font('arial', '', 10)
    pdf.cell(90, 8,"En el siguiente reporte se presentan diversas métricas de calidad correspondiente a la corrida "+corrida+"", 0, 1, 'L')
    pdf.cell(90, 8,"este informe fue generado el día "+time.strftime("%d/%m/%y")+" por el pipeline bioinformático de TumorSec desarollado por el laboratorio", 0, 1, 'L') 
    pdf.cell(90, 8,"de Genómica del Cáncer, Universidad de Chile. Estas métricas representan una guía para verificar la calidad de los", 0, 1, 'L') 
    pdf.cell(90, 8,"resultados obtenidos por cada muestra en la secuenciación.", 0, 1, 'L') 
    pdf.set_font('arial', 'B', 12)
    pdf.cell(75, 10, "2.- Control de calidad de la corrida:", 0, 2,'L')## REPORTE DE LA PODA DE DATOS.
    pdf.set_font('arial', '', 10)
    pdf.cell(75, 10, "2.1.- Información de la corrida:", 0, 2,'L')## REPORTE DE LA PODA DE DATOS.
    pdf.set_font('arial', '', 8)
    for i in range(0, len(df_baseSpace)):
        print(i)
        pdf.cell(50, 5, '%s' % (str(df_baseSpace[0][i])), 1, 0, 'L')
        pdf.cell(50, 5, '%s' % (str(df_baseSpace[1][i])), 1, 2, 'L')
        pdf.cell(-50)
    pdf.cell(120, 5,"Tabla 1: Información del kit de secuenciación y regiones blanco de TumorSec", 0, 2, 'L')
    pdf.ln(3)
    pdf.image(output_plots+'/Files_Clusters-by-lane.png', x = None, y = None, w = 58, h = 58, type = 'png', link = '')
    pdf.image(output_plots+'/Files_Intensity-by-cycle_Intensity.png', x = 80, y = 148, w = 58, h = 58, type = 'png', link = '')
    pdf.image(output_plots+'/Files_q-heat-map.png', x = None, y = None, w = 58, h = 58, type = 'png', link = '')
    pdf.image(output_plots+'/Files_q-histogram.png', x = 80, y = 206, w = 58, h = 58, type = 'png', link = '')
    pdf.cell(120, 5,"Imagen 1: Métricas de BaseSpace Illumina MiSeq. A: Densidad de clusters (K/mm2) por línea. B: Gráfico de intensidad por ciclo.", 0, 1, 'L')
    pdf.cell(120, 5,"C: Gráfico de score de calidad por ciclo. D: Diagrama de distribución de QScore, número de bases por score de calidad", 0, 1, 'L')


    #############  PAGINA 2 ############################################
    pdf.add_page()
    pdf.set_xy(0, 0)
    pdf.set_font('arial', 'B', 12)
    pdf.ln(10)
    pdf.image(logo, 10, 8, 33)
    pdf.ln(15)
    pdf.cell(60)
    pdf.set_font('arial', '', 10)
    pdf.cell(-60)
    pdf.cell(75, 10, "2.1.- Métricas según Lecturas:", 0, 2,'L')## REPORTE DE LA PODA DE DATOS.
    pdf.set_font('arial', '', 8)
    pdf.cell(30, 5, 'Read', 1, 0, 'L')
    pdf.cell(30, 5, 'Rendimiento (Gb)', 1, 0, 'L')
    pdf.cell(30, 5, 'Rend Esperado (Gb)', 1, 0, 'L')
    pdf.cell(30, 5, 'Intensidad', 1, 0, 'L')
    pdf.cell(30, 5, '%>=Q30', 1, 0, 'L')
    pdf.cell(30, 5, 'Phas/Prephas (%)', 1, 2, 'L')
    pdf.cell(-150)
    for i in range(0, len(df_metric_lect)):
        print(i)
        pdf.cell(30, 5, '%s' % (str(df_metric_lect['Level'][i])), 1, 0, 'L')
        pdf.cell(30, 5, '%s' % (str(df_metric_lect['Yield'][i])), 1, 0, 'L')
        pdf.cell(30, 5, '%s' % (str(df_metric_lect['ProjectedYield'][i])), 1, 0, 'L')
        pdf.cell(30, 5, '%s' % (str(df_metric_lect['IntensityC1'][i])), 1, 0, 'L')
        pdf.cell(30, 5, '%s' % (str(df_metric_lect['%>=Q30'][i])), 1, 0, 'L')
        pdf.cell(30, 5, '%s' % (str(df_metric_lect['LegacyPhasing/PrephasingRate'][i])), 1, 2, 'L')
        pdf.cell(-150)
    pdf.cell(120, 5,"Tabla 2: Métricas de las lecturas de BaseSpace Illumina", 0, 2, 'L')
    pdf.set_font('arial', '', 10)
    pdf.cell(75, 10, "2.2.- Métricas según Línea:", 0, 2,'L')## REPORTE DE LA PODA DE DATO
    pdf.set_font('arial', '', 8)
    pdf.cell(30, 5, 'Línea', 1, 0, 'L')
    pdf.cell(30, 5, 'Densidad (K/mm2)', 1, 0, 'L')
    pdf.cell(30, 5, 'Clúster PF (%)', 1, 2, 'L')
    pdf.cell(-60)
    pdf.cell(30, 5, 'Linea 1', 1, 0, 'L')
    pdf.cell(30, 5, '%s' % (str(df_metric_linea['Density'])), 1, 0, 'L')
    pdf.cell(30, 5, '%s' % (str(df_metric_linea['ClusterPF'])), 1, 2, 'L')
    pdf.cell(-150)
    pdf.ln(5)
    pdf.set_font('arial', 'B', 12)
    pdf.cell(75, 10, "3.- Control de calidad de los datos generados.", 0, 2,'L')## REPORTE DE LA PODA DE DATOS.
    pdf.ln(5)
    pdf.cell(75, 10, "3.1.1- Tabla resumen de las métricas de calidad", 0, 2,'L')## REPORTE DE LA PODA DE DATOS.

    pdf.cell(-90)
    pdf.ln(5)
    pdf.set_font('arial', 'B', 6)
    pdf.cell(22, 5, 'Sample', 1, 0, 'C')
    pdf.cell(22, 5, 'R_before trimming', 1, 0, 'C')
    pdf.cell(22, 5, 'R_after trimming', 1, 0, 'C')
    pdf.cell(22, 5, '% of trim', 1, 0, 'C')
    pdf.cell(22, 5, '% of dups', 1, 0, 'C')
    pdf.cell(22, 5, 'Reads On-Target', 1, 0, 'C')
    pdf.cell(22, 5, '% On-Target', 1, 0, 'C')
    pdf.cell(22, 5, 'Mean read coverage', 1, 0, 'C')
    pdf.cell(22, 5, '% uniformity', 1, 2, 'C')
    pdf.cell(-176)
    pdf.set_font('arial', '', 6)
    #df_HsMetrics[['Sample', 'MEAN_TARGET_COVERAGE','MAX_TARGET_COVERAGE','PCT_TARGET_BASES_100X','PCT_TARGET_BASES_500X','PCT_TARGET_BASES_1000X']]
    print(df_merge3)
    for i in range(0, len(df_merge3)):
        pdf.cell(22, 5, '%s' % (df_merge3['Sample'][i]), 1, 0,'C')
        pdf.cell(22, 5, '%s' % (str(df_merge3['Reads_before_trimming'][i])), 1, 0, 'C')
        pdf.cell(22, 5, '%s' % (str(df_merge3['Reads_after_trimming'][i])), 1, 0, 'C')
        pdf.cell(22, 5, '%.2f' % (float(df_merge3['pct_trimmed_reads'][i])), 1, 0, 'C')
        pdf.cell(22, 5, '%.2f' % (df_merge3['PERCENT_DUPLICATION'][i]), 1, 0, 'C')
        pdf.cell(22, 5, '%.2f' % (df_merge3['on_target'][i]), 1, 0, 'C')
        pdf.cell(22, 5, '%.2f' % (df_merge3['pc_ontarget'][i]), 1, 0, 'C')
        pdf.cell(22, 5, '%.2f' % (df_merge3['mean_coverage'][i]), 1, 0, 'C')
        pdf.cell(22, 5, '%.2f' % (df_merge3['pct_unifomity'][i]), 1, 2, 'C')
        pdf.cell(-176)
    pdf.set_font('arial', '', 8)
    pdf.cell(120, 5,"Tabla 3: Métricas de calidad. Sample: Muestras. R_before trimming: Número de lecturas iniciales. R_after_trimming: Número de lecturas despues de la poda", 0, 2, 'L')
    pdf.cell(120, 5,".% of trim : Porcentaje de lecturas eliminadas. % of dups: Porcentaje de lecturas duplicadas. Reads On-Target: Número de lecturas en regiones blanco", 0, 2, 'L')
    pdf.cell(120, 5,"% On-Target: Porcentaje en regiones blanco. Mean read coverage: Profundidad promedio de lecturas en regiones blanco. % Uniformity: Porcentaje de lecturas", 0, 2, 'L')
    pdf.cell(120, 5,"en regiones blanco, donde su profundidad promedio está entre el rango [2* mediana, mediana/2].", 0, 2, 'L')


    ################# PAGINA 3 #################################################
    pdf.set_xy(0, 0)
    pdf.cell(-40)
    pdf.set_y(-15)
    pdf.set_font('Arial', 'I', 8)
    # Print centered page number
    pdf.cell(0, 10, 'Página %s - TumorSec - Laboratorio de Genómica del Cancer, Universidad de Chile. ' % pdf.page_no(), 0, 2, 'C')
    pdf.set_xy(0, 0)
    pdf.set_font('arial', 'B', 12)
    pdf.ln(10)
    pdf.image(logo, 10, 8, 33)
    pdf.ln(15)
    pdf.cell(60)
    pdf.cell(-60)
    pdf.cell(75, 10, "3.1.2- Profundidad y amplitud de las coberturas en las regiones blanco:", 0, 2,'L')## REPORTE DE LA PODA DE DATOS
    pdf.ln(5)
    pdf.set_font('arial', 'B', 8)
    pdf.cell(28, 5, 'SAMPLE', 1, 0, 'C')
    pdf.cell(28, 5, 'MEAN_COVERAGE', 1, 0, 'C')
    pdf.cell(28, 5, 'MAX_COVERAGE', 1, 0, 'C')
    pdf.cell(20, 5, 'PCT_100X', 1, 0, 'C')
    pdf.cell(20, 5, 'PCT_200X', 1, 0, 'C')
    pdf.cell(20, 5, 'PCT_300X', 1, 0, 'C')
    pdf.cell(20, 5, 'PCT_400X', 1, 0, 'C')
    pdf.cell(20, 5, 'PCT_500X', 1, 2, 'C')
    pdf.cell(-164)
    pdf.set_font('arial', '', 8)
    #df_HsMetrics[['Sample', 'MEAN_TARGET_COVERAGE','MAX_TARGET_COVERAGE','PCT_TARGET_BASES_100X','PCT_TARGET_BASES_500X','PCT_TARGET_BASES_1000X']]
    for i in range(0, len(df_HsMetrics)):
        pdf.cell(28, 5, '%s' % (df_HsMetrics['Sample'][i]), 1, 0,'C')
        pdf.cell(28, 5, '%.2f' % (df_HsMetrics['MEAN_TARGET_COVERAGE'][i]), 1, 0, 'C')
        pdf.cell(28, 5, '%s' % (str(df_HsMetrics['MAX_TARGET_COVERAGE'][i])), 1, 0, 'C')
        pdf.cell(20, 5, '%.2f' % (df_HsMetrics['PCT_TARGET_BASES_100X'][i]), 1, 0, 'C')
        pdf.cell(20, 5, '%.2f' % (df_HsMetrics['PCT_TARGET_BASES_200X'][i]), 1, 0, 'C')
        pdf.cell(20, 5, '%.2f' % (df_HsMetrics['PCT_TARGET_BASES_300X'][i]), 1, 0, 'C')
        pdf.cell(20, 5, '%.2f' % (df_HsMetrics['PCT_TARGET_BASES_400X'][i]), 1, 0, 'C')
        pdf.cell(20, 5, '%.2f' % (df_HsMetrics['PCT_TARGET_BASES_500X'][i]), 1, 2, 'C')
        pdf.cell(-164)
    pdf.set_font('arial', '', 8)
    pdf.cell(120, 5,"Tabla 4: Métricas de cobertura en regiones targets", 0, 2, 'L')
    pdf.ln(5)
    pdf.set_font('arial', 'B', 12)
    pdf.cell(75, 10, "3.1.3- Amplitud de regiones blanco con cobertura mínima de 300X", 0, 2,'L')## REPORTE DE LA PODA DE DATOS
    pdf.ln(5)
    pdf.set_font('arial', 'B', 8)
    pdf.cell(28, 5, 'SAMPLE', 1, 0, 'C')
    pdf.cell(28, 5, 'Prom_pct_amp', 1, 0, 'C')
    pdf.cell(28, 5, 'Nº < 70 %', 1, 0, 'C')
    pdf.cell(28, 5, 'Nº < 80 %', 1, 0, 'C')
    pdf.cell(28, 5, 'Nº < 90 %', 1, 0, 'C')
    pdf.cell(28, 5, 'Nº < 100 %', 1, 2, 'C')
    pdf.cell(-140)
    pdf.set_font('arial', '', 8)
    #df_HsMetrics[['Sample', 'MEAN_TARGET_COVERAGE','MAX_TARGET_COVERAGE','PCT_TARGET_BASES_100X','PCT_TARGET_BASES_500X','PCT_TARGET_BASES_1000X']]
    for i in range(0, len(df_400X)):
        pdf.cell(28, 5, '%s' % (str(df_400X['Sample'][i])), 1, 0,'C')
        pdf.cell(28, 5, '%.2f' % (df_400X['pct'][i]), 1, 0, 'C')
        pdf.cell(28, 5, '%s' % (str(df_400X['70'][i])), 1, 0, 'C')
        pdf.cell(28, 5, '%s' % (str(df_400X['80'][i])), 1, 0, 'C')
        pdf.cell(28, 5, '%s' % (str(df_400X['90'][i])), 1, 0, 'C')
        pdf.cell(28, 5, '%s' % (str(df_400X['100'][i])), 1, 2, 'C')

        pdf.cell(-140)
    pdf.set_font('arial', '', 8)
    pdf.cell(120, 5,"Tabla 5: Número de regiones blanco que poseen menos del 80% una profundidad mínima de 300X. Estas métricas tambien se observan para un 70%,", 0, 2, 'L')
    pdf.cell(120, 5,"90% y 100% a un minimo de 300X. Para resultados de mejor calidad, se espera un bajo número de regiones a 80% a un minimo de 300X. El detalle", 0, 2, 'L')
    pdf.cell(120, 5,"de las regiones blanco se encuentra en los archivos excel y reporte complementario, generados por el pipeline TumorSec", 0, 2, 'L')

    pdf.ln(5)
    
    ################# PÁGINA 4 ################################################
    pdf.set_xy(0, 0)
    pdf.cell(-40)
    pdf.set_y(-15)
    # Select Arial italic 8
    pdf.set_font('Arial', 'I', 8)
    # Print centered page number
    pdf.cell(0, 10, 'Página %s - TumorSec - Laboratorio de Genómica del Cancer, Universidad de Chile. ' % pdf.page_no(), 0, 2, 'C')
    pdf.set_xy(0, 0)
    pdf.set_font('arial', 'B', 12)
    pdf.ln(10)
    pdf.image(logo, 10, 8, 33)
    pdf.ln(15)
    pdf.cell(-40)
    pdf.ln(5)
    ##### GRAFICO TRIMMING 
    pdf.set_font('arial', 'B', 12)
    pdf.cell(75, 10, "3.2.- Calidad de bases por posición en fastq R1 y R2 sin filtrar: FASTQC", 0, 2,'L')## REPORTE DE LA PODA DE DATOS.
    pdf.set_font('arial', '', 8)
    pdf.image(path_input+'/1_fastq/ALL_SAMPLES_L001_R1_001_fastqc/Images/per_base_quality.png', x = None, y = None, w = 100, h = 80, type = 'png', link = '')
    pdf.cell(120, 5,"Imagen 2: Descripción general del los valores de calidad para todos los fastq R1. Se observa un gráfico de cajas con la distribución", 0, 2, 'L')
    pdf.cell(120, 5,"de las calidades por posición en la lectura. Este gráfico permite observar si los datos tienen algún problema antes de realizar", 0, 2, 'L')
    pdf.cell(120, 5,"cualquier análisis posterior.", 0, 2, 'L')

    pdf.image(path_input+'/1_fastq/ALL_SAMPLES_L001_R2_001_fastqc/Images/per_base_quality.png', x = None, y = None, w = 100, h = 80, type = 'png', link = '')
    pdf.cell(120, 5,"Imagen 3: Descripción general del rango de valores de calidad para todos los fastq R2 en cada posición.", 0, 2, 'L')
   ##### TRIMMING METRICS 
    pdf.set_xy(0, 0)
    pdf.cell(-40)
    pdf.set_y(-15)
    # Select Arial italic 8
    pdf.set_font('Arial', 'I', 8)
    # Print centered page number
    pdf.cell(0, 10, 'Página %s - TumorSec - Laboratorio de Genómica del Cancer, Universidad de Chile. ' % pdf.page_no(), 0, 2, 'C')
    pdf.set_xy(0, 0)
    pdf.set_font('arial', 'B', 12)
    pdf.ln(10)
    pdf.image(logo, 10, 8, 33)
    pdf.ln(15)
    pdf.cell(-40)
    pdf.ln(5)
    pdf.cell(75, 10, "3.3.- Cantidad de lecturas antes y después del trimming:", 0, 2,'L')## REPORTE DE LA PODA DE DATOS.
    pdf.ln(5)
    pdf.image(output_plots+'/trimming.png', x = None, y = None, w = 100, h = 80, type = 'png', link = '')
    pdf.set_font('arial', '', 8)
    pdf.cell(120, 5,"Imagen 4: Representación gáfica del trimming de datos realizado por fastp", 0, 2, 'L')
    pdf.ln(5)
    pdf.set_font('arial', 'B', 12)
    pdf.cell(75, 10, "3.4.- Calidad de lecturas antes y después del trimming:", 0, 2,'L')## REPORTE DE LA PODA DE DATOS.
    pdf.image(output_plots+'/0quality_reads.png', x = None, y = None, w = 120, h = 80, type = 'png', link = '')
    pdf.set_font('arial', '', 8)
    pdf.cell(120, 5,"Imagen 5: Calidad promedio de lecturas por posición antes del trimming (R1)", 0, 2, 'L')
    pdf.ln(10)
    
    ###### TRIMMIG METRICS 2
    pdf.set_xy(0,0)
    pdf.cell(-40)
    pdf.set_y(-15)
    # Select Arial italic 8
    pdf.set_font('Arial', 'I', 8)
    # Print centered page number
    pdf.cell(0, 10, 'Página %s - TumorSec - Laboratorio de Genómica del Cancer, Universidad de Chile. ' % pdf.page_no(), 0, 2, 'C')
    pdf.set_xy(0, 0)
    pdf.set_font('arial', 'B', 12)
    pdf.ln(10)
    pdf.image(logo, 10, 8, 33)
    pdf.ln(5)
    pdf.cell(-40)
    pdf.ln(5)
    pdf.set_font('arial', '', 8)
    pdf.image(output_plots+'/1quality_reads.png', x = None, y = None, w = 120, h = 80, type = 'png', link = '')
    pdf.cell(120, 5,"Imagen 6: Calidad promedio de lecturas por posición antes del trimming (R2)", 0, 2, 'L')
    pdf.image(output_plots+'/2quality_reads.png', x = None, y = None, w = 120, h = 80, type = 'png', link = '')
    pdf.cell(120, 5,"Imagen 7: Calidad promedio de lecturas por posición después del trimming (R1)", 0, 2, 'L')
    pdf.image(output_plots+'/3quality_reads.png', x = None, y = None, w = 120, h = 80, type = 'png', link = '')
    pdf.cell(120, 5,"Imagen 8:  Calidad promedio de lecturas por posición después del trimming (R2)", 0, 2, 'L')
    #pdf.cell(120, 5,"Imagen 2: Esta Imagen hay que integrarla al script", 0, 2, 'L')

    #########3.3.- Porcentaje de duplicados:
    pdf.set_xy(0, 0)
    pdf.cell(-40)
    pdf.set_y(-15)
    # Select Arial italic 8
    pdf.set_font('Arial', 'I', 8)
    # Print centered page number
    pdf.cell(0, 10, 'Página %s - TumorSec - Laboratorio de Genómica del Cancer, Universidad de Chile. ' % pdf.page_no(), 0, 2, 'C')
    pdf.set_xy(0, 0)
    pdf.set_font('arial', 'B', 12)
    pdf.ln(10)
    pdf.image(logo, 10, 8, 33)
    pdf.ln(10)
    pdf.cell(-40)
    pdf.ln(5)
    pdf.set_font('arial', 'B', 12)
    pdf.cell(75, 10, "3.5.- Porcentaje de duplicados y tamaño del inserto", 0, 2,'L')## REPORTE DE LA PODA DE DATOS.
    pdf.ln(5)
    pdf.image(output_plots+'/dedup.png', x = None, y = None, w = 100, h = 90, type = 'png', link = '')
    pdf.set_font('arial', '', 8)
    pdf.cell(120, 5,"Imagen 9: Porcentaje de lecturas duplicadas, estas son marcadas e ignoradas en el llamado de variantes", 0, 2, 'L')
    pdf.ln(10)
    pdf.image(path_input+'/multiqc_plots/png/mqc_qualimap_insert_size_1.png', x = None, y = None, w = 150, h = 50, type = 'png', link = '')
    pdf.cell(120, 5,"Imagen 10: Histograma de distribución del tamaño del inserto. Métricas obtenidas por qualimap", 0, 2, 'L')
    pdf.ln(10)

    #########3.4.- Porcentaje de lecturas on-target y profundidad:
    pdf.set_xy(0, 0)
    pdf.cell(-40)
    pdf.set_y(-15)
    # Select Arial italic 8
    pdf.set_font('Arial', 'I', 8)
    # Print centered page number
    pdf.cell(0, 10, 'Página %s - TumorSec - Laboratorio de Genómica del Cancer, Universidad de Chile. ' % pdf.page_no(), 0, 2, 'C')
    pdf.set_xy(0, 0)
    pdf.set_font('arial', 'B', 12)
    pdf.ln(10)
    pdf.image(logo, 10, 8, 33)
    pdf.ln(15)
    pdf.cell(-40)
    pdf.ln(5)
    pdf.set_font('arial', 'B', 12)
    pdf.cell(75, 10, "3.6.- Porcentaje de lecturas on-target y profundidad:", 0, 2,'L')## REPORTE DE LA PODA DE DATOS.
    pdf.image(output_plots+'/pct_reads_ontarget.png', x = None, y = None, w = 100, h = 80, type = 'png', link = '')
    pdf.set_font('arial', '', 8)
    pdf.cell(120, 5,"Imagen 11: Porcentaje de lecturas que se encuentran en regiones blancos por muestra", 0, 2, 'L')
    pdf.ln(10)
    pdf.image(output_plots+'/promedio_profundidad.png', x = None, y = None, w = 100, h = 80, type = 'png', link = '')
    pdf.set_font('arial', '', 8)
    pdf.cell(120, 5,"Imagen 12: Promedio de profundidad por muestras en regiones targets", 0, 2, 'L')

    #########3.4.- Porcentaje de lecturas on-target y profundidad:
    pdf.set_xy(0, 0)
    pdf.cell(-40)
    pdf.set_y(-15)
    # Select Arial italic 8
    pdf.set_font('Arial', 'I', 8)
    # Print centered page number
    pdf.cell(0, 10, 'Página %s - TumorSec - Laboratorio de Genómica del Cancer, Universidad de Chile. ' % pdf.page_no(), 0, 2, 'C')
    pdf.set_xy(0, 0)
    pdf.set_font('arial', 'B', 12)
    pdf.ln(10)
    pdf.image(logo, 10, 8, 33)
    pdf.ln(15)
    pdf.cell(-40)
    pdf.ln(5)
    pdf.set_font('arial', 'B', 12)
    pdf.cell(75, 10, "3.6.- Uniformidad, intervalos con profundidad definida, bases con profundidad definida:", 0, 2,'L')## REPORTE DE LA PODA DE DATOS.
    pdf.image(output_plots+'/uniformity.png', x = None, y = None, w = 100, h = 80, type = 'png', link = '')
    pdf.set_font('arial', '', 8)
    pdf.cell(120, 5,"Imagen 13: Uniformidad de cobertura promedio de la corrida", 0, 2, 'L')
    pdf.image(output_plots+'/cobertura_promedio_por_rangos.png', x = None, y = None, w = 100, h = 80, type = 'png', link = '')
    pdf.set_font('arial', '', 8)
    pdf.cell(120, 5,"Imagen 14: Cantidad de coberturas promedio por rango para cada muestra", 0, 2, 'L')
    pdf.image(output_plots+'/pct_coverage_all.png', x = None, y = None, w = 150, h = 60, type = 'png', link = '')
    pdf.set_font('arial', '', 8)
    pdf.cell(120, 5,"Imagen 15: porcentaje de bases con cobertura en un rango de 100X-1000X", 0, 2, 'L')
    pdf.ln(10)

    pdf.set_xy(0, 0)
    pdf.cell(-40)
    pdf.set_y(-15)
    # Select Arial italic 8
    pdf.set_font('Arial', 'I', 8)
    # Print centered page number
    pdf.cell(0, 10, 'Página %s - TumorSec - Laboratorio de Genómica del Cancer, Universidad de Chile. ' % pdf.page_no(), 0, 2, 'C')
    pdf.set_xy(0, 0)
    pdf.set_font('arial', 'B', 12)
    pdf.ln(10)
    pdf.image(logo, 10, 8, 33)
    pdf.ln(15)
    pdf.cell(75, 20, "4. Cobertura de bases por cada gen target ", 0, 2,'L')## REPORTE DE LA PODA DE DATOS
    pdf.set_font('arial', '', 10)
    pdf.cell(90, 8,"Cobertura de las regiones blanco por gen. Se  agruparon las regiones blancos por gen target y se calcularon los porcentajes", 0, 1, 'L')
    pdf.cell(90, 8,"de bases que poseen una cobertura mayor o igual a 100X, 300X, 400X y 500X. Esta información, ademas se encuentra", 0, 1, 'L')
    pdf.cell(90, 8,"por muestra en el reporte suplementario del pipeline TumorSec.", 0, 1, 'L')


    #pdf.cell(90, 8,"", 0, 1, 'L') 
    pdf.cell(-40)
    pdf.ln(5)
    pdf.image(output_plots+'/100x.png', x = None, y = None, w = 100, h = 80, type = 'png', link = '')
    pdf.set_font('arial', '', 8)
    pdf.cell(120, 5,"Imagen 16: Porcentaje de bases targets que poseen una cobertura mayor o igual a 100X", 0, 2, 'L')
    pdf.image(output_plots+'/300x.png', x = None, y = None, w = 100, h = 80, type = 'png', link = '')
    pdf.cell(120, 5,"Imagen 17: Porcentaje de bases targets que poseen una cobertura mayor o igual a 300X", 0, 2, 'L')
    pdf.image(output_plots+'/400x.png', x = None, y = None, w = 100, h = 80, type = 'png', link = '')
    pdf.cell(120, 5,"Imagen 18: Porcentaje de bases targets que poseen una cobertura mayor o igual a 400X", 0, 2, 'L')
    pdf.image(output_plots+'/500x.png', x = None, y = None, w = 100, h = 80, type = 'png', link = '')
    pdf.cell(120, 5,"Imagen 19: Porcentaje de bases targets que poseen una cobertura mayor o igual a 500X", 0, 2, 'L')

    pdf.output(output_pdf+'/Reporte_corrida'+corrida+'.pdf', 'F')
    print("Reporte PDF con las métricas de calidad de la corrida ---> LISTO !!")

def plot_uniformity(path_input,list_uniformity,color,samples):
    list_uniformity=sort_dataframe(list_uniformity)
    with plt.style.context('bmh'):
        ind = np.arange(len(samples))    # the x locations for the groups
        width = 0.8       # the width of the bars: can also be len(x) sequence
        color=cm.gist_earth(np.linspace(0,1,len(samples)))
        p6 = plt.bar(ind,list_uniformity, width,bottom=0, color=color)# #861307

        plt.ylabel('PORCENTAJE')
        plt.xlabel('MUESTRAS')
        plt.title('PORCENTAJE DE UNIFORMIDAD DE REGIONES BLANCO')
        plt.xticks(ind, samples, rotation='vertical')
        plt.savefig(output_plots+'/uniformity.png',figsize=(50,50),dpi=200, bbox_inches = "tight")
        plt.clf()
        print("Gráfico de uniformidad ---> LISTO !!")

def main():

    parser = argparse.ArgumentParser(description='Script crea reporte de calidad de la corrida, como parte de TumorSec Pipeline')
    parser.add_argument('-i', '--input', help='ruta de carpeta de entrada', required='True')
    parser.add_argument('-s', '--samples', nargs='+', help='lista ID de muestras', required='True')
    parser.add_argument('-l', '--logo', help='Imagen logo laboratorio', required='True')
    parser.add_argument('-m', '--img', help='Carpteta de salida de los plots', required='True')
    parser.add_argument('-opdf', '--outputpdf', help='Carpteta de salida del reporte en PDF', required='True')
    parser.add_argument('-ocov', '--ocov', help='Carpteta de salida archivo de cobertura por region target', required='True')
    parser.add_argument('-kit', '--kit', help='Información del kit de secuenciación', required='True')


    args=parser.parse_args()

    path_input =args.input
    samples = args.samples
    logo = args.logo
    output_coverage = args.ocov
    output_plots = args.img
    output_pdf = args.outputpdf
    kit = args.kit

    corrida=path_input.split('/')[-1]
    data =path_input+"/multiqc_data/multiqc_data.json"
    prom=[]
    with open(data) as json_data:
        data = json.load(json_data)
        p=pd.DataFrame(data['report_general_stats_data'][2])# id': 'fastp_filtered_reads_plot'
        print(p)

    df_before = pd.DataFrame(p.iloc[15,])
    print("ANTES")
    print(df_before)
    df_after = pd.DataFrame(p.iloc[6,])
    print("DESPUES")
    print(df_after)
    df_trimming_metrics=pd.merge(df_before, df_after, left_index=True, right_index=True)
    df_trimming_metrics.reset_index(drop=False, inplace=True)
    df_trimming_metrics.columns=['Sample','Reads_before_trimming','Reads_after_trimming']
    
    for i in range(df_trimming_metrics.shape[0]):
        df_trimming_metrics['Sample'][i]=('_').join(df_trimming_metrics['Sample'][i].split('_')[0:2])
        prom.append(100-(df_trimming_metrics['Reads_after_trimming'][i]*100/df_trimming_metrics['Reads_before_trimming'][i]))
    
    df_trimming_metrics.insert(3,'pct_trimmed_reads',prom,True)   
    print(df_trimming_metrics)
    count=df_trimming_metrics.shape[0]
    n=df_trimming_metrics.shape[0]
    color=cm.gist_earth(np.linspace(0,1,n))

    #### CREAMOS Y GUARDAMOS PLOTS TRIMMING
    plot_trimming(output_plots,df_trimming_metrics)

    ############# INFORMACION DE READS DUPLICADOS ##################
    data_dedup=path_input+"/multiqc_data/multiqc_picard_dups.txt"
    dedup_metrics = pd.read_csv(data_dedup,delimiter='\t', skip_blank_lines=True)
    df_dedup_metrics = pd.DataFrame(dedup_metrics)
    count=df_dedup_metrics.shape[0]

    for i in range(count):
        df_dedup_metrics['PERCENT_DUPLICATION'][i] = (df_dedup_metrics['PERCENT_DUPLICATION'][i])*100

    df_dedup_metrics=df_dedup_metrics.drop(['LIBRARY', 'UNPAIRED_READS_EXAMINED', 'READ_PAIRS_EXAMINED','SECONDARY_OR_SUPPLEMENTARY_RDS', 'UNMAPPED_READS','UNPAIRED_READ_DUPLICATES','READ_PAIR_DUPLICATES','ESTIMATED_LIBRARY_SIZE','READ_PAIR_OPTICAL_DUPLICATES'], axis=1)
    ### CREAMOS GRAFICO DE DUPLICADOS
    plot_dedup(output_plots,df_dedup_metrics,color)

    #### TRIMMING + DUPLICADOS
    df_merge1=df_trimming_metrics.merge(df_dedup_metrics, on='Sample')
    print (df_merge1)

    ############ READS EN REGIONES ON-TARGETS
    list_ontarget = [['Sample','total_reads','on_target','pc_ontarget']]

    for sample in samples:
        data=path_input+"/TMP_dedup/"+sample+".ontarget.txt"
        try:
        	ontarget = pd.read_csv(data,header=None, delim_whitespace=True)
        	
        except pd.io.common.EmptyDataError:
        	df = pd.DataFrame()
        	
        print(ontarget)
        lis=[sample,ontarget[0][1],ontarget[0][0],float((ontarget[0][0]*100)/ontarget[0][1])]
        list_ontarget.append(lis)

    dfObj = pd.DataFrame(list_ontarget,columns=list_ontarget[0])
    df_ontarget=dfObj.drop([0], axis=0)

    #### CREAMOS PLOTS DE READS EN REGIONES TARGET
    plot_pct_ontarget(output_plots,df_ontarget,color)

    #####CALCULAMOS LA UNIFORMIDAD
    list_uniformity=[['Sample','pct_unifomity','mean_coverage']]

    for sample in samples:
        region_cov =""+path_input+"/TMP_dedup/"+sample+".mosdepth.regions.bed.gz"
        gzip_mosdepth=gzip.open(region_cov, 'rb')
        region_metrics = pd.read_csv(gzip_mosdepth,delimiter='\t', skip_blank_lines=True, header=None)

        #### CALCULAMOS EL PORCENTAJE DE UNIFORMIDAD.
        Lim_sup_uniformity=(region_metrics[4].median()*2) ### Limite superior de cobertura promedio
        Lim_inf_uniformity=(region_metrics[4].median()/2) ### Limite inferior de cobertura promedio
        #### Numero de regiones blancocon cobertura promedio entre [Lim_sup, Lim_inf]
        uniformity = sum(1 for i in region_metrics[4] if i < Lim_sup_uniformity and i > Lim_inf_uniformity)
        lis=[sample,(uniformity/326)*100, region_metrics[4].mean()]
        #df_ontarget.append(lis)
        list_uniformity.append(lis)

    dfObj = pd.DataFrame(list_uniformity,columns=list_uniformity[0])
    df_uniformity=dfObj.drop([0], axis=0)

    #### TRIMMING + DUPLICADOS + PROM COBERTURA + % UNIFORMIDAD
    df_merge2=df_merge1.merge(df_uniformity, on='Sample')
    #### TRIMMING + DUPLICADOS + PROM COBERTURA + % UNIFORMIDAD + READS ON_TARGET
    df_merge3=df_merge2.merge(df_ontarget, on='Sample')

    ##### GUARDAR METRICAS POR GEN TARGET DE CADA MUESTRA EN UN ARCHIVO DE SALIDA #######
    df_merge3.to_csv(output_coverage+'/tabla_resumen.csv',index=True, sep='\t')

    ### PLOTS DE PROMEDIO DE COVERTURA
    mean_coverage(output_plots,df_merge3,color)

    #### TABLA RESUMEN 2
    data=path_input+"/multiqc_data/multiqc_picard_HsMetrics.txt"
    HsMetrics = pd.read_csv(data,delimiter='\t', skip_blank_lines=True)
    df_HsMetrics = pd.DataFrame(HsMetrics)
    #recorrer por numero de filas
    count=df_HsMetrics.shape[0]
    for i in range(count):
        df_HsMetrics['Sample'][i]=df_HsMetrics['Sample'][i].split('.')[0]
        df_HsMetrics['PCT_TARGET_BASES_100X'][i]=(df_HsMetrics['PCT_TARGET_BASES_100X'][i]*100)
        df_HsMetrics['PCT_TARGET_BASES_200X'][i]=(df_HsMetrics['PCT_TARGET_BASES_200X'][i]*100)
        df_HsMetrics['PCT_TARGET_BASES_300X'][i]=(df_HsMetrics['PCT_TARGET_BASES_300X'][i]*100)
        df_HsMetrics['PCT_TARGET_BASES_400X'][i]=(df_HsMetrics['PCT_TARGET_BASES_400X'][i]*100)
        df_HsMetrics['PCT_TARGET_BASES_500X'][i]=(df_HsMetrics['PCT_TARGET_BASES_500X'][i]*100)
        df_HsMetrics['PCT_TARGET_BASES_600X'][i]=(df_HsMetrics['PCT_TARGET_BASES_600X'][i]*100)
        df_HsMetrics['PCT_TARGET_BASES_700X'][i]=(df_HsMetrics['PCT_TARGET_BASES_700X'][i]*100)
        df_HsMetrics['PCT_TARGET_BASES_800X'][i]=(df_HsMetrics['PCT_TARGET_BASES_800X'][i]*100)
        df_HsMetrics['PCT_TARGET_BASES_900X'][i]=(df_HsMetrics['PCT_TARGET_BASES_900X'][i]*100)
        df_HsMetrics['PCT_TARGET_BASES_1000X'][i]=(df_HsMetrics['PCT_TARGET_BASES_1000X'][i]*100)

    df_HSMETRICS=df_HsMetrics[['Sample','PCT_TARGET_BASES_100X','PCT_TARGET_BASES_200X','PCT_TARGET_BASES_300X','PCT_TARGET_BASES_400X','PCT_TARGET_BASES_500X']]
    #### CREAMOS EL PLOT DE PORCENTAJE DE BASES 100X,500X, 1000X
    df_auxHSMETRICS= df_HsMetrics[['Sample','PCT_TARGET_BASES_100X','PCT_TARGET_BASES_200X','PCT_TARGET_BASES_300X','PCT_TARGET_BASES_400X','PCT_TARGET_BASES_500X','PCT_TARGET_BASES_600X','PCT_TARGET_BASES_700X','PCT_TARGET_BASES_800X','PCT_TARGET_BASES_900X','PCT_TARGET_BASES_1000X']]
    #plot_pct_bases100_500_1000(path_input,df_HSMETRICS,color)
    plot_pct_coverage(output_plots,df_auxHSMETRICS,color)

    ##### GUARDAR METRICAS POR GEN TARGET DE CADA MUESTRA EN UN ARCHIVO DE SALIDA ######
    df_HSMETRICS.to_csv(output_coverage+'/tabla_resumen2.csv',index=True, sep='\t')

    #### LEE LA INFORMACIÓN DE ENTRADA 0_DATA_INPUT
    baseSpace = pd.read_csv(kit,delimiter=',', skip_blank_lines=True, header=None)
    df_baseSpace = pd.DataFrame(baseSpace)
    df_baseSpace[1][3]
    
    ##interop
    data=output_coverage+"/interop_summary2.csv"
    metric_linea = pd.read_csv(data,delimiter=',', skip_blank_lines=True)
    interop2 = pd.DataFrame(metric_linea)
    interop2 = interop2.drop([1,2,3,5,6,7,9,10],axis=0)
    df_metric_linea = interop2.loc[0,['Density', 'ClusterPF']]

	##interop 
    data=output_coverage+"/interop_summary.csv"
    lect = pd.read_csv(data,delimiter=',', skip_blank_lines=True)
    interop1 = pd.DataFrame(lect)
    interop2.index = [0, 1, 2]
    
    print (interop1)
    print (interop2)
    df_metric_lect = pd.concat([interop1, interop2], axis=1, sort=False)

    data_400X=output_coverage+"/ALL_SAMPLES_300X.csv"
    n_400X = pd.read_csv(data_400X,delimiter=',', skip_blank_lines=True,header=None)
    df_400X = pd.DataFrame(n_400X)
    df_400X.columns = ['Sample','pct','70','80','90','100']
    
    df_merge3=sort_dataframe(df_merge3)
    df_HsMetrics=sort_dataframe(df_HsMetrics)
    df_400X=sort_dataframe(df_400X)
    pdf_report(corrida,path_input,output_pdf,df_baseSpace,df_metric_lect,df_metric_linea,df_merge3,df_HsMetrics,df_400X,logo,output_plots)
    print("REPORTE FINALIZADO CON EXITO !!")

if __name__ == '__main__':
   main()
