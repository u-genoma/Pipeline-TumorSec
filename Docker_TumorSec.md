
## Imagen de Docker: pipeline TumorSec.


```
/home/egonzalez/workSpace/Docker_centos
```


| librerias de python  |  
|----------|
| Fpdf - 1.7.2 |
| numpy - 1.18.1 | 
| argparse - 1.4.0 | 


```
#!/bin/bash

set -e

echo -e "Start at `date +"%Y/%m/%d %H:%M:%S"`" 1>&2

docker run --rm -v /:/mnt egonzalez/tumorsec_centos:0.1 \
sh /programs/01.Run_TumorSec.sh --input--dir /mnt//home/egonzalez/workSpace/runs_TumorSec/200109_TumorSec \
--threads 20 \
--baseSpace /mnt//home/egonzalez/BaseSpace/Runs/Tumorsec20200109 \
--dendogram y \
--input--data /mnt//home/egonzalez/workSpace/PipelineTumorSec/00.inputs_TumorSec.ini

echo -e "Done at `date +"%Y/%m/%d %H:%M:%S"`" 1>&2

```



```
 docker run -ti --rm -v /:/mnt/ egonzalez/tumorsec_centos:0.1 /bin/bash
```








```
FROM centos:7
RUN yum update -y && yum -y install yum-utils && yum -y groupinstall development && yum -y install https://centos7.iuscommunity.org/ius-release.rpm
RUN yum install -y python36u

RUN yum install -y \
       java-1.8.0-openjdk \
       java-1.8.0-openjdk-devel

ENV JAVA_HOME /etc/alternatives/jre

RUN yum -y install R

RUN Rscript -e 'install.packages("ggplot2", repos="https://cran.rstudio.com")'
RUN Rscript -e 'install.packages("dplyr", repos="https://cran.rstudio.com")'
RUN Rscript -e 'install.packages("tidyr", repos="https://cran.rstudio.com")'
RUN Rscript -e 'install.packages("stringr", repos="https://cran.rstudio.com")'
RUN Rscript -e 'install.packages("reshape2", repos="https://cran.rstudio.com")'
RUN Rscript -e 'install.packages("gridExtra", repos="https://cran.rstudio.com")'
RUN Rscript -e 'install.packages("vcfR", repos="https://cran.rstudio.com")'
RUN Rscript -e 'install.packages("writexl", repos="https://cran.rstudio.com")'
RUN Rscript -e 'install.packages("gtools", repos="https://cran.rstudio.com")'
RUN Rscript -e 'install.packages("BiocManager", repos="https://cran.rstudio.com")'
RUN Rscript -e 'install.packages("remotes", repos="https://cran.rstudio.com")'
#RUN Rscript -e 'remotes::install_github("PoisonAlien/maftools")'

RUN yum -y install wget

RUN wget https://repo.anaconda.com/archive/Anaconda3-2019.10-Linux-x86_64.sh
RUN bash Anaconda3-2019.10-Linux-x86_64.sh -b -p $HOME/anaconda
RUN /root/anaconda/condabin/conda install -c bioconda mosdepth=0.2.5
RUN /root/anaconda/condabin/conda install -c bioconda bwa=0.7.12
RUN /root/anaconda/condabin/conda install -c bioconda samtools=1.3.1
RUN /root/anaconda/condabin/conda install -c bioconda bedtools=2.26.0 
RUN /root/anaconda/condabin/conda install -c bioconda qualimap=2.2.2a ## real 2.2.2a
RUN /root/anaconda/condabin/conda install -c dranew bcl2fastq=2.19.0 ## real 2.20.0
RUN /root/anaconda/condabin/conda install -c bioconda illumina-interop

RUN yum -y install python-pip
RUN pip install --upgrade pip
#RUN pip install matplotlib
RUN pip install requests

WORKDIR /programs
COPY fastp/ fastp
COPY GenomeAnalysisTK.jar GenomeAnalysisTK.jar
COPY picard.jar picard.jar

ENV PATH="/programs/fastp:/root/anaconda/bin:/programs:$PATH"

COPY 00.inputs_TumorSec.ini 00.inputs_TumorSec.ini
COPY 01.Run_TumorSec.sh 01.Run_TumorSec.sh
COPY 02.QC_Reports.sh 02.QC_Reports.sh
COPY 03.Variants_reports.sh 03.Variants_reports.sh
COPY 04.QC_dendogram.sh 04.QC_dendogram.sh 
COPY complement/ complement
COPY scripts/ scripts

ENTRYPOINT ["/programs/01.Run_TumorSec.sh"]
