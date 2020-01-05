#coding=utf-8
########################################################################################################################
#  DESCRIPCION: Este script a partir de un VCF, ejecuta la anotacion de CGI (envia un trabajo al sitio web) y retorna
#  un archivo .zip de salida en la ruta indicada
#
#  python CGI.py --vcf /Users/egonzalez/Desktop/Reporte_Variantes/PUCOv001_S1.annovar.hg19_multianno.vcf  \
#  --output /Users/egonzalez/Desktop/Reporte_Variantes/PUCOv001_S1_CGI.zip
#
#  FECHA: 26 Junio 2019
#  AUTOR: Evelin Gonzalez Feliu
########################################################################################################################

import requests
import time
import argparse
import pandas as pd
from pandas import DataFrame

def execute_CGI(vcf,output):
    headers = {'Authorization': 'evefeliu@gmail.com e7225bc0f9e09b6260bc'}
    payload = {'cancer_type': 'SOLID', 'title': 'TumorSec'}
    r_exec = requests.post('https://www.cancergenomeinterpreter.org/api/v1',
                headers=headers,
                files={
                        'mutations': open(vcf, 'rb'),
                        },
                data=payload)
    response=r_exec.json()
    print(response)
    if (len(response)!=20): ### SI NO RETORNA UN JOBID, SE INDICA QUE HAY UN ERROR.
        print("Problemas para anotar "+vcf+ 'en el CGI')
        print("Se eliminaran analisis anteriores del GCI y se volverá a ejecutar la tarea")
        delete_jobs(headers)
        execute_CGI(vcf,output)
    else:
        print('Ejecutando CGI ----> JOB_ID: '+response)
        print ('INPUT ----->'+vcf)
        time.sleep(60)
        flag=False
        while(flag==False): #### MIENTRAS EL STATUS DEL LOG SEA DIFERENTE A DONE, ESTE SIGUE ITERANDO.
            resp_logs=get_log(headers,response)
            df_resp = DataFrame(resp_logs)
            if (resp_logs['status']=='Done'):
                download_results(headers,response,output)
                print('DOWNLOAD RESULTS ----->'+output)
                print('LOG:')
                flag=True
                for dato in resp_logs['logs']:### IMPRIME EL LOG DEL CGI POR PANTALLA
                    print(dato, end='')
            else:
                time.sleep(60)
    ## {'error_code': 403, 'message': 'You have reached the maximum number of jobs permitted. Please, delete one before submitting a new job.'}
    #### IF ERROR CODE 403 --> DELETE JOBS AND RUN AGAIN

def delete_jobs(headers):
    ##### GET LIST OF JOB ID BY USUER
    r_jobs_id = requests.get('https://www.cancergenomeinterpreter.org/api/v1', headers=headers)
    resp_jobs_id = r_jobs_id.json()

    for job in resp_jobs_id: #### DELETE ALL JOBS OF USER
        r = requests.delete('https://www.cancergenomeinterpreter.org/api/v1/'+job, headers=headers)
        r_json =r.json()
        print(r_json)

def get_log(headers,jobid):
    payload={'action':'logs'}
    r_logs = requests.get('https://www.cancergenomeinterpreter.org/api/v1/'+jobid, headers=headers, params=payload)
    return (r_logs.json())

def download_results(headers, jobid,output):
    payload={'action':'download'}
    r_download = requests.get('https://www.cancergenomeinterpreter.org/api/v1/'+jobid, headers=headers, params=payload)
    with open(output, 'wb') as fd:
        fd.write(r_download._content)
    ### Arguments, archivo vcf de entrada, tipo de cancer, title: nombre_corrida_muestra

def main(args):
    output= args.output
    vcf=args.vcf
    execute_CGI(vcf,output)

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Ejecuta el CGI a partir de un archivo VCF')
    parser.add_argument('--vcf', type=str, help='Archivo VCF para ser anotado en CGI',required=True, default= False)
    parser.add_argument('--output', type=str, help='Ruta y nombre del .zip de salida, ejemplo: /path/to/output.zip', required=True, default=False )
    args = parser.parse_args()

    main(args)
