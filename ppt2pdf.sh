#!/bin/bash - 
#===============================================================================
#
#          FILE:  ppt2pdf.sh
# 
#         USAGE:  ./ppt2pdf.sh 
# 
#   DESCRIPTION:  
# 
#       OPTIONS:  ---
#  REQUIREMENTS:  JODConverter, OpenOffice
#          BUGS:  ---
#         NOTES:  ---
#        AUTHOR: Mario Santagiuliana (MS), <mario at marionline.it>
#       COMPANY: 
#       CREATED: 19/12/2010 12:15:24 CET
#      REVISION:  ---
#	LICENSE: LGPL
#===============================================================================

set -o nounset                              # Treat unset variables as an error

# .colori is my shell script with color code for bash
. colori

echo -e "\n-----------------------------------------------------------------"
echo -e "|   Avvio openoffice in modalità backgroud                      |"
echo -e "|$RED soffice -headless -accept="socket,host=127.0.0.1,port=8100;urp;" -nofirststartwizard $Z          |"
echo -e "-----------------------------------------------------------------\n"
# start OpenOffice as a service on listen port 8100
soffice -headless -accept="socket,host=127.0.0.1,port=8100;urp;" -nofirststartwizard &
# save pid of started process
pidOO=$!
# Chiedo se convertire tutti i file ora o se passarli uno ad uno
echo -n -e "$GREEN Convertire tutti i file ppt della directory corrente?$Z [s/...]\n"
read d
for file in *
do
     if echo "$file" | grep -q ".ppt" ; then
       if [[ $d != 's' ]]; then
         echo -e "Convertire:$RED $file$Z in pdf? [s/...]"
         read -s -n1 n
       else
         n='s'
       fi
       if [[ $n = 's' ]] ; then
          filePDF=${file/%.ppt/.pdf}
	  if [ -f $filePDF ] ; then
	    echo -e "   File $RED $filePDF $Z è già convertito: Size is $BLUE$(ls -lh $filePDF | awk '{ print $5 }')$Z"
	    echo -e "   File $RED $file $Z di origine Size is $BLUE$(ls -lh $file | awk '{ print $5 }')$Z"
	    # recupero le dimensioni dei file in modo da stampare sullo schermo le info sul loro peso.
	    DimFile0=$(ls -l $file | awk '{ print $5 }')
	    DimFile1=$(ls -l $filePDF | awk '{ print $5 }')
	    let diff="$DimFile0 - $DimFile1"
	    if (($diff >= 1048576)); then
	       scarto=$(echo "scale=2; $diff/1048576" | bc)
	       unita="MByte"
	    else
	       scarto=$(echo "scale=2; $diff/1024" | bc)
	       unita="KByte"
	    fi
	    echo -e "   Risparmio di: $BLUE$scarto $unita $Z"
	    echo
	  else
	    echo -e "$GRAY Inizio conversione di $file $(ls -lh $file | awk '{ print $5 }')"
	    # Con questo comando indico a JODConverter di convertire i file
	    # sto utilizzando la versione 2.2.1, il software è stato scaricato e scompattato nella home directory
	    # dell'utente
	    # modificare la path a jodconverter nel caso si utilizzi una versioni differente o posizione diversa del programma
            java -jar ~/jodconverter-2.2.1/lib/jodconverter-cli-2.2.1.jar $file $filePDF
	    echo -e "conversione finita:$Z"
	    echo -e "   File originario$RED $file$Z di Size is $BLUE$(ls -lh $file | awk '{ print $5 }')$Z"
	    echo -e "   Convertito in$RED $filePDF$Z di Size is $BLUE$(ls -lh $filePDF | awk '{ print $5 }')$Z"
	    DimFile0=$(ls -l $file | awk '{ print $5 }')
	    DimFile1=$(ls -l $filePDF | awk '{ print $5 }')
	    let diff="$DimFile0 - $DimFile1"
	    if (($diff >= 1048576)); then
	       scarto=$(echo "scale=2; $diff/1048576" | bc)
	       unita="MByte"
	    else
	       scarto=$(echo "scale=2; $diff/1024" | bc)
	       unita="KByte"
	    fi
	    echo -e "   Risparmio di: $BLUE$scarto $unita $Z"
	    echo
          fi
	  let dimtotPDF="$dimtotPDF + $DimFile1"
	  let dimtotppt="$dimtotppt + $DimFile0"
       fi
     fi
done
# Informazioni su peso iniziale e finale di tutti i file convertiti
dimtotppt=$(echo "scale=2; $dimtotppt/1048576" | bc)
echo -e "Dimensione totale dei file ppt:$RED $dimtotppt$Z MB"
dimtotPDF=$(echo "scale=2; $dimtotPDF/1048576" | bc)
echo -e "Dimensione totale dei file pdf:$RED $dimtotPDF$Z MB"
# Uccido il demone OpenOffice
kill $pidOO
exit
