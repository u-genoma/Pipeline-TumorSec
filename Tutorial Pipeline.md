## Tutorial para la ejecución del Pipeline TumorSec

A continuación se describen de manera detallada los pasos necesarios para ejecutar el pipeline de TumorSec utilizando la imagen de docker ```labgenomicatumorsec/tumorsec:0.1```, la cual se encuentra como un repositorio privado en el servidor Docker Hub.  Para la descarga, es necesario tener información de la cuenta de Docker Hub del proyecto. (ver sección 2)

Ademas, se deben descargar las bases de datos de entrada necesarias para ejecutar el software ANNOVAR, el cual, las utiliza para la anotación funcional de las variantes. La ruta local de descarga de las bases de dato se debe agregar al archivo de configuración de TumorSec (ver sección 1 y 4)

Una vez descargadas las bases de datos y la imagen docker, se debe ejecutar la imagen de docker de manera interactiva (parámetro -ti en docker run) y montar la cuenta de TumorSec dentro de del contenedor creado, de esta manera podemos acceder a los datos de BaseSpace, necesarios para el demultiplezado de datos y la generación de reportes. (ver seccion 3). Luego de estas configuraciones, podemos ejecutar el pipeline de Tumorsec. (ver sección 5)
 

### 1. Descargar bases de datos de ANNOVAR
#### 1.1 Instalar ANNOVAR de manera local

#### 1.2 Descargar bases de datos

Lista de Bases de datos utilizadas: 
- refGene
- AFR.sites.2015_08
- AMR.sites.2015_08
- EAS.sites.2015_0
- EUR.sites.2015_08
- SAS.sites.2015_08,exac03
- dbnsfp35c
- cadd13
- avsnp150
- cosmic70
- clinvar_20180603

Comandos para la descarga. 


```annotate_variation.pl -downdb -buildver hg19 -webfrom annovar refGene humandb/ ```


### 2. Descargar imagen docker Tumorsec
### 3. Montar datos de BaseSpace en Docker
### 4. Configurar archivo con parametros de entrada
### 5. Ejecucion del Pipeline
### 6. Archivos de salida e interpretación de resultados

