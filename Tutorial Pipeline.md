## Tutorial para la ejecución del Pipeline TumorSec

A continuación se describe de manera detallada los pasos necesarios para ejecutar el pipeline de TumorSec utilizando la imagen de docker ``` lgc/tumorsec:0.1```, la cual, se encuentra como un repositorio privado en el servidor Docker Hub (https://hub.docker.com/).  Para la descarga, es necesario tener información de la cuenta de Docker Hub del proyecto. (ver sección 2)

Ademas, se deben descargar las bases de datos de entrada necesarias para ejecutar el software ANNOVAR, el cual, las utiliza para la anotación funcional de las variantes. La ruta local de descarga de las bases de dato se debe agregar al archivo de configuración de TumorSec (ver sección 1 y 4)

Una vez descargadas las bases de datos y la imagen docker, se debe ejecutar la imagen de docker de manera interactiva (parámetro -ti en docker run) y montar la cuenta de TumorSec dentro de del contenedor creado, de esta manera podemos acceder a los datos de BaseSpace, necesarios para el demultiplezado de datos y la generación de reportes. (ver seccion 3). Luego de estas configuraciones, podemos ejecutar el pipeline de Tumorsec. (ver sección 5)

Para ejecutar este pipeline se asume instalado el programa docker de manera local en el servidor. Si no se encuentra instalado ejecutar sudo yum -y install docker. Este se encuentra instalado en el servidor Genoma3 de Genomedlab, y la version con la cual fue testeado este tutorial es la version 18.06.0-ce.

### 1. Descargar imagen docker Tumorsec

El archivo ```Dockerfile``` contiene los comandos necesarios para instalar todos los pre-requisitos del pipeline TumorSec, ademas de las bases de datos y archivos específicos del pipeline. Utilizando la configuración del ```Dockerfile```que se encuentra en el directorio ```/home/egonzalez/workSpace/docker_PipelineTumorsec```, se construyó la imagen docker la cual fue almacenada en un repositorio privado en DockerHub.

El contexto para construir la imagen de docker para el pipeline TumorSec, se encuentra en la siguiente ruta
```/home/egonzalez/workSpace/docker_PipelineTumorsec``` 

Para volver a contruir la imagen de docker, se debe ejecutar:
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
Podemos observar que la actual imagen de docker ```labgenomicatumorsec/tumorsec:0.1``` tiene un tamaño de 8.05 GB, aquellas bases de datos necesarias en el pipeline y de mayor tamaño deben ser descargadas antes de ejecutar TumorSec. Es recomendable tener una imagen menor a 10 GB, para evitar la sobrecarga de datos temporales que efecta el funcionamiento del sistema operativo. El espacio de docker destinado a imagenes es limitado, en caso de sobrepasar el límite se deben reconfigurar los tamaños por defecto establecidos al momento de instalar docker.

Una vez terminados los cambios de la imagen, se deben actualizar la imagen del repositorio en DockerHub.

Primero, se debe
```
docker login docker.io
Username: Tumorsec@gmail.com
Password: UDT-seq#19

docker push labgenomicatumorsec/tumorsec:0.1

```
Para un segundo cambio, no es necesario ingregar usuario y contraseña.

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
 Una vez descargada, podemos comenzar a descargar las bases de datos necesarios para TumorSec.

### 2. Descargar bases de datos de ANNOVAR y hg19

Como parte de la imagen de docker ```labgenomicatumorsec/tumorsec:0.1``` se agregó un script en bash ```DB_download.sh``` que se encuentra dentro del directorio ```/Docker/TumorSec ``` de la imagen de docker. Este script permite descargar las bases de datos que no fueron intregadas en la imagen (por el tamaño) y que son necesarias para ejecutar el pipeline de TumorSec. 

Para ejecutar este script, se debe correr la imagen docker ``` lgc/tumorsec:0.1``` de manera interactiva (parámetro -ti en docker run). Se debe ejecutar el siguiente comando.

```
docker run --privileged -ti -d --name tumorsecRUN  -v /var/run/docker.sock:/var/run/docker.sock -v /usr/bin/docker:/usr/bin/docker --mount type=bind,source=/,target=/mnt,bind-propagation=rslave labgenomicatumorsec/tumorsec:0.1 /bin/bash
```
Al ingresar podemos observar con ```ls``` los scripts necesarios para correr TurmorSec. Ejecutar el script e ingresar la ruta donde serán almacenadas de manera local las bases de datos, antecedido de /mnt/. A contiuación se observa un ejemplo de ejecucion.

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

Bases de datos descargadas para el pipeline(GATK, SomaticSeq entre otros)
-Hg19
-dbsnp_138

### 3. Montar datos de BaseSpace en Docker

```
cd /Docker/
mkdir BaseSpace
basemount BaseSpace/

[root@2efef00d36c2 Docker]# basemount BaseSpace/
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
Copiar el URL en el navegador e ingresar los datos de la cuenta TumorSec. 
usuario:tumorsec
contraseña: UDT-seq#19

y de manera automáitica se montarán los datos de BaseSapce en la carpeta /BaseSpace


### 4. Configurar archivo con parametros de entrada


### 5. Ejecucion del Pipeline



```
docker run --privileged -ti -rm --name tumorsecRUN  -v /var/run/docker.sock:/var/run/docker.sock -v /usr/bin/docker:/usr/bin/docker --mount type=bind,source=/,target=/mnt,bind-propagation=rslave labgenomicatumorsec/tumorsec:0.1 /bin/bash

[root@2efef00d36c2 TumorSec]# ls
00.inputs_TumorSec.ini  02.QC_Reports.sh        04.QC_dendogram.sh  scripts
01.Run_TumorSec.sh      03.Variants_reports.sh  complement

```

```sh 01.Run_TumorSec.sh```

```/home/egonzalez/workSpace/runs_TumorSec/Docker_subset_200122````


### 6. Archivos de salida e interpretación de resultados. 

