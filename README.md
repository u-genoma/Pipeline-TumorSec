# TumorSec

**Validation of a NGS panel, with automated analysis, designed for detection of medically actionable tumor biomarkers for Latin America**

https://www.medrxiv.org/content/10.1101/2021.03.19.21253988v1


## Manual de Procedimientos: Paquete Bioinformático TumorSec.

A continuación se presenta el manual de usuario de pipeline bioinformático TumorSec. Desarrollado por el laboratorio de Genómica del Cáncer en colaboración con GENOMED, ambos de la facultad de medicina, Universidad de Chile.

## 1. Descripción de TumorSec

TumorSec incluye un paquete de programas de código libre que se ejecutan de manera secuencial y automática, para la obtención  de variantes somáticas de tipo SNVs en InDels a partir de una muestra de tejido tumoral (FFPE o Tumor fresco), sin la necesidad de integrar una muestra de sangre para el descarte de variantes germinales.  El flujo de trabajo bioinformático está coordinado mediante un script en bash que llama los programas, guarda los resultados de forma secuencial, permitiendo una interacción con el usuario para realizar controles de calidad y genera un informe automático con los resultado en formato PDF.


## 2. Infraestructura computacional

TumorSec produce grandes volúmenes de datos y utiliza más de 10 programas que realizar cómputos en paralelo según la disponibilidad del hardware. Por tanto, para ejecutar su flujo de trabajo, es necesario una infraestructura computacional que permita optimizar los tiempos de cómputos y almacenar grandes volúmenes de datos de manera periódica.
Se describirán a continuación tres aspectos importantes a considerar en infraestructura: 
> * La transferencia de datos
> * El almacenamiento de datos
> * El sistema de respaldo

Este último, permite realizar copias de seguridad ante posibles fallas del hardware.

### 2.1 Transferencia de datos

Una vez terminado el proceso de secuenciación del MiSeq M03158, es necesaria una transferencia de los datos generados a un servidor o entorno para ejecutar el pipeline bioinformático de TumorSec.  La transferencia de datos se realiza montando de manera remota los datos de secuenciación en el servidor denominado Genoma3, ubicado en el laboratorio de Bioinformática GenoMed de la Facultad de Medicina, Universidad de Chile. Para realizar este proceso, el software BaseMount v0.15.103.3011 fue previamente instalado siguiendo las recomendaciones de Illumina <sup>[1]</sup>.  El primer paso es importar los datos de secuenciación a la cuenta de BaseSpace del personal técnico a cargo de ejecutar el pipeline de TumorSec.
La primera vez que se monten datos se deberá ingresar la información de autentificación de la cuenta de BaseSapce<sup>[2]</sup> que se montará en el servidor, además de crear un directorio vacío donde se alojarán los datos.

```
$ mkdir BaseSpace
```
Para montar los datos se debe ejecutar el siguiente comando en la terminal Linux

```
$ basemount BaseSpace/
```
De esta manera se podrán acceder a todas las carpetas de secuenciación vinculadas a una cuenta BaseSpace, permitiendo copiar los archivos fastq.gz al directorio donde se ejecutará el pipeline.

```
$cp BaseSpace/Projects/TumorsecXX/Samples/*/Files/*fastq.gz	
${WORKSPACE}/1_fastq

```
Una vez terminada la transferencia de datos se procede a desmontar la carpeta.

````
$ basemount --unmount BaseSpace/
````
Luego de la transferencia de datos es necesario revisar que los archivos fastq.gz no se encuentren truncados, debido a una falla durante la transferencia de datos desde el disco montado al servidor Genoma3. Es recomendable realizar un checksum de los datos antes de ejecutar el pipeline TumorSec.

### 2.2 Almacenamiento de datos

La ejecución del pipeline bioinformático de TumorSec necesita una gran capacidad de almacenamiento debido a que utiliza bases de datos genómicas de gran tamaño que son necesarias para el llamado de variantes y la anotación funcional. Entre estas, se encuentran; Genoma humano hg19 (~3.0 GB), COSMIC (~1.0 GB), dbSNPv138 (~11 GB) y 1000 Genomas (~100 MB). Cada secuenciación produce un total ~ 5,0 Gb de datos según las indicaciones del Kit (MiSeq Reagent Kit V2), y como referencia, los archivos de salida del pipeline son entre ~ 40-60 GB. El laboratorio de bioinformática GenoMed de la Facultad de medicina, cuenta con un sistema NAS, el cual es un dispositivo de almacenamiento conectado por red que permite almacenar y recuperar datos para usuarios autorizados. El sistema NAS vinculado a los servidores posee las siguientes especificaciones: Servidor Supermicro SuperStorage Server 4U, procesador INTEL SKYLAKE-SP, 32 GB de RAM, disco SSD de 240GB y 204 TB de almacenamiento

### 2.3 Sistema de respaldo

El laboratorio de bioinformática GenoMed cuenta con una unidad de cinta HP LTO-4 Ultrium 1760 para el resguardo de los datos a largo plazo. Dispositivo que permite almacenar o restaurar datos en una unidad de cinta magnética con una capacidad máxima de 1.6 TB comprimidos. Para el resguardo de los datos de TumorSec se realizan copias de seguridad de manera mensual siguiendo el  procedimiento operativo estandarizado (POE-BIT-07), para respaldo de datos en cintas del laboratorio de bioinformática. Este posee un control de respaldo bajo registros que permite trazar la información de cada cinta magnética almacenada.

## 3. Descripción del pipeline TumorSec

De manera global el programa TumorSec corresponde a un pipeline escrito en bash optimizado para datos NGS de alto rendimiento para librerías paired-end, enfocado en la búsqueda de variantes somáticas con importancia clínica para tejidos tumorales sin la necesidad de una muestra de sangre para el descarte de variantes germinales. Debido a estos grandes desafíos, el flujo de trabajo de TumorSec se rige por protocolos establecidos para la búsquedas de variantes, replicando las mejores prácticas de GATK en el pre-procesamiento de datos. Consta con un riguroso informe de calidad automatizado, que permite obtener métricas de los puntos críticos del pipeline, para finalizar con la anotación funcional y posteriores filtros que permite tener variantes de calidad con diversa información funcional para la toma de decisiones. El resumen de los procesos del flujo de trabajo de TumorSec se pueden ver a continuación.

![Captura de pantalla 2020-01-20 a la(s) 14 02 56](https://user-images.githubusercontent.com/37847170/72745089-b0bfaa80-3b8d-11ea-9269-b9a223d66387.png)

**Figura 1: Diagrama del flujo de trabajo del pipeline bioinformático de TumorSec.**
Procesamiento de datos realizado en el flujo de trabajo bioinformático, desde los archivos BCL hasta generar el archivo VCF con la lista de variantes somáticas por muestra. El detalle de los procesos y subprocesos se describen a continuación.



```
Enter the BaseSpace directory:
/home/egonzalez/BaseSpace/Runs/Tumorsec20200109

What steps do you want to execute?
0. Demultiplexing
1. Trimming
2. Mapping
3. Remove duplicates - QC report
4. Realign of indels
5. Recalibration
6. Varcall - Variants report
7. Annotation
8. Filter vcf (RGO Input)
Example, all pipeline -> 0-8, only varcall -> 6, from trimming to realignment -> 1-4
2-7

Build sample dendogram (y / n)
n

Threads:
10

Enter input parameters (path) or by default (0):
0

############################################
     Welcome to the TumorSec pipeline
############################################

== Búsqueda de variantes somáticas de importancia oncológica ==
Developed by the Laboratory of Genomics of Cancer and GENOMELAB, School of Medicine. University of Chile

Command: sh /home/egonzalez/workSpace/PipelineTumorSec/01.Run_TumorSec.sh --input--dir /home/egonzalez/workSpace/runs_TumorSec/200109_TumorSec --threads 10 --baseSpace /home/egonzalez/BaseSpace/Runs/Tumorsec20200109 --dendogram y --step 2-7 --input--data /home/egonzalez/workSpace/PipelineTumorSec/00.inputs_TumorSec.ini

```


Por cada proceso relevante en la ejecución del  pipeline de TumorSec, se crea un directorio de salida dentro de la carpeta de trabajo con los archivos de salida de cada proceso, lo que permite verificar la calidad de los datos a medida que se va ejecutando el pipeline. Los directorios se enumeran de manera secuencial según el orden de cada procedimiento. Un ejemplo de los directorios generados por corrida de secuenciación se muestran a continuación.

```
├──DDMMAA_TumorSec
	├── 0_logs 
	├── 1_fastq
	├── 2_trim 
	├── TMP_bwa 
	├── TMP_dedup 
	├── 4_QC_reports
	├── TMP_realign
	├── 3_bqsr
	├── 5_varcall
	├── 6_annotate
	├── 7_variants_report
	├── 8_RGO
```

El detalle del contenido de cada directorio se describe en las secciones de pre-procesamiento de datos, llamado de variantes, anotación funcional,  control de calidad y reportes.

### 3.1. Pre-procesamiento de datos
El pre-procesamiento es la primera fase que debe preceder al descubrimiento de variantes. Implica preprocesar los datos de secuenciación sin procesar para producir archivos de alineamientos BAM listos para el análisis. A continuación se describe en detalle de pre-procesamiento de datos, donde se implementaron las mejores prácticas de GATK para el llamado de variantes, utilizando los parámetros por defecto de la versión v3.8-1-0.

#### 3.1.1 Demultiplexación de datos

MiSeq Reporter convierte automáticamente los archivos BCL en archivos FASTQ como primer paso después de terminar el proceso de secuenciación, por tanto se pueden extraer directamente los archivos FASTQ desde los datos montados en el servidor (ver sección 2.1). Ante un posible error en el proceso de demultiplexado generado por el secuenciador, el pipeline de TumorSec realiza de manera automática este proceso al ingresar como parámetro de entrada la ruta de la carpeta montada en el servidor de la corrida de secuenciación. Tumorsec de manera interna ejecuta el programa bcl2fastq v2.20.0.422 el cual demultiplexa la secuencia de datos y convierte la llamada base (BCL) en archivos FASTQ. La forma de ejecutar el  programa bcl2fastq se observa a continuación, siendo ``${WORSPACE}`` la carpeta física de trabajo donde se está ejecutando el pipeline.

```
$bcl2fastq -R BaseSpace/DDMMAA_TumorSec/ -o ${WORKSPACE}/1_fastq
```

#### 3.1.2 Poda o trimming de datos
El control de calidad y el preprocesamiento de los archivos FASTQ son esenciales para proporcionar datos limpios para el análisis posterior. Una herramienta que optimiza los tiempos de cálculos y además realiza controles de calidad, filtrado de lectura y correcciones de base para los datos FASTQ es fastp v0.19.11<sup>[1]</sup>. El programa fastp v0.19.11 utiliza el algoritmo de ventana deslizante para eliminar las bases de baja calidad en los extremos de cada lectura. Este programa es parte del pipeline de TumorSec y sus parámetros de ejecución son; un tamaño de ventana de 10 bases con una calidad mínima en escala phred de 20, en dirección 5’ 3’ con un largo de lectura mínimo de 50 nucleótidos. Finalmente, los archivos de salida de la poda de datos (FASTQ en R1 y R2) que pasaron los filtros de calidad mencionados se almacenan en la carpeta:

```
${WORKSPACE}/2_trim
```

#### 3.1.3 Alineamiento
El segundo paso del pre-procesamiento de datos consiste en mapear cada par de lectura (R1 y R2) al genoma de referencia (hg19) para proporcionar un marco de coordenadas para los posteriores análisis. Para este propósito se utiliza el programa  BWA (alignment via Burrows-Wheeler transformation)<sup>[2]</sup>, el cual, alinea secuencias de baja divergencia contra un genoma de referencia grande, como el genoma humano, generalmente se recomienda para consultas de alta calidad y está incluido en el protocolo de buenas prácticas de GATK en el pre-procesamientos de datos genómicos. Debido a que el algoritmo de mapeo procesa cada par de lectura de forma aislada, el cálculo se puede paralelizar masivamente para aumentar el rendimiento deseado.
Finalmente se genera un archivo BAM/SAM ordenado para cada muestra que es almacenado en al carpeta de salida: 

```
${WORKSPACE}/TMP_bwa
```
#### 3.1.4 Remover duplicados
El tercer paso del pre-procesamiento se realiza por muestra y consiste en identificar pares de lectura que probablemente se hayan originado a partir de un mismo fragmento de ADN, por tanto son lecturas duplicadas. Estas se consideran observaciones no independientes, por lo que el programa etiqueta a todas las lecturas, menos un par de lecturas dentro de cada conjunto de duplicados, lo que hace que los pares marcados se ignoren por defecto durante el proceso de descubrimiento de variantes. En el pipeline TumorSec se utiliza la herramienta MarkDuplicates de Picard v2.20.2-8 de para este propósito, generando un nuevo directorio de salida con un archivo BAM por muestra que contiene las lecturas duplicadas marcadas, además de las métricas que serán integradas en un posterior reporte de calidad.

```
${WORKSPACE}/TMP_dedup
```
#### 3.1.5 Realineamiento de InDels 
El cuarto paso del pre-procesamiento de datos genómicos es el realineamiento de InDels, en donde, se alinean las lecturas localmente de modo que el número de bases que no coinciden en el alineamiento se minimiza en todas las lecturas. En general, un gran porcentaje de las regiones que requieren realineamiento local se deben a la presencia de una inserción o deleción. La realineación local sirve para transformar regiones desalineadas por los InDels en lecturas limpias que contienen un InDel consenso adecuado para el descubrimiento de variantes. En el pipeline TumorSec se utiliza la herramienta GATK v3.8-1-0 para este propósito, utilizando los parámetros por defectos recomendados por los desarrolladores. Se genera un directorio de salida con un archivo BAM por muestra con el alineamiento corregido en las inserciones y deleciones.

```
${WORKSPACE}/TMP_realign
```
#### 3.1.6 Recalibración de calidad de base (BQSR) 

El último paso del pre-procesamiento de datos es la recalibracion del puntaje de calidad de base. Los puntajes de calidad de base, son las estimaciones de error emitidas por la máquina de secuenciación que expresa cuán segura estaba la máquina de identificar la base correcta. Debido a que los algoritmos de llamado de variante dependen del puntaje de calidad asignado a la base en cada posición de la lectura, es importante realizar una  recalibración de la calidad. Este procedimiento se realiza en el pipeline de TumorSec con programa GATK v3.8-1-0 utilizando los parámetros por defecto recomendados por los desarrolladores. GATK v3.8-1-0 detecta errores sistemáticos cometidos por la máquina de secuenciación cuando estima la calidad de cada base, y ajusta los puntajes de calidad en un proceso en el que aplica aprendizaje automático para modelar empíricamente estos errores. Finalmente el pipeline de TumorSec, genera un directorio de salida con los archivos BAM del alineamiento con la correccion del puntaje de base.

```
${WORKSPACE}/3_bqsr
```

## 4. Llamado de variantes
Posterior al preprocesamiento de datos, el programa en bash ejecuta de manera paralela y automática el llamado de variantes utilizando el programa SomaticSeq v.3.3.0<sup>[4]</sup>,el cual, maximiza su sensibilidad combinando el resultado de cinco llamadores de variantes de última generación para SNV; Mutect2, VarScan2, VarDict, LoFreq, Strelka y agregando Scalpel para InDels<sup>[4]</sup> . A continuación, se listan las características globales de cada llamador de variante utilizado por SomaticSeq en el pipeline de TumorSec: 

> * **MuTect2**, es un llamador somático de SNV que aplica un clasificador bayesiano para detectar mutaciones somáticas. 
> * **VarScan2**, utiliza un enfoque estadístico diferente, aplicando una prueba exacta de Fisher (FET) para detectar el cambio de genotipo.
> * **VarDict**, está específicamente diseñado para detectar variantes importantes pero desafiantes que otros llamadores no reportan. Aplica una serie de filtros para los falsos positivos que permiten aumentar la precisión.
> * **LoFreq**, modela la tasas de error específicas para llamar con precisión las variantes que ocurren en bajas frecuencias alélicas.
> * **Strelka2**, es un llamador de SNV, rápido y preciso, optimizado para el análisis de la variación de la línea germinal en cohortes pequeñas y variantes somática en pares de muestras tumorales/normales.

El programa en bash de Tumorsec ejecuta de manera paralela los seis llamadores de variantes por muestras, en modo single (solo con muestras tumorales) utilizando un mínimo de frecuencia alélica para la búsqueda de variantes de un 1%. El resto de los parámetros establecidos son aquellos integrados por defecto por SomaticSeq v.3.3.0<sup>[4]</sup>. Cada llamador de variantes genera un archivo VCF, los cuales SomaticSeq v.3.3.0[ utilizará como parámetros de entrada para el cálculo de las variantes consenso. Se seleccionan aquellas SNVs o InDels que son reportadas por al menos 3 de los software de los 5 para SNV y 6 para InDels. Finalmente, el pipeline de TumorSec crea un nuevo directorio en la carpeta de trabajo, donde almacena los archivos VCF de cada llamador de variantes y el VCF final con las variantes consenso reportadas por SomaticSeq v.3.3.0.

```
${WORKSPACE}/5_varcall
```

## 5. Anotación
Una vez obtenidas las variantes consenso por SomatiSeq[4], se realiza la anotación de variantes con importancia oncológica con CGI (Cancer Genome Interpreter)[10] , la cual, anota la relevancia biológica y clínica de las alteraciones tumorales.

```
${WORKSPACE}/6_annotate
```

## 6. Filtro de variantes
Finalmente el pipeline de Tumorsec realiza filtros que permiten eliminar los posibles artefactos y variantes germinales de la muestra. El primer filtro se realiza después del llamado de variantes con SomaticSeq[4], en la cual se seleccionan aquellas mutaciones identificadas por 3 o más llamadores de variantes (sección 4.0) con frecuencias alélicas superiores al 5% para cada muestra. El segundo filtro se realiza posterior a la anotación funcional con CGI (sección 5), donde se seleccionan aquellas variantes que no poseen frecuencia alélica reportadas en la base de datos ExAC o que son menores al 1%.

## 7. Control de calidad de los datos
Entre la ejecución del pre-procesamiento de datos en el pipeline de TumorSec, se ejecutan programas de control de calidad, de manera paralela para el posterior reporte de calidad de la corrida de secuenciación. Estos se listan a continuación: 

> * **FastQC**<sup>[5]</sup>, realiza un control de calidad en datos de secuencia sin procesar que proviene de flujos de trabajo  de secuenciación de alto rendimiento
Picard MarkDuplicate[6], calcula la tasa de lecturas duplicadas en el pre-procesamiento de datos.
> * **Qualimap**<sup>[7]</sup>, realiza un control de calidad de los datos de secuenciación que fueron alineados a una referencia.
> * **Mosdepth**<sup>[8]</sup> es una aplicación conveniente para el cálculo de la profundidad de todo el genoma que rastrea fragmentos de alineaciones de lectura.
> * **MultiQC**<sup>[9]</sup>, resume los resultados de análisis para múltiples herramientas y muestras en un solo informe

## 8. Reportes
Integrando programas desarrollados en el laboratorio de Genómica del Cáncer, escritos en python y en R al pipeline de TumorSec, se generan 2 reportes automáticos como resultados del pipeline que permiten observar la calidad de los datos, las variantes obtenidas 

> **Reporte de calidad de las muestras**: Consiste en un archivo en PDF generado por secuenciación que reportar las métricas de calidad por muestra, que se fueron generando en los con los programas mencionados anteriormente (sección 7)
> > * Número de lecturas antes y después de la poda o trimming de datos.
> > * Porcentaje de lecturas eliminadas por el trimming.
> > * Porcentaje de lecturas marcadas como duplicados.
> > * Número de lecturas que se encuentran en las regiones blanco del panel de genes.
> > * Profundidad promedio de lecturas en regiones blanco.
> > * Porcentaje de regiones blanco que se encuentran en uniformidad.
> > * Porcentaje de regiones blanco a diferentes niveles de coberturas mínimas (100X- 500X).

> **Anotación de variantes y cobertura de regiones blanco por muestra** : Se genera 1 archivo excel por muestra que contiene 4 pestaña:
> > * Variantes identificadas con la anotación de ANNOVAR
> > * Variantes identificadas con la anotación de CGI
> > * Prescripción a drogas de CGI de las variantes reportadas
> > * Cobertura de las regiones blanco.

Estos reportes son generados en nuevos directorios dentro de la carpeta de trabajo donde se está ejecutando el pipeline, las cuales corresponden a:

```
${WORKSPACE}/4_QC_reports
${WORKSPACE}/7_variants_report
```

## 9. Referencias. 
+ [1] Chen, S., Zhou, Y., Chen, Y., & Gu, J. (2018). Fastp: An ultra-fast all-in-one FASTQ preprocessor. Bioinformatics, 34(17), i884–i890. https://doi.org/10.1093/bioinformatics/bty560
[2] Li, H., & Durbin, R. (2009). Making the Leap: Maq to BWA. Mass Genomics, 25(14), 1754–1760. https://doi.org/10.1093/bioinformatics/btp324
+ [3] Van der Auwera, G. A., Carneiro, M. O., Hartl, C., Poplin, R., Del Angel, G., Levy-Moonshine, A., M. A. (2013). From FastQ data to high confidence variant calls: the Genome Analysis Toolkit best practices pipeline. Current protocols in bioinformatics, 43(1110), 11.10.1–11.10.33. doi:10.1002/0471250953.bi1110s43
+ [4] Fang, L. T., Afshar, P. T., Chhibber, A., Mohiyuddin, M., Fan, Y., Mu, J. C., … Lam, H. Y. K. (2015). An ensemble approach to accurately detect somatic mutations using SomaticSeq. Genome Biology, 16(1), 1–13. https://doi.org/10.1186/s13059-015-0758-2
+ [5] FastQC versión 0.11.8 (quality control for raw sequence data; GPL v3) https://www.bioinformatics.babraham.ac.uk/projects/fastqc
+ [6] Picard versión 2.20. http://broadinstitute.github.io/picard/
+ [7] García-Alcalde, F., Okonechnikov, K., Carbonell, J., Cruz, L. M., Götz, S., Tarazona, S., Conesa, A. (2012). Qualimap: Evaluating next-generation sequencing alignment data. Bioinformatics, 28(20), 2678–2679. https://doi.org/10.1093/bioinformatics/bts503
+ [8] Pedersen, B. S., & Quinlan, A. R. (2018). Mosdepth: Quick coverage calculation for genomes and exomes. Bioinformatics, 34(5), 867–868. https://doi.org/10.1093/bioinformatics/btx699
+ [9] Ewels, P., Magnusson, M., Lundin, S., & Käller, M. (2016). MultiQC: Summarize analysis results for multiple tools and samples in a single report. Bioinformatics, 32(19), 3047–3048. https://doi.org/10.1093/bioinformatics/btw354
+ [10] Tamborero, D., Rubio-Perez, C., Deu-Pons, J., Schroeder, M. P., Vivancos, A., Rovira, A., Lopez-Bigas, N. (2018). Cancer Genome Interpreter annotates the biological and clinical relevance of tumor alterations. Genome Medicine, 10(1), 1–8. https://doi.org/10.1186/s13073-018-0531-8



