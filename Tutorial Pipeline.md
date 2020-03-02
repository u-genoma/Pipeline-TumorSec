## Tutorial para la ejecución del Pipeline TumorSec

A continuación se describe de manera detallada los pasos necesarios para ejecutar el pipeline de TumorSec utilizando la imagen de docker ```labgenomicatumorsec/tumorsec:0.1```, la cual, se encuentra como un repositorio privado en el servidor Docker Hub (https://hub.docker.com/).  Para la descarga, es necesario tener información de la cuenta de Docker Hub del proyecto. (paso 1)

Ademas, se deben descargar las bases de datos de entrada necesarias para ejecutar el software ANNOVAR, el cual, las utiliza para la anotación funcional de las variantes. Ademas, las bases de datos hg19 y dbsnp_138 necesarias en el pre-procesamiento de datos. La ruta local de descarga de las bases de dato se debe agregar al archivo de configuración de TumorSec (paso 2 y 4)

Una vez descargadas las bases de datos y la imagen docker, se debe ejecutar la imagen de docker de manera interactiva (parámetro -ti en docker run) y montar la cuenta de TumorSec dentro de del contenedor creado, de esta manera podemos acceder a los datos de BaseSpace, necesarios para el demultiplezado de datos y la generación de reportes (paso 3). Luego de estas configuraciones, podemos ejecutar el pipeline de Tumorsec. (paso 5)

Para ejecutar este pipeline se asume instalado el programa docker de manera local en el servidor. Si no se encuentra instalado, ejecutar:```sudo yum -y install docker```. En el servidor Genoma3 de Genomedlab el programa docker con la cual fue testeado este tutorial es la version 18.06.0-ce.

### 1. Descargar imagen docker Tumorsec

El archivo ```Dockerfile``` contiene los comandos necesarios para instalar todos los pre-requisitos del pipeline TumorSec, ademas de integrar las bases de datos y archivos específicos del pipeline. Utilizando la configuración del ```Dockerfile```que se encuentra en el directorio ```/home/egonzalez/workSpace/docker_PipelineTumorsec```, se construyó la imagen docker la cual fue almacenada en un repositorio privado en DockerHub.

Cuenta: tumorsec@gmail.com
Contraseña:UDT-seq#19

El contexto para construir la imagen de docker para el pipeline TumorSec, se encuentra en la siguiente ruta
```/home/egonzalez/workSpace/docker_PipelineTumorsec``` 

En caso de querer realizar algún cambio al pipeline es necesario volver a crear la imagen docker, para esto ejecutar ```docker build``` dentro de la carpea del contexto, donde ademas se realizaron los cambios. Docker cargará los nuevos cambios a la nueva imagen. Para esto, ejecutar:

```
cd /home/egonzalez/workSpace/docker_PipelineTumorsec
docker build -t labgenomicatumorsec/tumorsec:0.1 .
```
Para verificar que se creó la nueva imagen:

```
docker images

REPOSITORY                     TAG                 IMAGE ID            CREATED             SIZE
labgenomicatumorsec/tumorsec   0.1                 5ea88887915c        27 hours ago        8.05GB

```
Una vez terminados los cambios de la imagen, se debe actualizar la imagen del repositorio en DockerHub. Se debe ingrear la informacion de usuario y hacer un push al repositorio:

```
docker login docker.io
Username: tumorsec@gmail.com
Password: UDT-seq#19

docker push labgenomicatumorsec/tumorsec:0.1

```

Para un segundo cambio, no es necesario ingresar nuevamente el usuario y contraseña.
En caso de no querer realizar cambios en la imagen se puede utilizar directamente la imagen del repositorio, utlizando ```docker pull``` y la información de la imagen.

Para descargar la imagen de docker desde dockerHub, ejecutar: 
```
docker pull labgenomicatumorsec/tumorsec:0.1
```
Para verificar que se descargó la imagen:
```
docker images

REPOSITORY                     TAG                 IMAGE ID            CREATED             SIZE
labgenomicatumorsec/tumorsec   0.1                 5ea88887915c        27 hours ago        8.05GB

```
Una vez descargada, podemos comenzar a descargar las bases de datos necesarioas para TumorSec.

### 2. Descargar bases de datos de ANNOVAR y hg19

Como parte de la imagen de docker ```labgenomicatumorsec/tumorsec:0.1``` se agregó un script en bash ```DB_download.sh``` que se encuentra dentro del directorio ```/Docker/TumorSec ``` de la imagen de docker. Este script permite descargar las bases de datos que no fueron intregadas en la imagen (por el tamaño) y que son necesarias para ejecutar el pipeline de TumorSec. 

Para ejecutar este script, se debe correr la imagen docker ```labgenomicatumorsec/tumorsec:0.1``` de manera interactiva (parámetro -ti en docker run). Para esto, ejecutar el siguiente comando:

```
docker run --privileged -ti --rm --name tumorsecRUN  -v /var/run/docker.sock:/var/run/docker.sock -v /usr/bin/docker:/usr/bin/docker --mount type=bind,source=/,target=/mnt,bind-propagation=rslave labgenomicatumorsec/tumorsec:0.1 /bin/bash
```
Al ingresar podemos observar con ```ls``` que se encuentran los scripts necesarios para correr TurmorSec. Ejecutar el script ``` DB_download.sh``` e ingresar la ruta donde serán almacenadas de manera local las bases de datos, antecedido de ```/mnt/```. A contiuación se observa un ejemplo:

```
sh DB_download.sh
Enter the output directory:
/mnt/home/egonzalez/DB_TumorSec
```
Bases de datos descargadas para ANNOVAR
- refGene
- AFR.sites.2015_08
- AMR.sites.2015_08
- EAS.sites.2015_0
- EUR.sites.2015_08
- SAS.sites.2015_08
- exac03
- dbnsfp35c
- cadd13
- avsnp150
- cosmic70
- clinvar_20180603

Bases de datos descargadas para el pipeline (GATK, SomaticSeq entre otros)
- Hg19
- dbsnp_138

### 3 . Crear volumen para los datos dentro de la imagen ```labgenomicatumorsec/tumorsec:0.1```

Existen archivos dentro de la imagen de docker ```labgenomicatumorsec/tumorsec:0.1``` que son propios del pipeline, por ejemplo el archivo .bed que contiene las regiones blanco del panel de genes, la base de datos cosmic, logo del laboratorio ademas los script que conforman el pipeline TumorSec. Para que estos datos sea vizualizados por otros container de docker, es necesario crear un volumen que será utilizado para montar los datos que se encuentran en la image, de esta manera otros docker 'container', podran vizualizarlos. El en llamado de variantes Somaticseq ejecuta los containers de Vardict, Mutect1, Varscan y Lofreq dentro de ```labgenomicatumorsec/tumorsec:0.1```. Para que estos container vizualicen los datos de la imagen, se deden seguir las siguientes instrucciones. 

Crear un volumen con el nombre datatumorsec
```
docker volume create datatumorsec
```

Para verificar que fue creado:
```
docker volume ls

DRIVER              VOLUME NAME
local               datatumorsec
```

Una vez creado el volumen, este será utilizado para montar el directorio ```/docker``` que se encuentra en la imagen. Esto se debe realizar a momento de ejecutar el docker ```docker run```

Ejecutar el docker.

```
docker run --privileged -ti --rm -v datatumorsec:/docker -v /var/run/docker.sock:/var/run/docker.sock -v /usr/bin/docker:/usr/bin/docker --mount type=bind,source=/,target=/mnt,bind-propagation=rslave labgenomicatumorsec/tumorsec:0.1 /bin/bash
```

```
[root@9aa37fe30960 /]# tree -L 2 docker/
docker/
|-- BaseSpace
|-- Inputs_TumorSec
|   |-- MiSeq_ReagentKitV2.csv
|   |-- genome
|   |-- logo_lab.png
|   `-- targets
|-- programas
|   |-- GenomeAnalysisTK.jar
|   |-- annovar
|   |-- fastp
|   |-- picard.jar
|   `-- somaticseq
`-- tumorSec
    |-- 00.conf_docker.ini
    |-- 00.inputs_TumorSec.ini
    |-- 01.Run_TumorSec.sh
    |-- 02.QC_Reports.sh
    |-- 03.Variants_reports.sh
    |-- 04.QC_dendogram.sh
    |-- DB_download.sh
    |-- complement
    `-- scripts
    
 ```
 


### 4. Montar datos de BaseSpace en Docker

Para ejecutar el pipeline de TumorSec, es necesario montar los datos de BaseSpace en la imagen docker. Para montar los datos, se debe seguir las siguientes instrucciones. El programa basemount se encuentra instalado en la imagen. 

Se debe estar dentro de un contenedor creado a partir de la imagen, si no es así, ejecutar el siguiente comando:
```
docker run --privileged -ti --rm --name tumorsecRUN  -v /var/run/docker.sock:/var/run/docker.sock -v /usr/bin/docker:/usr/bin/docker --mount type=bind,source=/,target=/mnt,bind-propagation=rslave labgenomicatumorsec/tumorsec:0.1 /bin/bash
```
Luego se debe crear una carpeta BaseSpace y montar los datos:

```
cd /Docker/
mkdir BaseSpace
basemount BaseSpace/

,-----.                        ,--.   ,--.                         ,--.
|  |) /_  ,--,--. ,---.  ,---. |   `.'   | ,---. ,--.,--.,--,--, ,-'  '-.
|  .-.  \' ,-.  |(  .-' | .-. :|  |'.'|  || .-. ||  ||  ||      \'-.  .-'
|  '--' /\ '-'  |.-'  `)\   --.|  |   |  |' '-' ''  ''  '|  ||  |  |  |
`------'  `--`--'`----'  `----'`--'   `--' `---'  `----' `--''--'  `--'
Illumina BaseMount v0.15.103.3011 public develop 2019-05-08 08:56

Command called:
    basemount BaseSpace/
From:
    /Docker

Starting authentication.

You need to authenticate by opening this URL in a browser:
  https://basespace.illumina.com/oauth/device?code=p1k65
  
```
Copiar el URL que saldrá en la pantalla, en el navegador e ingresar los datos de la cuenta TumorSec. 
usuario:tumorsec@gmail.com
contraseña: UDT-seq#19

Ahora podemos observar las corridas de TumorSec que fueron compartidas a la cuenta tumorsec@gmail.com

```
[root@2efef00d36c2 Docker]# cd BaseSpace/
[root@2efef00d36c2 BaseSpace]# ls
Projects  README  Runs
[root@2efef00d36c2 BaseSpace]# cd Runs/
[root@2efef00d36c2 Runs]# ls
20190219 LIB ROCHE V1.1  P-DGT-R02         Tumorsec20200124  Tumorsec20200128
Lib ROCHE v.1            Tumorsec20200122  Tumorsec20200127  Tumorsec20200130
[root@2efef00d36c2 Runs]# cd Tumorsec20200122/
[root@2efef00d36c2 Tumorsec20200122]# pwd
/Docker/BaseSpace/Runs/Tumorsec20200122
[root@2efef00d36c2 Tumorsec20200122]#

```

Con la ruta de BaseSapce de la corrida, podemos correr el pipeline de tumorSec. Ojo: Hasta el momento cada vez que se corre ```docker run```, se debe montar la carpeta de baseSpace (ejecutar paso 2). Existe una manera de realizar cambios al ejecutar la imagen docker (crear un contenedor) y guardar este contenedor con docker push en DockerHub, sin embargo, todavia no se encuentra implementado.  



### 5. Configurar archivo con parametros de entrada

Una vez montado el directorio de BaseSpace, es necesario proceder a configurar los parámetros de entrada para la ejecucion del pipeline. Para esto, se creó en la imagen TumorSec un archivo ```00.conf_docker.ini ``` en la carpeta ```/Docker/TumorSec ``` el cual será cargado al inicio de la ejecución del pipeline. Este archivo contiene los parámetros que se pueden modificar. Aquellos que no son modificables se encuentran en el archivo ```00.inputs_TumorSec.ini```, el cual no debe ser alterado.

archivo: ```00.conf_docker.ini```

EXT_DBS -> variable con la ruta absoluta de las bases de datos descargadas hg19 y dbsnp (paso2)
ANNOVAR_HDB -> variable con la ruta absoluta de las bases de datos descargadas de annovar (paso2)

Para modificar el archivo de cofiguracion:

```
nano 00.conf_docker.ini
```

```
#########
# Pipeline TumorSec V2.0 
# Parámetros para TumorSec.
# Archivo de configuración de parámetros para correr en modo docker. A partir del archivo 00.inputs_TumorSec.ini 
# se creo este archivo, que solo tiene los parámetros modificables en el pipeline. 
########

## Ingresar la ruta donde se descargaron las bases de datos. (paso 2)
EXT_DBS="/mnt/home/egonzalez/Inputs_TumorSec/genome"    ## hg19 y dbsnp_138
ANNOVAR_HDB="/mnt/datos/reference/annot/annovar/humandb"  ## bases de datos de annovar

## PARAMETERS OF TRIMMING (FASTP)
qual="20"
large="50"
window="10"

## VARIANT FILTERS
AF="0.02"
ExAC="0.01"
DP_ALT="12"

## DEFAULTS PARAMETERS DENDOGRAM
PCT_GT_SNV="0.9" ### porcentaje de genotipado del 90% por SNV (RSID).
PCT_GT_SAMPLES="0.5" ### porcentaje de genotipado por 50% por muestra. 
MAF="0.05" ## Mínimo de frecuencia alélica del 5% para cada RSID.
DP="250" ## profundidad por SNV identificada.
```
Una vez configurado los parámetros de entrada necesarios. Se puede ejecutar el pipeline de TumorSec.(paso 5)

### 6. Ejecución del Pipeline

Para la ejecución del pipeline, una vez terminados los pasos anteriores, podemos correr el pipeline dentro del contenedor que configuramos, solo debemos ejecutar el programa ```01.Run_TumorSec.sh```

Ejemplo de ejecución de TumorSec, dentro del contenedor que fue previamente configurado.
```
[root@201792d839be /]# cd Docker/
[root@201792d839be Docker]# ls
BaseSpace  Inputs_TumorSec  Programas  TumorSec
[root@201792d839be Docker]# cd TumorSec/
[root@201792d839be TumorSec]# ls
00.conf_docker.ini      01.Run_TumorSec.sh  03.Variants_reports.sh  complement
00.inputs_TumorSec.ini  02.QC_Reports.sh    04.QC_dendogram.sh      scripts
[root@201792d839be TumorSec]# sh 01.Run_TumorSec.sh

Enter the output directory:
/mnt/home/egonzalez/workSpace/runs_TumorSec/Docker_subset_200122

Enter the BaseSpace directory:
/Docker/BaseSpace/Runs/Tumorsec20200122

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
0-8

Build sample dendogram (y / n)
n

Threads:
10

Enter input parameters (path) or by default (0):
0

############################################
     Welcome to the TumorSec pipeline
############################################

== Search for somatic variants of oncological importance ==
Developed by the Laboratory of Genomics of Cancer and GENOMELAB, School of Medicine. University of Chile

Comando: sh /Docker/TumorSec/01.Run_TumorSec.sh --input--dir /mnt/home/egonzalez/workSpace/runs_TumorSec/Docker_subset_200122 --threads 10 --baseSpace /Docker/BaseSpace/Runs/Tumorsec20200122 --dendogram n --step 0-8 --input--data /Docker/TumorSec/00.inputs_TumorSec.ini

Mon Feb 17 15:43:17 UTC 2020 : step 0 - start - demultiplexing
Mon Feb 17 15:43:17 UTC 2020 : step 0 - logfile - /mnt/home/egonzalez/workSpace/runs_TumorSec/Docker_subset_200122/0_logs/0_log_demultiplexing.out
```
Actualmente existen problemas para ejecutar el llamado de variantes, este proceso, debe ejecutar 5 imagenes de docker dentro del docker. Se logró ejecutar el docker-in-docker estableciendo un link del programa docker de manera local a la imagen y montando el binario en ```docker run```con los parámetros: ```-v /var/run/docker.sock:/var/run/docker.sock -v /usr/bin/docker:/usr/bin/docker```. Para montar los datos de manera recursiva, es decir, para que el docker dentro del docker acceda a los archivos del host, se de debe montar el directorio raíz de manera recursiva con el parámetro ```-mount type=bind,source=/,target=/mnt,bind-propagation=rslave``` en ```docker run ```.

El problema actual, es que el docker-in-docker no esta montando los datos que se encuentran dentro de la imagen de TumorSec ```labgenomicatumorsec/tumorsec:0.1```. Por ejemplo, la base de datos COSMIC que no se descarga en el paso 2, si no, que se encuentra integrada en al imagen no puede ser leída al correr MuTect2 (que es un docker que se ejecuta dentro del docker TumorSec). 

### 7. Archivos de salida e interpretación de resultados. 

