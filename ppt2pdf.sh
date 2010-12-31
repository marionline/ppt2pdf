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
#         NOTES: For bugs or other referer to:
#			https://github.com/marionline/ppt2pdf
#        AUTHOR: Mario Santagiuliana (MS), <mario at marionline.it>
#
#       CREATED: 19/12/2010 12:15:24 CET
#      REVISION: 31/12/2010 16:38:50 CET
#	LICENSE: GPL v3.0
#
#===============================================================================

# Set JODConverter PATH
JODConverter="/home/mario/jodconverter-2.2.2/lib/jodconverter-cli-2.2.2.jar"
# Set TEXTDOMAINDIR, where are located translations
TEXTDOMAINDIR=/home/mario/projects/ppt2pdf/locate


#===============================================================================
# Should not to be changed
#===============================================================================

FILE=false
RECURSIVELY=false
VERBOSITY=1
ASK=true
ALL_FILE_HERE=false
INCLUDE_DOC=false
ERASE=false

TEXTDOMAIN=ppt2pdf

export TEXTDOMAINDIR
export TEXTDOMAIN

. gettext.sh

USAGE=`gettext "
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

"`
usage(){
cat<<EOF
$USAGE
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
	DIM=`ls -lh $FILE | awk '{ print $5 }'`
	echo "`eval_gettext "Conversion of \\$FILE \\$DIM..."`"
    fi
    if [[ $VERBOSITY =~ [0-1] ]]; then
	jod &> /dev/null
    else
	jod
    fi
    if [[ $VERBOSITY =~ [1-2] ]]; then
	echo "`eval_gettext "Conversion finished."`"
	DIM=`ls -lh $FILE | awk '{ print $5 }'`
	echo "`eval_gettext "Original file \\$FILE is \\$DIM size"`"
	DEST_DIM=`ls -lh $DEST_FILE | awk '{ print $5 }'`
	echo "`eval_gettext "Converted file \\$DEST_FILE is \\$DEST_DIM size"`"
    fi
}

erase(){
    if [[ $ERASE == true ]]; then
	if [[ $VERBOSITY =~ [1-2] ]]; then
	    echo "`eval_gettext "Erasing \\$FILE..."`"
	fi
	rm $FILE
    fi
}
# If no parameter passed show usage options
if [ $# -eq 0 ]
then
    echo "`eval_gettext "No argument passed."`"
    usage
    exit 1
fi

# If not found JODConverter
if [ ! -r "$JODConverter" ]; then
  echo "`eval_gettext "ERROR: JODConverter not found."`" >&2
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
		echo "`eval_gettext "Invalid argument '\\$OPTARG' passed."`" >&2
            fi
            ;;
        : ) echo "`eval_gettext "No argument passed to '\\$OPTARG' option."`" >&2 
	    exit 1
	    ;;
        * ) echo "`eval_gettext "Invalid option '-\\$OPTARG'."`" >&2
	    exit 1
	    ;; # DEFAULT
    esac
done
shift $(($OPTIND - 1))

if [ -f $1 ]; then
    FILE=$1
else
    echo "`eval_gettext "\\$1 is not a file."`"
    exit 1
fi
PASSED_FILE=$FILE

if [[ $VERBOSITY = 2 ]]; then
    echo -e "`gettext "\nStarting OpenOffice as a deamon...\n"`"
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
		echo "`eval_gettext "Enter in subdirectory: \\$DIR"`"
	    fi
	    recursive
	    if [[ $VERBOSITY =~ [1-2] ]]; then
		echo "`eval_gettext "Exit from subdirectory: \\$DIR"`"
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
			echo "`eval_gettext "File \\$DEST_FILE exist: Size is \\$DEST_FILE_SIZE_HUMAN"`"
			echo "`eval_gettext "Original file \\$FILE: Size is \\$FILE_SIZE_HUMAN"`"
		    fi
		fi
		#echo "`eval_gettext "Would you like overwrite it?  [y/...]"`"
		#read -s -n1 answare
		#if [[ $answare = 'y' ]]; then
		#fi
	    else
		if [[ $ASK == true ]]; then
		    echo "`eval_gettext "Convert: \\$FILE in pdf? [y/...]"`"
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
		echo "`eval_gettext "Saved: \\$SCARTO \\$UNIT"`"
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
    echo "`eval_gettext "\\$1 is not a ppt or doc file."`"
fi

if [[ $RECURSIVELY == true || $ALL_FILE_HERE == true ]]; then
    recursive
fi

if [[ $VERBOSITY =~ [1-2] ]]; then
    echo
    if [[ $TOT_PPT_SIZE ]]; then
	TOT_PPT_SIZE=$(echo "scale=2; $TOT_PPT_SIZE/1048576" | bc)
	echo "`eval_gettext "Total ppt files size: \\$TOT_PPT_SIZE MB"`"
    fi
    if [[ $TOT_DOC_SIZE ]]; then
	TOT_DOC_SIZE=$(echo "scale=2; $TOT_DOC_SIZE/1048576" | bc)
	echo "`eval_gettext "Total doc files size: \\$TOT_DOC_SIZE MB"`"
    fi
    if [[ $TOT_DEST_FILE_SIZE ]]; then
	TOT_DEST_FILE_SIZE=$(echo "scale=2; $TOT_DEST_FILE_SIZE/1048576" | bc)
	echo "`eval_gettext "Total pdf files size: \\$TOT_DEST_FILE_SIZE MB"`"
    else
	echo "`eval_gettext "No file ppt or doc found or convert."`"
    fi
fi

if [[ $VERBOSITY == 2 ]]; then
    echo -e "`eval_gettext "\nKill OpenOffice deamon...\n"`"
fi
# kill OpenOffice deamon
kill $pidOO 2>/dev/null
exit 0
