#!/bin/bash 

SERVERNAME="$2"
FECHA="$3"

configfile="$(pwd)/conf/gnuplot_statistics.conf"
configfile_secure="$(pwd)/conf/gnuplot_statistics.conf.secure"

###########################################################################
#### Condicionales de parametros ,directorios temporales, configuracion
###########################################################################
## Si el directorio temporal no existe lo creo
if [[ ! -e tmp ]]; then
	mkdir tmp
fi

## Si el directorio de configuracion no existe lo creo
if [[ ! -e conf ]]; then
	mkdir conf
	echo "NO EXISTE EL DIRECTORIO DE CONFIGURACION. FAVOR CHEQUEAR"
	exit 1
fi 

## Si el directorio input donde recojo los ficheros no existe lo creo
if [[ ! -e input ]]; then
        mkdir input
fi

if egrep -q -v '^#|^[^ ]*=[^;]*' $configfile; then
echo "Config file is unclean, trying to cleaning" >&2
 # filter the original to a new file
  #egrep '^#|^[^ ]*=[^;&]*' "$configfile" > "$configfile_secured"
  #echo "Please check the file $(echo $configfile_secured). If the configuration looks ok rename it to $(echo $configfile). Returning to shell!!!"
  #exit 4
source $configfile
else
  echo "Reading configuration..."
  source $configfile
fi

#### Condicional ayuda
if [ $# -eq 0 ]; then
        echo "ERROR - Chequea los parametros ingresados - No hay parametros"
## invocar funcion ayuda
exit 1
fi
###########################################################################
###########################################################################


###########################################################################
#### Limpieza de variables/ficheros temporales
###########################################################################
#### Limpio variables temporales
limpieza ()
{
#for i in $(egrep '^#|^[^ ]*=[^;&]*' $configfile | grep -v "#" | grep TMP | awk -F'=' '{print $1}'|grep -v DIR); do rm -f "$"$i; touch $"$i"; done
#env
rm -f $TMPVMSTAT
rm -f $TMPVMSTAT_1
rm -f $TMPVMSTAT2
rm -f $TMPSARQ
rm -f $TMPSARQ2
rm -f $TMPPRSTATCPU
rm -f $TMPPRSTATCPU2
touch $TMPVMSTAT
touch $TMPVMSTAT_1
touch $TMPVMSTAT2
touch $TMPSARQ
touch $TMPSARQ2
touch $TMPPRSTATCPU
touch $TMPPRSTATCPU2
#rm -f $INPUTDIR/*.out
}
###########################################################################
###########################################################################

###########################################################################
#### FUNCIONES DE AGREGAR FECHA / HORA A FICHEROS
###########################################################################
#### Limpio fichero vmstat de valores que no me sirven
agrego_fecha_vmstat ()
{
#### ciclo loco
while read line
do
        ((g++))
        if [ "$g" == "1" ]; then
                time=0;
        else
                time=$((time + 30))
        fi
        time2=$((time + 30))

        to=`date -d "2012-02-24 00:00:00 ART  $time2 seconds" +"%d/%m/%y %H:%M:%S"`

	## envio a variable temporal para procesar luego
	echo $to $line >> $TMPVMSTAT
done < $TMPVMSTAT_1
limpio_valores_vmstat
}

agrego_dia_vmstat ()
{
#### ciclo loco
while read line
do
        ((g++))
        if [ "$g" == "1" ]; then
                time=0;
        else
                time=$((time + 30))
        fi
        time2=$((time + 30))

        to=`date -d "2012-02-24 ART $time2 seconds" +"%d/%m/%y"`

        ## envio a variable temporal para procesar luego
	echo $to $line >> $TMPVMSTAT
done < $TMPVMSTAT_1
limpio_valores_vmstat
}

# funcion diseñada para agregar la fecha y hor segn corresponda en el fichero $PRSTATCPUFE, 
# procesado anteriormente por la funcion limpiar_prstat_cpu
# formato de salida
agrego_fecha_prstat_cpu ()
{
time=-1800
while read line
do
        ((g++))
        if [ "$g" == "1" ]; then
                time=0;
        else
                time=$((time + 900))
        fi
        time2=$((time + 900))

        to=`date -d "2012-02-24 00:00:00 ART  $time2 seconds" +"%d/%m/%y %H:%M:%S"`

        ## envio a variable temporal para procesar luego
        echo $to $line >> $TMPPRSTATCPU2
done < $TMPPRSTATCPU
}
###########################################################################
###########################################################################

###########################################################################
#### FUNCIONES DE LIMPIEZA DE FICHEROS
###########################################################################
# funcion diseñada para limpiar los valores que no se usan del fichero prstat. solo dejo los valores
# ej: remplazo "Total: 223 processes, 418 lwps, load averages: 0.32, 0.33, 0.35" por "223 418 0.32, 0.33, 0.35"
# y envio al archivo temporal numero 1, asi puedo continuar agregandole la fecha a cada fichero
# Invocada por agrego_fecha_prstatcpu
limpiar_prstat_cpu()
{
cat $PRSTATCPUFILE |grep "load averages"| awk '{print $2 " " $4 " " $8 " " $9 " " $10}' > $TMPPRSTATCPU
}

# 
limpiar_vmstat ()
{
#el % de memoria se calcula con 
# prtconf| grep "Memory size"| awk '{print $3*1024}'
# swap -l | awk '{print $4}'|grep -v blocks
#cat $VMSTATFILE |grep -v swap | grep -v memory | grep -v started | grep -v ended | grep 0 |grep -v vmstat | awk '{print $1 " " $2 " " $3 " " 100-$4/145435344*100 " " $5/16777216*100 " " $6 " " $7 " " $8 " " $9 " " $10 " " $11 " " $12 " " $13 " " $14 " " $15 " " $16 " " $17 " " $18 " " $19 " " $20 " " $21 " " $22}' > $TMPVMSTAT_1
#cat $VMSTATFILE |grep -v swap | grep -v memory | grep -v started | grep -v ended | grep 0 |grep -v vmstat | awk '{print $1 " " $2 " " $3 " " $4/145435344*100 " " 100-$5/16777216*100 " " $6 " " $7 " " $8 " " $9 " " $10 " " $11 " " $12 " " $13 " " $14 " " $15 " " $16 " " $17 " " $18 " " $19 " " $20 " " $21 " " $22}' > $TMPVMSTAT_n
#cat $VMSTATFILE |grep -v swap | grep -v memory | grep -v started | grep -v ended | grep 0 |grep -v vmstat | awk '{print $1 " " $2 " " $3 " " 100-$4/$swapmemory*100 " " 100-$5/$phymemory*100 " " $6 " " $7 " " $8 " " $9 " " $10 " " $11 " " $12 " " $13 " " $14 " " $15 " " $16 " " $17 " " $18 " " $19 " " $20 " " $21 " " $22}' > $TMPVMSTAT_1
cat $VMSTATFILE |grep -v swap | grep -v memory | grep -v started | grep -v ended | grep 0 |grep -v vmstat > $TMPVMSTAT_1
}

# 
limpio_valores_vmstat ()
{
#cat $OUTFILE | grep -v ":30" | egrep "0:00|5:00" | egrep "00:00|15:00|30:00|45:00"> $OUTFILE2
#cat $OUTFILE | grep -v ":30" | egrep -v ":00:|:5:|:10:|:15:|:20:" | egrep "13:|14:|15:|16:|17:|18:|19:|20:|21" > $OUTFILE2
#cat $OUTFILE | grep -v ":30 " | egrep -v "24/02/12 21:|24/02/12 22:|24/02/12 23:" > $OUTFILE2
#cat $OUTFILE > $OUTFILE2
cat $TMPVMSTAT > $TMPVMSTAT2
}

limpiar_sarq ()
{
cat $SARQFILE | egrep -v "started|ended|runq-sz|Average|SunOS|sar" | sort | uniq | grep -v "^$" > $TEMPSARQ
}
###########################################################################
###########################################################################


###########################################################################
#### FUNCIONES ESPECIFICAS DE INTERACCION PARA CIERTOS PLOT
###########################################################################
#pregunta la cantidad de memoria del equipo para clacular el porcentaje de uso desde los ficheros vmstat
cantidad_de_memoria ()
{
echo -e "Cuanta memoria fisica tiene el servidor (Kb)"
read phymemory
echo -e "Cuanta memoria swap tiene el servidor (Kb)"
read swapmemory
}

generar_todos_los_graficos_produccion()
{
limpieza
limpiar_vmstat
agrego_dia_vmstat
limpiar_prstat_cpu
agrego_fecha_prstat_cpu
plot_vmstat_cpu
#plot_vmstat_memory
plot_vmstat_pageinout
plot_vmstat_queued
#plot_prstat_cpu_load_average
}

# Se buscan ficheros de configuracion vmstat.out, sar-q.out y prstat-cpu.out con los parametros enviados
buscar_ficheros_prod()
{
find . -name vmstat.out |grep $SERVERNAME | grep $FECHA | xargs -i cp {} $INPUTDIR
find . -name prstat-cpu.out |grep $SERVERNAME | grep $FECHA | xargs -i cp {} $INPUTDIR
}

scp_ficheros_prod()
{
if [[ ! -e $INPUTDIR/$SERVERNAME ]]; then
        mkdir $INPUTDIR/$SERVERNAME
fi
if [[ ! -e $INPUTDIR/$SERVERNAME/$FECHA ]]; then
        mkdir $INPUTDIR/$SERVERNAME/$FECHA
fi

VMSTATFILE=$INPUTDIR/$SERVERNAME/$FECHA/vmstat.out
PRSTATCPUFILE=$INPUTDIR/$SERVERNAME/$FECHA/prstat-cpu.out

echo $VMSTATFILE
echo $PRSTATCPUFILE
echo "trayendo ficheros de $SERVERNAME con fecha $FECHA"
scp -rp root@$SERVERNAME:/oracle_sun/guds/output/$FECHA*/*/vmstat.out $VMSTATFILE
scp -rp root@$SERVERNAME:/oracle_sun/guds/output/$FECHA*/*/prstat-cpu.out $PRSTATCPUFILE
#scp -rp root@$SERVERNAME:/oracle_sun/guds/output/$FECHA*/*/df.kl 
df-kl.out
}
##########################################################################o
###########################################################################

###########################################################################
#### FUNCIONES DE PLOT
###########################################################################
plot_vmstat_cpu ()
{
#### Realizo el plot
gnuplot -persist <<EOF
set title "Server $SERVERNAME - Fecha $FECHA"
set xlabel "Date / Time"
set ylabel "CPU % Busy"
set xdata time
set timefmt "%d/%m/%Y %H:%M:%S"
set format x "%H:%M"
set yrange [0:100]
set grid
## propiedades del fichero externo
set terminal png size 1024,352
set output 'vmstat_cpu.png'
set key reverse Left outside
plot "$TMPVMSTAT2" using 1:22 with lines title "CPU Usr%" lw 2, \
"$TMPVMSTAT2" using 1:23 with lines title "CPU Sys%" lw 3, \
"$TMPVMSTAT2" using 1:24 with lines title "CPU Idle%" lw 2
EOF
mv vmstat_cpu.png $OUTDIR/$SERVERNAME"_"$FECHA"_cpu.png"
}

#### Funcion que realiza el grafico de memoria via fichero vmstat
plot_vmstat_memory ()
{
#### Realizo el plot
gnuplot -persist <<EOF
set title "Server $SERVERNAME - Fecha $FECHA"
set xlabel "Date / Time"
set ylabel "Memory %"
set yrange [0:100]
set style data fsteps
set xdata time
set timefmt "%d/%m/%Y %H:%M:%S"
set format x "%H:%M"
set grid
## propiedades del fichero externo
set terminal png size 1024,352
set output 'vmstat_memory.png'
set key reverse Left outside
plot "$TMPVMSTAT2" using 1:6 with lines title "% Swap Used" lw 2, \
"$TMPVMSTAT2" using 1:7 with lines title "% Phy Used" lw 2
EOF
mv vmstat_memory.png $OUTDIR/$SERVERNAME"_"$FECHA"_memory.png"
}

#### Funcion que realiza el grafico de page in / out via fichero vmstat
plot_vmstat_pageinout ()
{
#### Realizo el plot
gnuplot -persist <<EOF
set title "Server $SERVERNAME - Fecha $FECHA"
set xlabel "Date / Time"
set ylabel "Page In / Out (KB)"
set xdata time
set timefmt "%d/%m/%Y %H:%M:%S"
set format x "%H:%M"
set grid
## propiedades del fichero externo
set terminal png size 1024,500
set output 'vmstat_pageinout.png'
set key reverse Left outside
set yrange [0:20000]
plot "$TMPVMSTAT2" using 1:10 with lines title "PageIn (Kb)" lw 2, \
"$TMPVMSTAT2" using 1:11 with lines title "PageOut(Kb)" lw 2, \
"$TMPVMSTAT2" using 1:14 with lines title "Scan Rate" lw 2
EOF
mv vmstat_pageinout.png "$OUTDIR/$SERVERNAME"_"$FECHA"_pageinout.png
}

#### Funcion que realiza el grafico de Run Queued / Blocked via fichero vmstat
plot_vmstat_queued ()
{
#### Realizo el plot
gnuplot -persist <<EOF
set title "Server $SERVERNAME - Fecha $FECHA"
set xlabel "Date / Time"
set ylabel "Queued, Blocked, Swapped runnable processes"
set xdata time
set timefmt "%d/%m/%Y %H:%M:%S"
set format x "%H:%M"
set grid
## propiedades del fichero externo
set terminal png size 1024,500
set output 'vmstat_queued.png'
set key reverse Left outside
set yrange [0:]
plot "$TMPVMSTAT2" using 1:3 with lines title "Run Queue" lw 2, \
"$TMPVMSTAT2" using 1:4 with lines title "Blocked" lw 2, \
"$TMPVMSTAT2" using 1:5 with lines title "Swapped" lw 2, \
"$TMPPRSTATCPU2" using 1:7 with lines title "15m Average Load" lw 2
EOF
mv vmstat_queued.png "$OUTDIR/$SERVERNAME"_"$FECHA"_vmstat_queued.png
}

#### Funcion que realiza el grafico de load average via fichero prstat-cpu.out
plot_prstat_cpu_load_average ()
{
#### Realizo el plot
gnuplot -persist <<EOF
set title "Server $SERVERNAME - Fecha $FECHA"
set xlabel "Date / Time"
set ylabel "Load Average CPU (1m, 5m, 15m)"
set xdata time
set timefmt "%d/%m/%Y %H:%M:%S"
set format x "%H:%M"
set grid
## propiedades del fichero externo
set terminal png size 1024,500
set output 'prstat_cpu_load_average.png'
set key reverse Left outside
set yrange [0:]
plot "$TMPPRSTATCPU2" using 1:5 with lines title "1m period" lw 1, \
"$TMPPRSTATCPU2" using 1:6 with lines title "5m period" lw 1, \
"$TMPPRSTATCPU2" using 1:7 with lines title "15m period" lw 1
EOF
mv prstat_cpu_load_average.png "$OUTDIR/$SERVERNAME"_"$FECHA"_prstat_cpu_load_average.png
}

###########################################################################
#### CONDICIONALES
###########################################################################

if [ $# != 1 ]
then
echo -e "\033[45m Author: Aledec \033[0m"
#echo -e "        _          _             "
#echo -e "   __ _| | ___  __| | ___  ___   "
#echo -e "  / _` | |/ _ \/ _` |/ _ \/ __|  "
#echo -e " | (_| | |  __/ (_| |  __/ (__   "
#echo -e "  \__-_|_|\___|\__-_|\___|\___|  "

echo -e "\n******************\033[44m Estadisticas del fichero vmstat.out \033[0m ******************"
echo -e "\033[1m 1. \033[33;33m CPU Usr% Sys% Busy% Diario / vmstat \033[0m"
echo -e "\033[1m 2. \033[33;32m Memory (KB) / vmstat \033[0m"
echo -e "\033[1m 3. \033[33;31m Page In / Out (KB) / vmstat \033[0m"
echo -e "\033[1m 4. \033[33;30m Queued, Blocked, Swapped runnable processes / sarq -vmstat \033[0m"
echo -e "\033[1m 8. \033[33;29m Limpiar Fichero VMSTAT (se agrega dia y hora(cada 30segundos) al fichero vmstat) - QA \033[0m"
echo -e "\033[1m 9. \033[33;28m Procesar sin limpiar Fichero VMSTAT (se agrega dia al fichero vmstat) - PRODUCCION \033[0m"

echo -e
echo -e "\n******************\033[44m Estadisticas del fichero sar-q.out \033[0m ******************"
echo -e "\033[1m 10. \033[33;33m Sumatoria I/O LUN presentadas en el servidor \033[0m"

echo -e
echo -e "\n******************\033[44m Estadisticas del fichero prstat \033[0m ******************"
echo -e "\033[1m 20. \033[33;33m Generar Load Average / prstat-cpu.out \033[0m"
echo -e "\033[1m 28. \033[33;32m Limpiar Fichero prstat-cpu.out (se agrega dia y hora(cada 15 minutos) al fichero prstat) - PRODUCCION \033[0m"

echo -e
echo -e "\n******************\033[44m Operaciones Especiales \033[0m ******************"
echo -e "\033[1m 96. \033[33;33m Recojo Ficheros - Genero todos los graficos de produccion \033[0m"
echo -e "\033[1m 97. \033[33;32m Recojo Ficheros - Genero todos los graficos de QA \033[0m"

echo -e "\033[1m 98. \033[33;31m Genero todos los graficos de produccion \033[0m"
echo -e "\033[1m 99. \033[33;30m Genero todos los graficos de QA \033[0m"

echo -e
echo -e "******************"
echo -e "\033[1m 0. \033[33;31m Salir \033[0m"
echo -e "******************"
echo -e
echo -e "\033[42m Ingrese el valor \033[0m"
read ch
  a=$ch
  else
  a=$1
fi

case $a in
0) exit 0;;
1) plot_vmstat_cpu;;
2) echo "TEMPORALMENTE DESHABILITADO";exit 2;plot_vmstat_memory;;
3) plot_vmstat_pageinout;;
4) plot_vmstat_queued;;
8) limpieza;limpiar_vmstat;agrego_fecha_vmstat;;
9) limpieza;limpiar_vmstat;agrego_dia_vmstat;;
10) echo "TEMPORALMENTE NO HABILITADA";exit 10;;
20) plot_prstat_cpu_load_average;;
28) limpieza;limpiar_prstat_cpu;agrego_fecha_prstat_cpu;;
95) buscar_ficheros_prod;;
96) rm -f $INPUTDIR/*.out;scp_ficheros_prod;generar_todos_los_graficos_produccion;;
97) buscar_ficheros_qa;generar_todos_los_graficos_qa;;
98) generar_todos_los_graficos_produccion;;
99) generar_todos_los_graficos_qa;;
*) echo -e "error de parametro";exit 1;;
esac
