## Tutorial para la ejecución del Pipeline TumorSec

A continuación se describe de manera detallada los pasos necesarios para ejecutar el pipeline de TumorSec utilizando la imagen de docker ```labgenomicatumorsec/tumorsec:0.1```. Esta, se encuentra en un repositorio privado en el servidor DockerHub (https://hub.docker.com/).  Para la descarga, es necesario tener información de la cuenta de Docker Hub del proyecto.

Para ejecutar este pipeline se asume instalado el programa docker de manera local en host. Si no se encuentra instalado, ejecutar:```sudo yum -y install docker``` en Sistemas operativos Centos. Este tutorial fue testeado con ```docker v18.06.0-ce``` en el servidor Genoma3 del laboratorio Genomed. Facultad de medicina, Universidad de Chile.

### 1. Pre-configuración.

Para ejecutar el paquete bioinformático TumorSec utilizando docker, es necearios realizar configuraciones previas a la ejecución del pipeline. Estas solo se deben ejecutar una vez, en caso de volver a correr el docker TumorSec, solo se deben seguir las instruciones del punto 2.

#### 1.1. Configuración de usuario.

Para poder ejecutar la imagen ```labgenomicatumorsec/tumorsec:0.1``` , es necesario que el usuario tenga los permisos para correr docker. Para esto, el administrador(a) de sistema debe agregar al usuario al grupo docker del host.  En caso de no existir el grupo docker, debe ser creado. 
```
groupadd --system docker
sudo usermod -aG docker $USER
```
Siendo ```$USER``` el nombre de usuario. Para verificar los permisos de usuario, este puede ejecutar ```docker image ls``` para listar las imagenes del sistema. En caso de arrojar error, reinicie el servicio docker.
```
sudo systemctl restart docker
```
#### 1.2. Descargar imagen docker Tumorsec

La imagen ```labgenomicatumorsec/tumorsec:0.1``` debe estar disponible en la sistema para su ejecución. Esta, se encuentra en la nube en un repositorio privado de Docker Hub. Procedemos a descargar la imagen.

Primero verificamos que la imagen TumorSec no se encuentra en el sistema. Si se encuentra en la lista desplegada, podemos omitir este paso. Podemos observar que en este caso solo tenemos disponible una imagen de centos.
```
docker image ls
REPOSITORY                     TAG                 IMAGE ID            CREATED             SIZE
centos                         7                   5e35e350aded        3 months ago        203MB
```
Ejecutamos las siguientes instrucciones para la descarga.
```
docker login docker.io
Username: tumorsec@gmail.com
Password: UDT-seq#19

docker pull labgenomicatumorsec/tumorsec:0.1
```
Para verificar que se descargó la imagen:
```
docker image ls
REPOSITORY                     TAG                 IMAGE ID            CREATED             SIZE
labgenomicatumorsec/tumorsec   0.1                 b71f244458dd        32 minutes ago      10.3GB
centos                         7                   5e35e350aded        3 months ago        203MB
```
#### 1.3 Descargar bases de datos externas

La imagen ```labgenomicatumorsec/tumorsec:0.1``` contiene un script en bash ```DB_download.sh``` que se encuentra dentro del directorio ```/Docker/TumorSec ``` de la imagen. Este script permite descargar las bases de datos que no fueron intregadas en la imagen (por el tamaño) y que son necesarias para ejecutar el pipeline de TumorSec. 

Para ejecutar este script se debe correr la imagen docker ```labgenomicatumorsec/tumorsec:0.1``` de manera interactiva (parámetro -ti en docker run), ademas de montar el directorio de descarga del host en el contenedor. Para esto, ejecutar el siguiente comando:
```
docker run --privileged -ti --rm \ 
--mount type=bind,source=/path/to/output_DB,target=/mnt/docker/DB_TumorSec,bind-propagation=rslave \
labgenomicatumorsec/tumorsec:0.1 /bin/bash
```
Siendo ```/path/to/output_DB``` el directorio de salida donde se descargarán las bases de datos en el host. Dentro del contenedor, este directorio será ```/mnt/docker/DB_TumorSec```(no modificar), el cual, debe ser el parámetro de entrada para el script ``` DB_download.sh``` (Sección 2.3).

Dentro del contenedor docker que acabamos de crear con docker run, se encuentra el directorio ```/docker/tumorSec ```, podemos observar con ```ls``` que se encuentran los scripts necesarios para correr TurmorSec. Ejecutar el script ``` DB_download.sh``` e ingresar la ruta donde serán almacenadas las bases de datos. A contiuación se observa un ejemplo:
```
cd /docker/tumorSec
sh DB_download.sh
Enter the output directory:
/mnt/docker/DB_TumorSec
```
La ruta ```/mnt/docker/DB_TumorSec``` se encuentra en el archivo de configuración por defecto, por tanto, no es un parámetro modificable.

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

#### 1.4 Crear volumen para datos internos en la imagen

Existen archivos dentro de la imagen de docker ```labgenomicatumorsec/tumorsec:0.1``` que son propios del pipeline, por ejemplo el archivo .bed que contiene las regiones blanco del panel de genes, la base de datos cosmic, el logo del laboratorio, ademas de los script que conforman el pipeline TumorSec. Para que estos datos sean vizualizados por otros contenedores, es necesario crear un volumen que será utilizado para montar los datos de la image.

Crear un volumen con el nombre ```datatumorsec```
```
docker volume create datatumorsec
```
Para verificar que fue creado:
```
docker volume ls
DRIVER              VOLUME NAME
local               datatumorsec
```
Una vez creado el volumen, este será utilizado para montar el directorio ```/docker``` que se encuentra en la imagen. Esto se debe realizar a momento de crear el contenedor ```docker run``` (Sección 2)

### 2. Ejecutar pipeline TumorSec.

A continuación se lista los pasos necesarios para correr el pipeline de TumorSec para una corrida en particular. Cada vez que existe una nueva corrida de TumorSec, se deben seguir las siguientes instrucciones. Se asume que las pre-configuraciones ya se encuentran en el host. (Sección 1)

#### 2.1 Crear un contenedor de TumorSec.

Creamos un contenedor de TumorSec, ejecutando ```docker run```. El cual, desplegará una nueva terminal, con esto verificamos que estamos dentro del contenedor. Cualquier cambio realizado en el contenedor, será eliminado al momento de ser borrado el contenedor, por tanto, cada vez que existe una nueva corrida de secuenciación se debe crear un nuevo contenedor. 
```
docker run --privileged -ti -d \
-v datatumorsec:/docker \
-v /var/run/docker.sock:/var/run/docker.sock \
-v $(which docker):/usr/bin/docker \
--mount type=bind,source=/home/,target=/mnt/home,bind-propagation=rslave \
--mount type=bind,source=/path/to/output_DB,target=/mnt/docker/DB_TumorSec,bind-propagation=rslave \
labgenomicatumorsec/tumorsec:0.1 /bin/bash
```
Descripción de los parámetros:
- ```docker run``` : Crea un contenedor docker.
- ```--privileged``` : Da permisos root dentro del contenedor.
- ```-ti``` : Permite crear un contenedor interactivo.
- ```--rm``` : Elimina el contenedor al ingresar exit en la consola de este.
- ```-v datatumorsec:/docker``` : Monta el directorio ```/docker``` de la imagen en el volumen ```datatumorsec```
- ```-v /var/run/docker.sock:/var/run/docker.sock``` : Vincula el docker del host al nuevo contenedor.
- ```-v $(which docker):/usr/bin/docker``` : Vincula el binario (docker) del host al nuevo contenedor.
- ```--mount type=bind,source=/home,target=/mnt/home,bind-propagation=rslave```: Monta los datos del ```/home``` del host al nuevo contenedor en ```/mnt/home``` de manera recursiva, así la ejecución docker-in-docker puede vizualizar los datos. 
- ```--mount type=bind,source=/path/to/output_DB,target=/mnt/docker/DB_TumorSec,bind-propagation=rslave```: Monta los datos del ```/path/to/output_DB``` del host al nuevo contenedor en ```/mnt/docker/DB_TumorSec``` de manera recursiva.
- ```labgenomicatumorsec/tumorsec:0.1```: Imagen docker de TumorSec que fue descargada de Docker Hub. 
- ```/bin/bash```: Contenedor ejecuta un bash, así permite ingresar en modo consola dentro del contenedor.

El parámetro ```/path/to/output_DB``` en ```--mount type=bind,source=/path/to/output_DB,target=/mnt/docker/DB_TumorSec,bind-propagation=rslave``` debe ser remplazado por la ruta absoluta, donde se encuentran las bases de datos externas que fueron previamente descargadas (Seccion 1.3). Ademas, el parámetro ```/home``` en ```--mount type=bind,source=/home,target=/mnt/home,bind-propagation=rslave``` debe ser remlplazado si el directorio de salida para la corrida no esta en el ```/home``` del usuario.

Opcional: Una vez ejecutado el comando anterior podemos vizualizar los datos de la imagen: 
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
Como buena practica, podemos vizualizar los contenedores del sistema con ```docker ps -a``` para evitar el exceso de contenedores, podemos elimnarlos con el comando ```docker rm ID_container```

#### 2.1 Montar datos de BaseSpace contenedor.

Para ejecutar el pipeline de TumorSec, es necesario montar los datos de BaseSpace dentro de la imagen docker. Para montar los datos, se debe seguir las siguientes instrucciones. El programa basemount se encuentra instalado en la imagen. 

Se debe estar dentro de un contenedor creado a partir de la imagen, si no es así, ejecutar el siguiente comando:
```
docker run --privileged -ti --rm -v datatumorsec:/docker -v /var/run/docker.sock:/var/run/docker.sock -v /usr/bin/docker:/usr/bin/docker --mount type=bind,source=/,target=/mnt,bind-propagation=rslave labgenomicatumorsec/tumorsec:0.1 /bin/bash
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
- Usuario:tumorsec@gmail.com
- Contraseña: UDT-seq#19

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

#### 1.5 Configurar archivo con parámetros de entrada

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

#### 2.4 Correr pipeline. 
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

### 3. Contrucción de imagen docker 

El archivo ```Dockerfile``` contiene los comandos necesarios para instalar todos los pre-requisitos del pipeline TumorSec, ademas de integrar las bases de datos y archivos específicos del pipeline. Utilizando la configuración del ```Dockerfile```que se encuentra en el directorio ```/home/egonzalez/workSpace/docker_PipelineTumorsec```, se construyó la imagen docker la cual fue almacenada en un repositorio privado en DockerHub.

- Cuenta: tumorsec@gmail.com        
- Contraseña:UDT-seq#19

El contexto para construir la imagen de docker para el pipeline TumorSec, se encuentra en la siguiente ruta
```/home/egonzalez/workSpace/docker_PipelineTumorsec```

```
cd /home/egonzalez/workSpace/docker_PipelineTumorsec
docker build -t labgenomicatumorsec/tumorsec:0.1 .
```

#### 4. Archivos de salida e interpretación de resultados. 

