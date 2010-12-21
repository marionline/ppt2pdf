#!/bin/bash - 
#===============================================================================
#
#          FILE:  ppt2pdf.sh
# 
#         USAGE:  ./ppt2pdf.sh [options] [filename]
# 
#   DESCRIPTION: convert ppt file to pdf 
# 
#       OPTIONS: -r -a -y -v -d -h
#  REQUIREMENTS:  JODConverter, OpenOffice.org
#          BUGS:  ---
#         NOTES:  ---
#        AUTHOR: Mario Santagiuliana (MS), <mario at marionline.it>
#       COMPANY: 
#       CREATED: 19/12/2010 12:15:24 CET
#      REVISION: 21/12/2010 01:34:50 CET
#	LICENSE: GPL v3.0
#===============================================================================

# Set JODConverter PATH
JODConverter="/home/mario/jodconverter-2.2.2/lib/jodconverter-cli-2.2.2.jar"

FILE=false
RECURSIVELY=false
VERBOSITY=1
ASK=true
ALL_FILE_HERE=false
INCLUDE_DOC=false
ERASE=false

usage(){
cat<<EOF

Usage: ppt2pdf.sh [options] [filename]
    options: -r: Recursive,
    	     -a: All file in this directory,
    	     -y: Answare YES to all question,
	     -v: Verbose (if not use default is 1),
	     -d: Include doc file,
	     -e: Erase original file,
	     -h: Usage.
    verbose: 0 no output,
	     1 a little bit of info,
	     2 a lot of info.

EOF
}

file_size_diff(){
    FILE_SIZE=$(ls -l $FILE | awk '{ print $5 }')
    DEST_FILE_SIZE=$(ls -l $DEST_FILE | awk '{ print $5 }')

    FILE_SIZE_HUMAN=$(ls -lh $FILE | awk '{ print $5 }')
    DEST_FILE_SIZE_HUMAN=$(ls -lh $DEST_FILE | awk '{ print $5 }')

    let DIFF="$FILE_SIZE - $DEST_FILE_SIZE"
    if (($DIFF >= 1048576)); then
	SCARTO=$(echo "scale=2; $DIFF/1048576" | bc)
	UNIT="MByte"
    else
	SCARTO=$(echo "scale=2; $DIFF/1024" | bc)
	UNIT="KByte"
    fi
}

jod(){
    java -jar $JODConverter $FILE $DEST_FILE
}

JOD_convert(){
    if [[ $VERBOSITY =~ [1-2] ]]; then
	echo $"Conversion of $FILE $(ls -lh $FILE | awk '{ print $5 }')..."
    fi
    if [[ $VERBOSITY =~ [0-1] ]]; then
	jod &> /dev/null
    else
	jod
    fi
    if [[ $VERBOSITY =~ [1-2] ]]; then
	echo $"Conversion finished."
	echo $"Original file $FILE is $(ls -lh $FILE | awk '{ print $5 }') size"
	echo $"Converted file $DEST_FILE is $(ls -lh $DEST_FILE | awk '{ print $5 }') size"
    fi
}

erase(){
    if [[ $ERASE == true ]]; then
	if [[ $VERBOSITY =~ [1-2] ]]; then
	    echo $"Erasing $FILE..."
	fi
	rm $FILE
    fi
}
# If no parameter passed show usage options
if [ $# -eq 0 ]
then
    echo $"No argument passed."
    usage
    exit 1
fi

# If not found JODConverter
if [ ! -r "$JODConverter" ]; then
  echo $"ERROR: JODConverter not found." >&2
  exit 1
fi

while getopts ":hryadev:" Options
do
    case $Options in 
        h ) usage
	    exit 0
	    ;;
        r ) RECURSIVELY=true;;
	y ) ASK=false;;
	a ) ALL_FILE_HERE=true;;
	d ) INCLUDE_DOC=true;;
	e ) ERASE=true;;
        v ) if [[ $OPTARG =~ [0-2] ]]
	    then
		VERBOSITY=$OPTARG
            else
		echo $"Invalid argument '$OPTARG' passed." >&2
            fi
            ;;
        : ) echo $"No argument passed to '$OPTARG' option." >&2 
	    exit 1
	    ;;
        * ) echo $"Invalid option '-$OPTARG'." >&2
	    exit 1
	    ;; # DEFAULT
    esac
done
shift $(($OPTIND - 1))

if [ -f $1 ]; then
    FILE=$1
else
    echo $"$1 is not a file."
    exit 1
fi
PASSED_FILE=$FILE

if [[ $VERBOSITY = 2 ]]; then
    echo -e $"\nStarting OpenOffice as a deamon...\n"
fi
# start OpenOffice as a service on listen port 8100
soffice -headless -accept="socket,host=127.0.0.1,port=8100;urp;" -nofirststartwizard &
# save pid of started process
pidOO=$!
# need a sleep to ensure that soffice complete the starting process
sleep 2

recursive(){
    for FILE in *
    do
	if [[ -d "$FILE" && $RECURSIVELY == true ]]; then
	    local DIR=$FILE
	    cd $DIR
	    if [[ $VERBOSITY =~ [1-2] ]]; then
		echo $"Enter in subdirectory: $DIR"
	    fi
	    recursive
	    if [[ $VERBOSITY =~ [1-2] ]]; then
		echo $"Exit from subdirectory: $DIR"
	    fi
	    cd ..
	else
	    if [[ $INCLUDE_DOC == true ]]; then
		if [[  ${FILE: -4} =~ .(ppt|doc) ]]; then
		    GO=true
		else
		    GO=false
		fi
	    elif [[ ${FILE: -4} == ".ppt" ]]; then
		GO=true
	    else
		GO=false
	    fi 
	fi
	# Only if are correct extension go ahead
	if [[ $GO == true ]]; then
	    DEST_FILE=${FILE%.*}.pdf
	    if [[ -f $DEST_FILE ]] ; then
		file_size_diff
		if [[ $VERBOSITY =~ [1-2] ]]; then
		    if [[ $FILE != $PASSED_FILE ]]; then
			echo $"File $DEST_FILE exist: Size is $DEST_FILE_SIZE_HUMAN"
			echo $"Original file $FILE: Size is $FILE_SIZE_HUMAN"
		    fi
		fi
		#echo $"Would you like overwrite it? [y/...]"
		#read -s -n1 answare
		#if [[ $answare = 'y' ]]; then
		#fi
	    else
		if [[ $ASK == true ]]; then
		    echo $"Convert: $FILE in pdf? [y/...]"
		    read -s -n1 answare
		    if [[ $answare == 'y' ]]; then
			CONTINUE=true
		    else
			CONTINUE=false
		    fi
		else
		    CONTINUE=true
		fi
		if [[ $CONTINUE == true ]] ; then
		    JOD_convert
		    file_size_diff
		    erase
		fi
	    fi
	    if [[ $VERBOSITY =~ [1-2] ]]; then
		echo $"Saved: $SCARTO $UNIT"
	    fi
	    let TOT_DEST_FILE_SIZE="$TOT_DEST_FILE_SIZE + $DEST_FILE_SIZE"

	    if [[ ${FILE: -4} == ".doc" ]]; then
		let TOT_DOC_SIZE="$TOT_DOC_SIZE + $FILE_SIZE"
	    else
		let TOT_PPT_SIZE="$TOT_PPT_SIZE + $FILE_SIZE"
	    fi

	    # Reset access
	    GO=false
	fi
    done
}

if [[  ${FILE: -4} =~ .(ppt|doc) ]]; then
    DEST_FILE=${FILE%.*}.pdf
    JOD_convert
    erase
elif [[ ! -z $FILE ]]; then
    echo $"$1 is not a ppt or doc file."
fi

if [[ $RECURSIVELY == true || $ALL_FILE_HERE == true ]]; then
    recursive
fi

if [[ $VERBOSITY =~ [1-2] ]]; then
    echo
    if [[ $TOT_PPT_SIZE ]]; then
	TOT_PPT_SIZE=$(echo "scale=2; $TOT_PPT_SIZE/1048576" | bc)
	echo $"Total ppt files size: $TOT_PPT_SIZE MB"
    fi
    if [[ $TOT_DOC_SIZE ]]; then
	TOT_DOC_SIZE=$(echo "scale=2; $TOT_DOC_SIZE/1048576" | bc)
	echo $"Total doc files size: $TOT_DOC_SIZE MB"
    fi
    if [[ $TOT_DEST_FILE_SIZE ]]; then
	TOT_DEST_FILE_SIZE=$(echo "scale=2; $TOT_DEST_FILE_SIZE/1048576" | bc)
	echo $"Total pdf files size: $TOT_DEST_FILE_SIZE MB"
    else
	echo $"No file ppt or doc found or convert."
    fi
fi

if [[ $VERBOSITY == 2 ]]; then
    echo -e $"\nKill OpenOffice deamon...\n"
fi
# kill OpenOffice deamon
kill $pidOO 2>/dev/null
exit 0
