#/usr/bin/python
import sys

ped = open(sys.argv[1],"r")
for line in ped:
	line = line.rstrip("\n")
	aux = line.split(" ")
	new_line = aux[0] ##Nombre muestra
	aux = aux[6:]
	for i in range(0,len(aux),2):
		genotype = aux[i]+aux[i+1]
		new_line = new_line+"\t"+genotype
	print new_line
ped.close()
