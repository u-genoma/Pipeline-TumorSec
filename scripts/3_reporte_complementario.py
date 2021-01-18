#!/usr/bin/env python
# coding: utf-8
#/usr/bin/python
########################################################################################################################
#  09/06/2019
#  EVELIN GONZALEZ FELIU
#
# python Reporte_complementario.py -i /home/egonzalez/workSpace/runs_TumorSec/190617_TumorSec -o /home/egonzalez/workSpace/runs_TumorSec/190617_TumorSec -s PUCOv013_S1 PUCOv014_S2 PUCOv015_S3 PUCOv016_S4 PUCOv017_S5 PUCOv018_S6 PUCOv019_S7 PUCOv020_S8 Undetermined_S0
#
#  DESCRIPCION: Este programa es parte del pipeline TumorSec. Produce un reporte PDF con las metricas de cobertura por gen target
#  Utiizando la salida de PICARD CollectHSMetrics y la salida de Mosdepth para los graficos de % de números de
#  regiones targets con cobertura promedio <50, 50-100,100-500,500-1000, <1000
#
########################################################################################################################

import gzip
import numpy as np
import pandas as pd
from fpdf import FPDF
import matplotlib
import matplotlib.pyplot as plt
from pylab import title, figure, xlabel, ylabel, xticks, bar, legend, axis, savefig
import argparse
import csv # to import csv files
import sys
plt.switch_backend('agg')

def sort_dataframe(df_input): 
    df_input[['aux_nombre','orden']] = df_input['Sample'].str.split('_S',expand=True)
    df_input["orden"] = pd.to_numeric(df_input["orden"])
    df_input=df_input.sort_values(by='orden', ascending=True)
    df_input.set_index('orden',inplace=True)
    df_input.reset_index(inplace=True)
    df_input=df_input.drop(['aux_nombre', 'orden'], axis=1)

    
    return df_input

def heatmap(datos, genes, samples, ax=None, #row_labels=genes col_labels=samples
            cbar_kw={}, cbarlabel="", **kwargs):

    if not ax:
        ax = plt.gca()

    # Plot the heatmap
    im = ax.imshow(datos, **kwargs, vmax=100, vmin=0, aspect='auto')

    # Create colorbar
    cbar = ax.figure.colorbar(im, ax=ax, **cbar_kw)
    cbar.ax.set_ylabel(cbarlabel, rotation=-90, va="bottom")

    # We want to show all ticks...
    ax.set_xticks(np.arange(datos.shape[1]))
    ax.set_yticks(np.arange(datos.shape[0]))
    # ... and label them with the respective list entries.
    ax.set_xticklabels(genes,fontsize=15, rotation=0)
    ax.set_yticklabels(samples, fontsize=15, rotation=0)

    # Let the horizontal axes labeling appear on top.
    ax.tick_params(top=True, bottom=False,
                   labeltop=True, labelbottom=False)

    # Rotate the tick labels and set their alignment.
    plt.setp(ax.get_xticklabels(), rotation=-60, ha="right",
             rotation_mode="anchor")

    # Turn spines off and create white grid.
    for edge, spine in ax.spines.items():
        spine.set_visible(False)

    ax.set_xticks(np.arange(datos.shape[1]+1)-.5, minor=True)
    ax.set_yticks(np.arange(datos.shape[0]+1)-.5, minor=True)
    ax.grid(which="major", color="w", linestyle='-', linewidth=0)
    ax.tick_params(which="minor", bottom=False, left=False)

    return im, cbar

def plot_100X(genes_100X,merge_df_metrics,samples,output_plots):
    fig, ax = plt.subplots()

    im, cbar = heatmap(np.array(genes_100X), list(merge_df_metrics.index.values),list(samples), ax=ax,
                    cmap="YlGn", cbarlabel="porcentaje de bases")

    fig.tight_layout(pad=-8)
    fig.savefig(output_plots+'/100x.png',figsize=(50,50),dpi=200, bbox_inches = "tight")


def plot_300X(genes_300X, merge_df_metrics,samples,output_plots):
    fig, ax = plt.subplots()

    im, cbar = heatmap(np.array(genes_300X), list(merge_df_metrics.index.values),list(samples), ax=ax,
                   cmap="YlGn", cbarlabel="porcentaje de bases")

    fig.tight_layout(pad=-8)
    fig.savefig(output_plots+'/300x.png', figsize=(50,50),dpi=200, bbox_inches = "tight")
    
def plot_400X(genes_400X, merge_df_metrics,samples,output_plots):
    fig, ax = plt.subplots()

    im, cbar = heatmap(np.array(genes_400X), list(merge_df_metrics.index.values),list(samples), ax=ax,
                   cmap="YlGn", cbarlabel="porcentaje de bases")

    fig.tight_layout(pad=-8)
    fig.savefig(output_plots+'/400x.png',figsize=(50,50),dpi=200, bbox_inches = "tight")

def plot_500X(genes_500X, merge_df_metrics,samples,output_plots):
    fig, ax = plt.subplots()

    im, cbar = heatmap(np.array(genes_500X), list(merge_df_metrics.index.values),list(samples), ax=ax,
                   cmap="YlGn", cbarlabel="porcentaje de bases")

    fig.tight_layout(pad=-8)
    fig.savefig(output_plots+'/500x.png',figsize=(50,50),dpi=200, bbox_inches = "tight")


def main():

    genes_100X=[]
    genes_300X=[]
    genes_400X=[]
    genes_500X=[]

    #pdf = FPDF()
    parser = argparse.ArgumentParser(description='Script que produce reporte PDF complementario, con métricas de cobertura por gen target')

    parser.add_argument('-i', '--input', help='ruta de carpeta de entrada (DEDUP)', required='True')
    parser.add_argument('-opdf', '--outputpdf', help='Carpteta de salida del reporte en PDF', required='True')
    parser.add_argument('-m', '--img', help='Carpteta de salida de los plots', required='True')
    parser.add_argument('-ocov', '--ocov', help='Carpteta de salida archivo de cobertura por region target', required='True')
    parser.add_argument('-l', '--logo', help='Imagen logo laboratorio', required='True')

    parser.add_argument('-s', '--samples', nargs='+', help='lista ID de muestras', required='True')

    args=parser.parse_args()

    input = args.input
    samples = args.samples
    logo = args.logo
    output_coverage = args.ocov
    output_plots = args.img
    output_pdf = args.outputpdf
    
    pdf = FPDF()
    
    df_samples = pd.DataFrame(samples,columns = ['Sample'])
    df_samples = sort_dataframe(df_samples)
    samples = df_samples['Sample'].tolist()

    print(len(samples))
    for sample in samples:
        data_target_cov =""+input+"/"+sample+".target_coverage.txt"
        target_metrics = pd.read_csv(data_target_cov,delimiter='\t', skip_blank_lines=True)
        df_target_metrics = pd.DataFrame(target_metrics)

        #delete columns of dataframe
        df_target_metrics.drop(['start', 'end', '%gc','normalized_coverage', 'min_normalized_coverage','max_normalized_coverage','pct_0x'], axis=1)
        #aux_target_metrics=df_target_metrics

        count=df_target_metrics.shape[0]

        for i in range(count):
            df_target_metrics['name'][i]=df_target_metrics['name'][i].split('-')[0]

        df1 = df_target_metrics[['name','read_count','length']]
        df2 = df_target_metrics[['name','mean_coverage']]
        df3 = df_target_metrics[['name','min_coverage']]
        df4 = df_target_metrics[['name','max_coverage']]

        df1=df1.groupby(['name']).sum()
        df2=df2.groupby(['name']).mean()

        df3=df3.groupby(['name']).min()
        df4=df4.groupby(['name']).max()

        #df_row = df2.merge(df1, on='name')
        df_row=df1.merge(df2, on='name')
        df_row2= df3.merge(df_row, on='name')
        df_row3= df4.merge(df_row2, on='name')

        # change to ""+sample+"mosdepth.thresholds.bed.gz"
        mosdepth =input+"/"+sample+".mosdepth.thresholds.bed.gz"
        gzip_mosdepth=gzip.open(mosdepth, 'rb')

        target_metrics_mosdepth = pd.read_csv(gzip_mosdepth,delimiter='\t', skip_blank_lines=True)
        df_target_metrics_mosdepth = pd.DataFrame(target_metrics_mosdepth)
        count=df_target_metrics_mosdepth.shape[0]
        aux=df_target_metrics_mosdepth.rename(columns={'region':'name'}, inplace=True)

        for i in range(count):
            df_target_metrics_mosdepth['name'][i]=df_target_metrics_mosdepth['name'][i].split('-')[0]
            df_target_metrics_mosdepth['end'][i]=(df_target_metrics_mosdepth['end'][i]-df_target_metrics_mosdepth['start'][i])


        df_mosdepth=df_target_metrics_mosdepth.groupby(['name']).sum()
        merge_df_metrics= df_mosdepth.merge(df_row3, on='name')
        #merge_df_metrics

        count=merge_df_metrics.shape[0]
        ## Calculamos el procentaje de reads con cobertura igual o mayor a 100X, 500X y 1000X
        merge_df_metrics['pct_100X']= ''
        merge_df_metrics['pct_300X']= ''
        merge_df_metrics['pct_400X']= ''
        merge_df_metrics['pct_500X']= ''
        for i in range(count):
            merge_df_metrics['pct_100X'][i] = float(merge_df_metrics['100X'][i]*100/merge_df_metrics['end'][i])
            merge_df_metrics['pct_300X'][i] = float(merge_df_metrics['300X'][i]*100/merge_df_metrics['end'][i])
            merge_df_metrics['pct_400X'][i] = float(merge_df_metrics['400X'][i]*100/merge_df_metrics['end'][i])
            merge_df_metrics['pct_500X'][i] = float(merge_df_metrics['500X'][i]*100/merge_df_metrics['end'][i])

        merge_df_metrics=merge_df_metrics.drop(['start', '100X','300X','400X','500X'], axis=1)

        genes_100X.append(list(merge_df_metrics['pct_100X'].values))
        genes_300X.append(list(merge_df_metrics['pct_300X'].values))
        genes_400X.append(list(merge_df_metrics['pct_400X'].values))
        genes_500X.append(list(merge_df_metrics['pct_500X'].values))

        ##### GUARDAR METRICAS POR GEN TARGET DE CADA MUESTRA EN UN ARCHIVO DE SALIDA #######
        merge_df_metrics.to_csv(output_coverage+'/'+sample+'_region_metrics.csv',index=True, sep='\t') 
        #PDF_complement_report(merge_df_metrics,output,sample)
        pdf.add_page()
        pdf.set_xy(0,0)
        pdf.set_font('arial', 'B', 12)
        pdf.ln(20)
        pdf.image(logo, 10, 8, 33)
        pdf.ln(5)
        pdf.cell(100, 10, "Reporte TumorSec: Muestra "+sample, 0, 2, 'L') 
        pdf.cell(-40)
        pdf.ln(5)
        pdf.set_font('arial', 'B', 6)
        pdf.cell(23, 5, 'Gen', 1, 0, 'C')
        pdf.cell(23, 5, 'Max coverage', 1, 0, 'C')
        pdf.cell(23, 5, 'Min coverage', 1, 0, 'C')
        pdf.cell(23, 5, 'Length', 1, 0, 'C')
        pdf.cell(23, 5, 'Mean coverage', 1, 0, 'C')
        pdf.cell(23, 5, 'pct 300X', 1, 0, 'C')
        pdf.cell(23, 5, 'pct 400X', 1, 0, 'C')
        pdf.cell(23, 5, 'pct 500X', 1, 2, 'C')
        pdf.cell(-161)
        pdf.set_font('arial', '', 6)
        for i in range(0, len(merge_df_metrics)):
        	#pdf.cell(30, 5, '%s' % (merge_df_metrics['name'].ix[i]), 1, 0, 'C')
        	pdf.cell(23, 5, '%s' % (str(merge_df_metrics.index[i])), 1, 0, 'C')
        	pdf.cell(23, 5, '%.2f' % (merge_df_metrics['max_coverage'][i]), 1, 0, 'C')
        	pdf.cell(23, 5, '%.2f' % (merge_df_metrics['min_coverage'][i]), 1, 0, 'C')
        	pdf.cell(23, 5, '%s' % (str(merge_df_metrics['length'][i])), 1, 0, 'C')
        	pdf.cell(23, 5, '%.2f' % (merge_df_metrics['mean_coverage'][i]), 1, 0, 'C')
        	pdf.cell(23, 5, '%.2f' % (merge_df_metrics['pct_300X'][i]), 1, 0, 'C')
        	pdf.cell(23, 5, '%.2f' % (merge_df_metrics['pct_400X'][i]), 1, 0, 'C')
        	pdf.cell(23, 5, '%.2f' % (merge_df_metrics['pct_500X'][i]), 1, 2, 'C')
        	pdf.cell(-161)	
        pdf.ln(5)
        pdf.set_font('arial', '', 8)
        pdf.cell(120, 5,"Métricas de cobertura de regiones blanco agrupadas por gen para una muestra. Gen: gen blanco. Max coverage: máximo de cobertura del gen", 0, 2, 'L')
        pdf.cell(120, 5,"Min_coverage: cobertura mínima del gen. Length: número de pares de bases de la regiones blanco del gen. Mean coverage: promedio de cobertura", 0, 2, 'L')
        pdf.cell(120, 5,"pct 300X: porcentaje de la región con al menos 300X. pct 400X: porcentaje de la región con al menos 400X. pct 500X: porcentaje de la región con", 0, 2, 'L')
        pdf.cell(120, 5,"al menos 500X", 0, 2, 'L')

        pdf.add_page()
        pdf.set_xy(0,0)
        pdf.set_font('arial', 'B', 12)
        pdf.ln(20)
        pdf.image(logo, 10, 8, 33)
        pdf.ln(5)
        pdf.cell(100, 10, "Cobertura por region target: Muestra "+sample, 0, 2, 'L') 
        pdf.cell(-40)
        pdf.ln(5)
        pdf.image(output_plots+'/'+sample+'_coverage_by_targets_region.png', x = None, y = None, w = 180, h = 180, type = 'png', link = '')
        pdf.set_font('arial', '', 8)
        pdf.cell(120, 5,"Gráfico de cobertura de todas las regiones blanco para una muestra. En el eje Y se observa el porcentaje cubierto de la region blanco y en el eje X", 0, 2, 'L')
        pdf.cell(120, 5,"la profundidad mínima. La linea punteada, marca el 80% de la region blanco cubierta. Aquellas lineas que se encuentran etiquetadas, corresponden", 0, 2, 'L')
        pdf.cell(120, 5,"a las regiones bajo 80% a un mínimo de 300X. Aquellos gráficos que no poseen etiquetas, presentan 0 o más de 20 regiones bajo 80% a un mínimo", 0, 2, 'L')
        pdf.cell(120, 5,"de 300X", 0, 2, 'L')

        pdf.cell



    ## DESCRIPCION DEL HEADER EN EL FINAL DEL REPORTE
    pdf.output(output_pdf+'/Complement_report.pdf', 'F')

    plot_100X(genes_100X,merge_df_metrics,samples,output_plots)
    plot_300X(genes_300X,merge_df_metrics,samples,output_plots)
    plot_400X(genes_400X,merge_df_metrics,samples,output_plots)
    plot_500X(genes_500X,merge_df_metrics,samples,output_plots)

if __name__ == '__main__':
   main()





