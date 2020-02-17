## Tutorial para la ejecución del Pipeline TumorSec

A continuación se describe de manera detallada los pasos necesarios para ejecutar el pipeline de TumorSec utilizando la imagen de docker ```labgenomicatumorsec/tumorsec:0.1```, la cual, se encuentra como un repositorio privado en el servidor Docker Hub (https://hub.docker.com/).  Para la descarga, es necesario tener información de la cuenta de Docker Hub del proyecto. (paso 1)

Ademas, se deben descargar las bases de datos de entrada necesarias para ejecutar el software ANNOVAR, el cual, las utiliza para la anotación funcional de las variantes. La ruta local de descarga de las bases de dato se debe agregar al archivo de configuración de TumorSec (paso 2 y 4)

Una vez descargadas las bases de datos y la imagen docker, se debe ejecutar la imagen de docker de manera interactiva (parámetro -ti en docker run) y montar la cuenta de TumorSec dentro de del contenedor creado, de esta manera podemos acceder a los datos de BaseSpace, necesarios para el demultiplezado de datos y la generación de reportes (paso 3). Luego de estas configuraciones, podemos ejecutar el pipeline de Tumorsec. (paso 5)

Para ejecutar este pipeline se asume instalado el programa docker de manera local en el servidor. Si no se encuentra instalado ejecutar ```sudo yum -y install docker```. Este se encuentra instalado en el servidor Genoma3 de Genomedlab, y la version con la cual fue testeado este tutorial es la version 18.06.0-ce.

### 1. Descargar imagen docker Tumorsec

El archivo ```Dockerfile``` contiene los comandos necesarios para instalar todos los pre-requisitos del pipeline TumorSec, ademas de las bases de datos y archivos específicos del pipeline. Utilizando la configuración del ```Dockerfile```que se encuentra en el directorio ```/home/egonzalez/workSpace/docker_PipelineTumorsec```, se construyó la imagen docker la cual fue almacenada en un repositorio privado en Docker Hub.

El contexto para construir la imagen de docker para el pipeline TumorSec, se encuentra en la siguiente ruta
```/home/egonzalez/workSpace/docker_PipelineTumorsec``` 

En caso de querer realizar algún cambio al pipeline es necesario volver a crear la imagen docker, para esto ejecutar docker build con la informacion de la imagen que se creará, y docker cargará los nuevos cambios a esta.

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
Una vez terminados los cambios de la imagen, se deben actualizar la imagen del repositorio en DockerHub. Primero, se debe ingrear la informacion de usuario, y hacer un push al repositorio:
```
docker login docker.io
Username: Tumorsec@gmail.com
Password: UDT-seq#19

docker push labgenomicatumorsec/tumorsec:0.1

```
Para un segundo cambio, no es necesario ingresar nuevamente el usuario y contraseña.
En caso de no querer realizar cambios en la imagen se puede utilizar directamente la imagen del repositorio, utlizando docker pull y la información de la imagen.

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

Para ejecutar este script, se debe correr la imagen docker ```labgenomicatumorsec/tumorsec:0.1``` de manera interactiva (parámetro -ti en docker run). Se debe ejecutar el siguiente comando:

```
docker run --privileged -ti -d --name tumorsecRUN  -v /var/run/docker.sock:/var/run/docker.sock -v /usr/bin/docker:/usr/bin/docker --mount type=bind,source=/,target=/mnt,bind-propagation=rslave labgenomicatumorsec/tumorsec:0.1 /bin/bash
```
Al ingresar podemos observar con ```ls``` los scripts necesarios para correr TurmorSec. Ejecutar el script ``` DB_download.sh``` e ingresar la ruta donde serán almacenadas de manera local las bases de datos, antecedido de /mnt/. A contiuación se observa un ejemplo de ejecución.

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

### 3. Montar datos de BaseSpace en Docker

Para ejecutar el pipeline de TumorSec, es necesario montar los datos de baseSpace en la imagen docker. Para montar los datos, se debe seguir las siguientes instrucciones. El programa basemount se encuentra instalado en la imagen. 

Se debe estar dentro de un contenedor creado a partir de la imagen, si no es así, ejecutar el siguiente comando:
```
docker run --privileged -ti -d --name tumorsecRUN  -v /var/run/docker.sock:/var/run/docker.sock -v /usr/bin/docker:/usr/bin/docker --mount type=bind,source=/,target=/mnt,bind-propagation=rslave labgenomicatumorsec/tumorsec:0.1 /bin/bash
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

Ahora podemos observar las corridas de tumorSec que fueron compartidas a la cuenta tumorsec@gmail.com

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
Con la ruta de BaseSapce de la corrida en la imagen podemos correr el pipeline de tumorSec. Ojo: Hasta el momentocada vez que se corre docker run, se debe montar la carpeta de baseSpace. Existe una manera de realizar cambios al ejecutar la imagen docker(crear un contenedor) y guardar este contenedor con docker push en DockerHub, sin embargo, todavia no se encuentra implementado.  

### 4. Configurar archivo con parametros de entrada

Una vez montado el directorio de BaseSpace, es necesario proceder a configurar los parámetros de entrada para la ejecucion del pipeline. Para esto, se creó en la imgaen TumorSec un archivo ```00.conf_docker.ini ``` en la carpeta ```/Docker/TumorSec ``` el cual será cargado al inicio de la ejecución del pipeline. Este archivo contiene los parámetros que se pueden modificar, aquellos que no modificables se encuentran en el archivo ```00.inputs_TumorSec.ini``` ,el cual no debe ser alterado.

archivo: ``00.conf_docker.ini```

```
EXT_DBS="/mnt/home/egonzalez/Inputs_TumorSec/genome"
ANNOVAR_HDB="/mnt/datos/reference/annot/annovar/humandb"

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

### 5. Ejecución del Pipeline



```
docker run --privileged -ti -rm --name tumorsecRUN  -v /var/run/docker.sock:/var/run/docker.sock -v /usr/bin/docker:/usr/bin/docker --mount type=bind,source=/,target=/mnt,bind-propagation=rslave labgenomicatumorsec/tumorsec:0.1 /bin/bash

[root@2efef00d36c2 TumorSec]# ls
00.inputs_TumorSec.ini  02.QC_Reports.sh        04.QC_dendogram.sh  scripts
01.Run_TumorSec.sh      03.Variants_reports.sh  complement

```

```sh 01.Run_TumorSec.sh```

```/home/egonzalez/workSpace/runs_TumorSec/Docker_subset_200122````


### 6. Archivos de salida e interpretación de resultados. 

