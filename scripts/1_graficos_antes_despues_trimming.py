#!/usr/bin/env python
import gzip
import numpy as np
import pandas as pd
import json
import argparse
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt


def main():

    parser = argparse.ArgumentParser(description='Script realiza los gráficos de calidad antes y despues del trimming')
    parser.add_argument('-i', '--input', help='ruta de carpeta de entrada', required='True')
    parser.add_argument('-o', '--output', help='ruta de carpeta de salida', required='True')

    args=parser.parse_args()

    path_input =args.input
    path_output =args.output
	
    ####### OBTENER CANTIDAD DE LECTURAS ANTES Y DESPUES DEL TRIMMING DE DATOS
    data =path_input+"/multiqc_data/multiqc_data.json"
    #/Users/evelin/Documents/190607_TumorSec/multiqc_data

    # Reading the json as a dict
    with open(data) as json_data:
        data = json.load(json_data)
        p=pd.DataFrame(data['report_plot_data']['fastp-seq-quality-plot-1']['datasets'])# id': 'fastp_filtered_reads_plot'
        N_fastp_graph=p.shape[0]
        N_samples=p.shape[1]
        for i in range(N_fastp_graph):### por cada grafico, R1, R2 antes del trimming y R1, R2 despues del trimming
            with plt.style.context('bmh'):
                name_samples=[]
                for x in range(N_samples): ### por cada muestra
                    quality_base=[]
                    pos_base=[]
                    name_samples.append(p.iloc[i].values[x]['name'].split('_')[0])
                    for w in range(len(p.loc[i].values[x]['data'])): ### por cada nucleotido del reads
                        pos_base.append(p.loc[i].values[x]['data'][w][0])
                        quality_base.append(p.loc[i].values[x]['data'][w][1])
                    #print(pos_base,quality_base,p.iloc[i].values[x]['name'])
                    #plt.figure(1)
                    #plt.subplot(211)
                    #print(pos_base)
                    plt.plot(pos_base,quality_base,label='linear')
            # Number of accent colors in the color scheme
            if(i==0):
                plt.title('Q PROMEDIO ANTES DEL TRIMMING (R1)')
            if(i==1):
                plt.title('Q PROMEDIO ANTES DEL TRIMMING (R2)')
            if(i==2):
                plt.title('Q PROMEDIO DESPUES DEL TRIMMING (R1)')
            if(i==3):
                plt.title('Q PROMEDIO DESPUES DEL TRIMMING (R2)')
        
            plt.ylim((0,43))
            plt.xlim((0,154))
        
            plt.xlabel('POSICION',fontsize=14)
            plt.ylabel('CALIDAD',fontsize=14)
            plt.xscale('linear',linthreshy=10)
            plt.yscale('linear')
            plt.legend(name_samples, loc='center left', bbox_to_anchor=(1, 0.5))
            plt.savefig(path_output+'/'+str(i)+'quality_reads.png',figsize=(50,100),dpi=200, bbox_inches = "tight")
            plt.clf()
            print("Gráfico Nº "+str(i)+" del trimming de datos listo!!")


if __name__ == '__main__':
   main()





