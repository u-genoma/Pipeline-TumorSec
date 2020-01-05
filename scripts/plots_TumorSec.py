#!/usr/bin/env python
# coding: utf-8
#/usr/bin/python
########################################################################################################################
#  15/06/2019
#  EVELIN GONZALEZ FELIU
#
#  python plots_TumorSec.py -i /Users/evelin/Desktop/TUMORSEC -o /Users/evelin/Desktop/TUMORSEC -s 11682_S10 159078_S5 165553_S2 171425_S7 180569_S6 218190_S9 157980_S8 164356_S1 170927_S11 174656_S3 191012_S4
#
#  DESCRIPCION: Este programa forma parte del Pipeline de TumorSec, genera los gráficos de uniformidad y coberturas
#  por rango definido.
########################################################################################################################
import gzip
import numpy as np
import pandas as pd # to use of dataframe data structure
from fpdf import FPDF
import matplotlib.pyplot as plt
from pylab import title, figure, xlabel, ylabel, xticks, bar, legend, axis, savefig
from matplotlib import cm

##### GRAFICO DE UNIFORMIDAD DE COBERTURA. 
###guardar archivos de metricas por gen para cada muestra  en carpeta. 5_metrics 5.1_plots 5.2_reports 5.3_output_gen_coverage 
##### Contadores de cobertura promedio de regiones blancos por rango.
list_r_50=[]
list_r50_100=[]
list_r100_500=[]
list_r500_1000=[]
list_r_1000=[]
list_uniformity=[]

#samples=['PUCOv001_S1', 'PUCOv002_S2', 'PUCOv003_S3', 'PUCOv004_S4', 'PUCOv006_S5', 'PUCOv007_S6', 'PUCOv008_S7', 'PUCOv010_S8','Undetermined_S0']
#path_input='/Users/evelin/Documents/190610_TumorSec'

def plot_uniformity(list_uniformity):

    with plt.style.context('bmh'):
        ind = np.arange(len(samples))    # the x locations for the groups
        width = 0.8       # the width of the bars: can also be len(x) sequence
       
        color=cm.gist_earth(np.linspace(0,1,len(samples)))
        p6 = plt.bar(ind,list_uniformity, width,bottom=0, color=color)# #861307

        plt.ylabel('PORCENTAJE')
        plt.xlabel('MUESTRAS')
        plt.title('PORCENTAJE DE UNIFORMIDAD DE REGIONES BLANCO')
        plt.xticks(ind, samples, rotation='vertical')
        plt.savefig(path_input+'/5_metrics/5.1_plots/uniformity.png',figsize=(50,50),dpi=200, bbox_inches = "tight")
        plt.clf()

def plot_by_ranges(path_input):
    with plt.style.context('bmh'):
        ind = np.arange(len(samples))    # the x locations for the groups
        width = 0.9       # the width of the bars: can also be len(x) sequence
        p1 = plt.bar(ind,list_r_1000, width,bottom=[list_r50_100[j]+list_r100_500[j]+list_r500_1000[j]+list_r_50[j] for j in range(len(list_r100_500))], edgecolor='black',color='#F8F5A4')
        p2 = plt.bar(ind,list_r500_1000, width,bottom=[list_r50_100[j]+list_r100_500[j]+list_r_50[j] for j in range(len(list_r100_500))], edgecolor='black', color='#F9B767')# #861307
        p3 = plt.bar(ind,list_r100_500, width,bottom=[list_r50_100[j]+list_r_50[j] for j in range(len(list_r_50))], edgecolor='black', color='#FD8D05')# #861307 #F9B767  
        p4 = plt.bar(ind,list_r50_100, width,bottom=list_r_50, edgecolor='black', color='#D23803')# #861307
        p5 = plt.bar(ind,list_r_50,width,bottom=0, edgecolor='black', color='#A13814')# #861307

        plt.ylabel('NÚMERO DE REGIONES BLANCO')
        plt.xlabel('MUESTRAS')
        plt.title('CANTIDAD DE REGIONES BLANCO CON COBERTURA PROMEDIO POR UMBRAL')
        plt.xticks(ind, samples, rotation='vertical')
        plt.legend((p1[0], p2[0],p3[0],p4[0],p5[0]), ('>1000', '500-1000','100-500','50-100','<50'), loc='center left',  bbox_to_anchor=(1, 0.5))
        plt.savefig(path_input+'/5_metrics/5.1_plots/cobertura_promedio_por_rangos.png',figsize=(50,50),dpi=200, bbox_inches = "tight")
        plt.clf()
        
def main():
	parser = argparse.ArgumentParser(description='script genera graficos de uniformidad y cobertura por rango para todas las muestras')
	parser.add_argument('-i', '--input', help='ruta de carpeta de entrada', required='True')
	parser.add_argument('-o', '--output', help='Carpteta de salida', required='True')
	parser.add_argument('-s', '--samples', nargs='+', help='lista ID de muestras', required='True')

	args=parser.parse_args()

	path_input=args.input
	samples = args.samples
	output=args.output
    
 	for sample in samples:
 	
 		region_cov =""+path_input+"/4_dedup/"+sample+".mosdepth.regions.bed.gz"
    	gzip_mosdepth=gzip.open(region_cov, 'rb')
    	region_metrics = pd.read_csv(gzip_mosdepth,delimiter='\t', skip_blank_lines=True, header=None)

    	r_50 = sum(1 for i in region_metrics[4] if i < 50)
    	r50_100 = sum(1 for i in region_metrics[4] if i >= 50 and i < 100)
    	r100_500 = sum(1 for i in region_metrics[4] if i >=100 and i <500)
    	r500_1000 = sum(1 for i in region_metrics[4] if i >= 500 and i <1000)
    	r_1000 = sum(1 for i in region_metrics[4] if i >1000)

    	### verificar en que rango se encuentra el promedio de covertura por region targets (325 regiones, arcihvo bed)
    	list_r_50.append(r_50)
    	list_r50_100.append(r50_100)
    	list_r100_500.append(r100_500)
    	list_r500_1000.append(r500_1000)
    	list_r_1000.append(r_1000)
    
    	#### CALCULAMOS EL PORCENTAJE DE UNIFORMIDAD. 
    	Lim_sup_uniformity=(region_metrics[4].median()*2) ### Limite superior de cobertura promedio
    	Lim_inf_uniformity=(region_metrics[4].median()/2) ### Limite inferior de cobertura promedio
    	#### Numero de regiones blancocon cobertura promedio entre [Lim_sup, Lim_inf]
    	uniformity = sum(1 for i in region_metrics[4] if i < Lim_sup_uniformity and i > Lim_inf_uniformity)
    	list_uniformity.append((uniformity/326)*100) ## Calcula el porcentaje de regiones en el rango con respecro al total.

	plot_uniformity(list_uniformity)
	plot_by_ranges(path_input)
    
if __name__ == '__main__':
   main()



