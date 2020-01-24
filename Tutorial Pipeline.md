## Tutorial para la ejecución del Pipeline Tumorsec

A Continuación se describe de manera detalla, los pasos necesarios para ejecutar el pipeline de TumorSec utilizando la imagen de docker labgenomicatumorsec/tumorsec:0.1, la cual se encuentra como un repositorio privado en el servidor Docker Hub.  Para descargar esta imagen, es necesario tener información de la cuenta de Docker Hub del proyecto. En caso de dudas enviar correo (evefeliu@gmail.com) (ver sección 2)
Ademas se deben descargar las bases de datos de entrada, necesarias para ejecutar el software ANNOVAR, el cual utiliza una serie de bases de datos para la anotación funcional de las variantes. La ruta de descarga de las bases de datos de manera local, debe agregarse al archivo de configuración de entrada. (ver sección 1 y 4)

Una vez descargadas las bases de datos y la imagen docker, se debe ejecutar la imagen de docker y montar la cuenta de Tumorsec dentro de del contenedor creado, de esta manera podemos acceder a los datos de BaseSpace, necesarios para el demultiplezado de datos y la generación de reportes. (ver seccion 3). Luego de estas configuraciones, podemos ejecutar el pipeline de Tumorsec. (ver sección 5)
 

### 1. Descargar bases de datos de ANNOVAR
### 2. Descargar imagen docker Tumorsec
### 3. Montar datos de BaseSpace en Docker
### 4. Configurar archivo con parametros de entrada
### 5. Ejecucion del Pipeline
### 6. Archivos de salida e interpretación de resultados

