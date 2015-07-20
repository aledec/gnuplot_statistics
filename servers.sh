#!/bin/bash 

configfile="$(pwd)/conf/gnuplot_statistics.conf"
configfile_secure="$(pwd)/conf/gnuplot_statistics.conf.secure"

###########################################################################
#### Condicionales de parametros ,directorios temporales, configuracion
###########################################################################
## Si el directorio temporal no existe lo creo
if [[ ! -e $OUTPUTPDFDIR ]]; then
        mkdir $OUTPUTPDFDIR
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
###########################################################################
###########################################################################

###########################################################################
#### Valores Requeridos para el correcto funcionamiento del script automatico
###########################################################################
echo -e "Ingrese el dia a procesar (formato YYYYMMD)"
echo -e "Ejemplo: 20131231, siendo 2013 el año, 12 el mes y 31 el dia"
read dn

echo -e "Ingrese el periodo de facturacion que corresponde (este valor se utilizara al generar el fichero pdf externo como encabezado de cada pagina)"
echo -e "Ejemplo: B4 de Diciembre del 2013 - Sabado"
echo -e "Ejemplo: 23 de Marzo 2013 - Martes"
read pe

DATE=$dn
PERIODOFACT=$pe
PDFTEXFILE=$LATEXDIR/$DATE.tex
###########################################################################
###########################################################################

###########################################################################
#### Condicionales de parametros ,directorios temporales, configuracion
###########################################################################
## Condicional para chequear si ya existe el fichero .tex de latex para luego generar el pdf
if [[ ! -e $PDFTEXFILE ]]; then
        touch $PDFTEXFILE
else
 rm -f $PDFTEXFILE
 touch $PDFTEXFILE
fi

## Agrego el encabezado para generar el fichero .tex de latex para luego generar el pdf
cat $LATEX_HEADER > $PDFTEXFILE
###########################################################################
###########################################################################

###########################################################################
#### Script
###########################################################################
echo -e "###########################################################################"
echo -e "###########################################################################"
echo -e "Generando graficos, espere por favor............"
## Loop para recorrer el listado de servidores
for i in $(cat $SERVERS); do
  ## agrego el nombre del servidor y la fecha actual al fichero .tex de latex para luego generar el pdf
  echo "\newline" >> $PDFTEXFILE
  echo "$PERIODOFACT" >> $PDFTEXFILE
  echo "\newline" >> $PDFTEXFILE
  echo "\newline" >> $PDFTEXFILE
  echo "Nombre Del Servidor: $i --- Fecha $DATE" >> $PDFTEXFILE
  echo -e " " >> $PDFTEXFILE

  ## ejecuto el script que genera los graficos, obteniendo los ficheros de los servidores
  echo "Esperando modificaciones especificas para el servidor $i en el fichero time-date.sh"
  read
  echo 96 | ./time-date.sh 96 $i $DATE > /dev/null 2>&1

  ## realizo un listado de los ficheros generados con el parametro de la fecha y nombre del servidor
  PNGFILES=$(ls $OUTDIR/$i*$DATE*)

  ## loop para agregar cada fichero al fichero .tex de latex para luego generar el pdf
  for o in $PNGFILES; do
    ## agrego el grafico, sin propiedades de dimension especifica(scale0.50 por ejemplo)
    #echo "\centering" >> $PDFTEXFILE
    echo "\includegraphics[scale=0.50]{$o}" >> $PDFTEXFILE
  done

  ## agrego una nueva pagina para separar por servido
  echo "\newpage" >> $PDFTEXFILE
  echo -e " " >> $PDFTEXFILE

done

## Envio final del documento al fichero .tex para generar el pdf
echo "\end{document}" >> $PDFTEXFILE


echo -e "###########################################################################"
echo -e "###########################################################################"
echo -e "Generando pdf.....espere por favor"
echo "R"| latex -output-directory=$OUTPUTPDFDIR $PDFTEXFILE > /dev/null 2>&1
echo -e "Se ha generado exitosamente el pdf"
echo -e "Fichero generado:"
ls -l $OUTPUTPDFDIR/$DATE.pdf
echo -e "Logs en el archivo:"
ls -l $OUTPUTPDFDIR/$DATE.log

