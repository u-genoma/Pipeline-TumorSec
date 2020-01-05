#/usr/bin/python
import sys
import os
import re

### ejecutar como :
##python pipeline_report.py lista_muestras.txt 

##Funcion para crear archivo csv delimitado por ";" con las metricas del analisis realiazdo
def Create_csv(matriz_sample): 
	report = open("REPORT.csv","w")
	report.write("Sample;Number of reads in untrimmed fastq file;Average  Raw Read Length;Percentage of Duplicate raw reads;Number of reads trimmed;%;Avarage after filtering Read Length;Percentage of deduplicated reads;Number of reads in bam file;%;Number of reads in bam file passing mapping quality filters *;%;Number of genomic bases in analyzable target region;Number of reads in target regions;%;Average read depth in analyzable target regions;% target region with at least 1 reads;% target region with at least 10 reads;% target region with at least 20 reads;% target region with at least 50 reads;Total variants;SNP;INSERTION;DELETION;MISSENSE;NONSENSE;SILENT\n")
	report.write(";;;;;;;;;;;;;;;;;;;;;;;;;;\n")
	print "Sample;Number of reads in untrimmed fastq file;Average  Raw Read Length;Percentage of Duplicate raw reads;Number of reads trimmed;%;Avarage after filtering Read Length;Percentage of deduplicated reads;Number of reads in bam file;%;Number of reads in bam file passing mapping quality filters *;%;Number of genomic bases in analyzable target region;Number of reads in target regions;%;Average read depth in analyzable target regions;% target region with at least 1 reads;% target region with at least 10 reads;% target region with at least 20 reads;% target region with at least 50 reads;Total variants;SNP;INSERTION;DELETION;MISSENSE;NONSENSE;SILENT"
	print ";;;;;;;;;;;;;;;;;;;;;;;;;;"
	for array_sample in matriz_sample:
		line = ""
		for data in array_sample:
			line = line+str(data)+";"
		line = line[:-1]	
		print line
		report.write(line+"\n")
	report.close()

##Funcion que obtiene las metricas del archivo sample.csv de snpEff y las almacena de forma ordenada en matriz_sample para cada muestra
def snpEff(matriz_sample):
	list_sample = open(sys.argv[1],"r")
	for line in list_sample:
		line = line.rstrip("\n")
		#list = line.split("\t")
		#path = "./"+list[0]
		sample = line		
		snpEff = open(sample+"/"+sample+".csv","r")
		DEL = ""
		INS = ""
		SNP = ""
		MISSENSE = "" 
		NONSENSE = "" 
		SILENT = "" 
		TOTAL_VARIANTS = 0
		for line_snpEff in snpEff:
			line_snpEff = line_snpEff.rstrip("\n")
			if line_snpEff.startswith("DEL ,") == True:
				m1 = re.search(" , (.+?) , ",line_snpEff)
				if m1:
					DEL = m1.group(0)
					DEL = DEL.replace(" , ","")
					DEL = int(DEL)
			if line_snpEff.startswith("INS ,") == True:  #
				m2 = re.search(" , (.+?) , ",line_snpEff)
				if m2:
					INS = m2.group(0)
					INS = INS.replace(" , ","")
					INS = int(INS)
			if line_snpEff.startswith("SNP ,") == True: #
				m3 = re.search(" , (.+?) , ",line_snpEff)
				if m3:
					SNP = m3.group(0)
					SNP = SNP.replace(" , ","")
					SNP = int(SNP)
			if line_snpEff.startswith("MISSENSE ,") == True:  #
				m4 = re.search(" , (.+?) , ",line_snpEff)
				if m4:
					MISSENSE = m4.group(0)
					MISSENSE = MISSENSE.replace(" , ","")
					MISSENSE = int(MISSENSE)
			if line_snpEff.startswith("NONSENSE ,") == True:  #
				m5 = re.search(" , (.+?) , ",line_snpEff)
				if m5:
					NONSENSE = m5.group(0)
					NONSENSE = NONSENSE.replace(" , ","")
					NONSENSE = int(NONSENSE)
			if line_snpEff.startswith("SILENT ,") == True: #
				m6 = re.search(" , (.+?) , ",line_snpEff)
				if m6:
					SILENT = m6.group(0)
					SILENT = SILENT.replace(" , ","")
					SILENT = int(SILENT)
		if INS == "":
			INS = 0
		if DEL == "":
			DEL = 0
		if SNP == "":
			SNP = 0	
		if MISSENSE == "":
			MISSENSE = 0	
		if NONSENSE == "":
			NONSENSE = 0	
		if SILENT == "":
			SILENT = 0	
		TOTAL_VARIANTS = DEL+INS+SNP	
		snpEff.close()
		cont = 0
		for array_sample in matriz_sample:
			if array_sample[0].find(sample) != -1:
				matriz_sample[cont][20] = TOTAL_VARIANTS
				matriz_sample[cont][21] = SNP
				matriz_sample[cont][22] = INS
				matriz_sample[cont][23] = DEL
				matriz_sample[cont][24] = MISSENSE
				matriz_sample[cont][25] = NONSENSE
				matriz_sample[cont][26] = SILENT
			cont = cont +1	
	list_sample.close()
	return matriz_sample

##Funcion que obtiene las metricas del archivo genome_fraction_coverage.txt y las almacena de forma ordenada en matriz_sample para cada muestra
def qualimap_coverage(matriz_sample):
	list_sample = open(sys.argv[1],"r")
	for line in list_sample:
		line = line.rstrip("\n")
#		list = line.split("\t")
#		path = "./"+list[0]
		sample = line			
		genome_fraction_coverage = open(sample+"/"+sample+"/raw_data_qualimapReport/genome_fraction_coverage.txt","r")
		x1 = ""
		x10 = ""
		x20 = ""
		x50 = ""
		for line_fraction in genome_fraction_coverage:
			line_fraction = line_fraction.rstrip("\n")
			if line_fraction.startswith("#") == False:
				if line_fraction.startswith("1.0") == True:
					x1 = line_fraction.split("\t")[1]
				if line_fraction.startswith("10.0") == True:
					x10 = line_fraction.split("\t")[1]
				if line_fraction.startswith("20.0") == True:
					x20 = line_fraction.split("\t")[1]
				if line_fraction.startswith("50.0") == True:
					x50 = line_fraction.split("\t")[1]
		genome_fraction_coverage.close()
		cont = 0
		for array_sample in matriz_sample:
			if array_sample[0].find(sample) != -1:
				matriz_sample[cont][16] = x1	##agregamos porcent lecturas a x10
				matriz_sample[cont][17] = x10	##agregamos porcent lecturas a x10
				matriz_sample[cont][18] = x20	##agregamos porcent lecturas a x20
				matriz_sample[cont][19] = x50	##agregamos porcent lecturas a x50
			cont = cont +1			
	list_sample.close()
	return matriz_sample

##Funcion que obtiene las metricas del archivo qualimapReport.html y las almacena de forma ordenada en matriz_sample para cada muestra
def qualimap_html(matriz_sample):
	list_sample = open(sys.argv[1],"r")
	for line in list_sample:
		line = line.rstrip("\n")
#		list = line.split("\t")
#		path = "./"+list[0]
		sample = line	
		qualimapHtml = open(sample+"/"+sample+"/qualimapReport.html","r")
		flag_target = False
		flag_coverage = False
		cont_colum2 = 0
		for line_qual in qualimapHtml:
			line_qual = line_qual.rstrip("\n")
			if line_qual.find("Globals (inside of regions)") != -1:
				flag_target = True
			if (flag_target == True) and (line_qual.find("=column2>") != -1):
				cont_colum2 = cont_colum2 +1
				if cont_colum2 == 1:  ###tamanio region target
					m = re.search("=column2>(.+?)/",line_qual)
					if m:
						length_target = m.group(0)
						length_target = length_target.replace("=column2>","")
						length_target = length_target.replace(" /","")
				if cont_colum2 == 2: ## cantidad de lecturas mapeadas en region target
					ma = re.search("=column2>(.+?)/",line_qual)
					if ma:
						reads_mapped_target = ma.group(0)
						reads_mapped_target = reads_mapped_target.replace("=column2>","")
						reads_mapped_target = reads_mapped_target.replace("  /","")
						flag_target = False 
					mc = re.search("/  (.+?)%</td>",line_qual)
					if mc:
						porcent_reads_mappeds_target = mc.group(0)
						porcent_reads_mappeds_target = porcent_reads_mappeds_target.replace("/  ","")
						porcent_reads_mappeds_target = porcent_reads_mappeds_target.replace("%</td>","")
						porcent_reads_mappeds_target = porcent_reads_mappeds_target.replace(",",".")
			if line_qual.find("Coverage (inside of regions)") != -1:
				flag_coverage = True
				cont_colum2 = 0
			if (flag_coverage == True) and (line_qual.find("=column2>") != -1):
				cont_colum2 = cont_colum2 +1
				if cont_colum2 == 1:  ### mean coverage
					mb = re.search("=column2>(.+?)</",line_qual)
					if mb:
						mean_coverage = mb.group(0)
						mean_coverage = mean_coverage.replace("=column2>","")
						mean_coverage = mean_coverage.replace("</","")
						mean_coverage = float(mean_coverage.replace(",","."))			
		cont = 0
		for array_sample in matriz_sample:
			if array_sample[0].find(sample) != -1:
				matriz_sample[cont][12] = length_target			##agregamos largo region target en pb
				matriz_sample[cont][13] = reads_mapped_target	##agregamos num de lecturas mapeadas en region target
				matriz_sample[cont][14] = porcent_reads_mappeds_target	## agregamos porcentaje de lecturas mapeadas en region target
				matriz_sample[cont][15] = mean_coverage			##agregamos ccobetura media region target
			cont = cont +1						
		qualimapHtml.close()
	list_sample.close()
	return matriz_sample

##Funcion que obtiene las metricas del archivo multiqc_general_stats.txt y las almacena de forma ordenada en matriz_sample para cada muestra
def multiqc_general(matriz_sample):
	multiqc_general_stats = open("multiqc_data/multiqc_general_stats.txt","r")
	for line in multiqc_general_stats:
		line = line.rstrip("\n")
		if (line.find("_R") == -1) and (line.startswith("Sample") == False) and (line.find("sorted") == -1):
			list_aux1 = line.split("\t")
			sample_general = list_aux1[0]
			total_reads_bam =  int(list_aux1[7][:-2])
			read_mapped = int(list_aux1[3][:-2])
			median_coverage = int(list_aux1[11])
			cont = 0
			for sample in matriz_sample:
				if sample[0].find(sample_general) != -1: 
					total_reads = matriz_sample[cont][1]
					reads_trimmed = total_reads-total_reads_bam
					porcent_reads_trimmed = (float(reads_trimmed)*100)/total_reads
					percent_total_reads_bam = (float(total_reads_bam)*100)/total_reads
					percent_read_mapped = (float(read_mapped)*100)/total_reads_bam
					matriz_sample[cont][4] = reads_trimmed  	##agregamos cant de reads eliminados en trimming
					matriz_sample[cont][5] = porcent_reads_trimmed  	##agregamos porcentaje de reads eliminados en trimming
					matriz_sample[cont][8] = total_reads_bam  	##agregamos reads totales en el bam
					matriz_sample[cont][9] = percent_total_reads_bam  	##agregamos porcentaje de reads totales en el bam
					matriz_sample[cont][10] = read_mapped		##agregamos reads mapeados en el bam
					matriz_sample[cont][11] = percent_read_mapped		##agregamos porcentaje de reads mapeados en el bam
					#matriz_sample[cont][15] = median_coverage		##agregamos la cobertura media en region target
				cont = cont +1	
	multiqc_general_stats.close()
	return matriz_sample

##Funcion que obtiene las metricas del archivo multiqc_fastqc.txt y las almacena de forma ordenada en matriz_sample para cada muestra
def multiqc_fastq(matriz_sample):
	multiqc_fasqc = open("multiqc_data/multiqc_fastqc.txt","r")
	sample_actual = ""
	sample_past = ""
	dup_actual = 0
	dup_past = 0
	length_actual = 0
	length_past = 0

	sample_actual_filter = ""
	sample_past_filter = ""
	dup_actual_filter = 0
	dup_past_filter = 0
	length_actual_filter = 0
	length_past_filter = 0
	for line in multiqc_fasqc:
		if (line.startswith("Sample") == False) and (line.find(".qc") == -1):			
			if (line.find("filter3") == -1):  ##analizamos datos de lecturas crudas
				line = line.rstrip("\n")
				list_aux1 = line.split("\t")
				reads = int(list_aux1[13][:-2])
				sample_actual = list_aux1[0][:-3] ## modificar acorde al nombre de la muestra ye extencion del fastq
				dup_actual = float(list_aux1[18])
				dup_actual = 100 - dup_actual
				length_actual = float(list_aux1[4])
				if sample_actual == sample_past:
					#print "son iguales"
					list_aux2 = []
					list_aux2.append(sample_past)  ##agregamos id muestra
					list_aux2.append(reads*2) ##agregamos cant total de lecturas
					list_aux2.append((length_actual+length_past)/2) ##agregamos promedio largo lecturas
					list_aux2.append((dup_actual+dup_past)/2) ##agregamos promedio de duplicados
					cont = 0
					for sample in matriz_sample:
						if sample[0].find(sample_past) != -1:
							matriz_sample[cont][1] = list_aux2[1] ##agregamos total lecturas a matriz final
							matriz_sample[cont][2] = list_aux2[2] ##agregamos promedio largo lecturas a matriz final
							matriz_sample[cont][3] = list_aux2[3] ## agregamos porcentaje dup a matriz final
						cont = cont+1	
				sample_past = list_aux1[0][:-3]
				dup_past = float(list_aux1[18])
				dup_past = 100 - dup_past
				length_past = float(list_aux1[4])
			else:							##analizamos datos de lecturas filtradas
				line = line.rstrip("\n")
				list_aux1 = line.split("\t")
				#reads = int(list_aux1[13][:-2])
				sample_actual_filter = list_aux1[0][:-11] ## modificar acorde al nombre de la muestra y extencion del fastq
				dup_actual_filter = float(list_aux1[18])
				dup_actual_filter = 100 - dup_actual_filter
				length_actual_filter = float(list_aux1[4])
				if sample_actual_filter == sample_past_filter:
					#print "son iguales"
					list_aux2 = []
					list_aux2.append(sample_past_filter)  ##agregamos id muestra
					#list_aux2.append(reads*2) ##agregamos cant total de lecturas
					list_aux2.append((length_actual_filter+length_past_filter)/2) ##agregamos promedio largo lecturas
					list_aux2.append((dup_actual_filter+dup_past_filter)/2) ##agregamos promedio de duplicados
					cont = 0
					for sample in matriz_sample:
						if sample[0].find(sample_past_filter) != -1:
							#matriz_sample[cont][1] = list_aux2[1] ##agregamos total lecturas a matriz final
							matriz_sample[cont][6] = list_aux2[1] ##agregamos promedio largo lecturas a matriz final
							matriz_sample[cont][7] = list_aux2[2] ## agregamos porcentaje dup a matriz final
						cont = cont+1	
				sample_past_filter = list_aux1[0][:-11]
				dup_past_filter = float(list_aux1[18])
				dup_past_filter = 100 - dup_past_filter
				length_past_filter = float(list_aux1[4])			
	multiqc_fasqc.close()
	return matriz_sample

##########MAIN########

list_sample = open(sys.argv[1],"r")
matriz_sample = []
for line in list_sample:
	line = line.rstrip("\n")
	#list = line.split("\t")
	#path = "./"+list[0]
	sample = line
	list_id = range(27)
	list_id[0] = sample
	#list_id[9] = 
	matriz_sample.append(list_id)
list_sample.close()

matriz_sample = multiqc_fastq(matriz_sample)
matriz_sample = multiqc_general(matriz_sample)
matriz_sample = qualimap_html(matriz_sample)
matriz_sample = qualimap_coverage(matriz_sample)
matriz_sample = snpEff(matriz_sample)
Create_csv(matriz_sample)

"""
for muestra in matriz_sample:
	print muestra
"""



