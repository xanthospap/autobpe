#! /bin/bash

################################################################################
## 
## |===========================================|
## |** Higher Geodesy Laboratory             **|
## |** Dionysos Satellite Observatory        **| 
## |** National Tecnical University of Athens**|
## |===========================================|
##
## filename              : wgetvmf1.sh
                           NAME=wgetvmf1
## version               : v-1.0
                           VERSION=v-1.0
                           RELEASE=beta
## created               : NOV-2014
## usage                 : wgetvmf1.sh
## exit code(s)          : 0 -> success
##                         1 -> error
## discription           : download VMF1 grid files
## uses                  : getopt, bpepy.gpstime, bpepy.products, python, read
## dependancies          : the python library bpepy.gpstime must be installed and
##                         set in the python path variable. the same holds for
##                         the python bpepy.products library.
## notes                 :
## TODO                  :
## detailed update list  :
                           LAST_UPDATE=NOV-2014
##
################################################################################

# //////////////////////////////////////////////////////////////////////////////
# DISPLAY VERSION
# //////////////////////////////////////////////////////////////////////////////
function dversion {
  echo "${NAME} ${VERSION} (${RELEASE}) ${LAST_UPDATE}"
  exit 0
}

# //////////////////////////////////////////////////////////////////////////////
# HELP FUNCTION
# //////////////////////////////////////////////////////////////////////////////
function help {
  echo "/******************************************************************************************/"
  echo " Program Name : ${NAME}.sh"
  echo " Version      : $VERSION"
  echo " Last Update  : $LAST_UPDATE"
  echo ""
  echo " Purpose : download VMF1 grid files"
  echo ""
  echo " Usage   : wgetvmf1"
  echo ""
  echo " Dependancies : the python libraries bpepy.gpstime and bpepy.products must"
  echo "                be installed and set in the python path variable."
  echo ""
  echo " Switches: -o --output-directory= specify the output directory; default is"
  echo "            the running directory"
  echo "           -y --year specify year (4-digit)"
  echo "           -d --doy specify day of year"
  echo "           -x --xml-output provide a summary file in xml format. The file will be named"
  echo "            as the downloaded file, using an extra .meta extension"
  echo "           -h --help display (this) help message and exit"
  echo "           -v --version dsiplay version and exit"
  echo ""
  echo " Note that the hourly files will be merged to a whole-day grid file. I.e if year"
  echo " is 2014 and doy is 331, the script will download 5 seperate hourly files "
  echo " VMFG_20141127.H00, VMFG_20141127.H06, VMFG_20141127.H12, VMFG_20141127.H18 and"
  echo " VMFG_20141128.H00) and merge them to the file VMFG_2014331."
  echo " If a final (observed) grid file is not found (in http://.../DELAY/GRID/VMFG)"
  echo " then the script will look for a prediction (forecast) file (in http://.../DELAY/GRID/VMFG_FC)"
  echo " and download it (if present). The type of the file is reported in stdout, .e.g."
  echo " (wgetvmf1) Downloaded VMF1 grid file VMFG_20141126.H18 (final) ; merged to VMFG_2014"
  echo " (wgetvmf1) Downloaded VMF1 grid file VMFG_20141127.H00 (prediction) ; merged to VMFG_2014"
  echo ""
  echo " Exit Status:255-1 -> error"
  echo " Exit Status:    0 -> sucess"
  echo ""
  echo " |===========================================|"
  echo " |** Higher Geodesy Laboratory             **|"
  echo " |** Dionysos Satellite Observatory        **|"
  echo " |** National Tecnical University of Athens**|"
  echo " |===========================================|"
  echo ""
  echo " WARNING !! The long options are only available if the GNU-enhanced version of getopt is"
  echo "            available; else, the user must only use short options"
  echo ""
  echo "/******************************************************************************************/"
  exit 0
}

# //////////////////////////////////////////////////////////////////////////////
# PRE-DEFINE BASIC VARIABLES
# //////////////////////////////////////////////////////////////////////////////
ODIR=                ## output directory
FDEL=False           ## force remove
YEAR=                ## year (4-digit)
DOY=                 ## doy
XML_SENTENCE="<command>$NAME " ## command run in xml format
XML_OUT=NO           ## provide xml output file

# //////////////////////////////////////////////////////////////////////////////
# GET COMMAND LINE ARGUMENTS
# //////////////////////////////////////////////////////////////////////////////
if [ "$#" == "0" ]; then help; fi

# Call getopt to validate the provided input. This depends on the getopt version available
getopt -T > /dev/null
if [ $? -eq 4 ]; then
  # GNU enhanced getopt is available
  ARGS=`getopt -o y:d:o:rhvx \
  -l year:,doy:,output-directory:,force-remove,help,version,xml-output \
  -n 'wgetvmf1.sh' -- "$@"`
else
  # Original getopt is available (no long option names, no whitespace, no sorting)
  ARGS=`getopt o:rhy:d:vx "$@"`
fi
# check for getopt error
if [ $? -ne 0 ] ; then echo "getopt error code : $status ;Terminating..." >&2 ; exit 254 ; fi
eval set -- $ARGS

# extract options and their arguments into variables.
while true ; do
  case "$1" in
    -y|--year)
      XML_SENTENCE="${XML_SENTENCE} <arg>${1} <replaceable>${2}</replaceable></arg>"
      YEAR="$2"; shift;;
    -d|--doy)
      XML_SENTENCE="${XML_SENTENCE} <arg>${1} <replaceable>${2}</replaceable></arg>"
      DOY=`echo "$2" | sed 's|^0*||g'`; shift;;
    -o|--output-directory)
      XML_SENTENCE="${XML_SENTENCE} <arg>${1} <replaceable>${2}</replaceable></arg>"
      ODIR="$2"; shift;;
    -r|--force-remove)
      XML_SENTENCE="${XML_SENTENCE} <arg>${1}</arg>"
      FDEL=True;;
    -x|--xml-output)
      XML_SENTENCE="${XML_SENTENCE} <arg>${1}</arg>"
      XML_OUT=YES;;
    -h|--help)
      help; exit 0;;
    -v|--version)
      dversion; exit 0;;
    --) # end of options
      shift; break;;
     *) 
      echo "*** Invalid argument $1 ; fatal" ; exit 254 ;;
  esac
  shift 
done
XML_SENTENCE="${XML_SENTENCE}</command>"

# //////////////////////////////////////////////////////////////////////////////
# CHECK THAT YEAR AND DOY IS SET AND VALID
# //////////////////////////////////////////////////////////////////////////////
if [ $YEAR -lt 1950 ]; then
  echo "*** Need to provide a valid year [>1950]"
  exit 254
fi
YR2=${YEAR:2:2}
if [ $DOY -lt 1 ] || [ $DOY -gt 366 ]; then
  echo "*** Need to provide a valid doy [1-366]"
  exit 254
fi

# //////////////////////////////////////////////////////////////////////////////
# IF OUTPUT DIR GIVEN, SEE THAT IT EXISTS
# //////////////////////////////////////////////////////////////////////////////
if [ ! -d $ODIR ]; then
  echo "*** Directory $ODIR does not exist!"
  exit 254
fi

# //////////////////////////////////////////////////////////////////////////////
# JUST CALL PYTHON
# //////////////////////////////////////////////////////////////////////////////
if [ -z "$ODIR" ]; then ODIR="./"; fi
PLIST=`python -c "import bpepy.gpstime
import bpepy.products.vmfgrid
import sys
rtn = bpepy.products.vmfgrid.getvmf1 ($YEAR,$DOY,'"$ODIR"','yes')
if rtn != 0: sys.exit (1)
print rtn
sys.exit (0)"; 2>/dev/null`

if [ $? -ne 0 ]; then
  echo "*** Error running bpepy.products.vmfgrid.getvmf1"
  echo $P_LIST
  exit 254
fi

# //////////////////////////////////////////////////////////////////////////////
# RESOLVE ANSWER
# //////////////////////////////////////////////////////////////////////////////
echo ${PLIST} | grep 'ERROR' 2>/dev/null
if [ $? -eq 0 ]; then
  echo "$PLIST"
  exit 254
fi

# archive all strings in an array
IFS=' ' read -a array <<< "$PLIST"

# last element must be zero
SZ=${#array[@]}
LPOS=$((SZ - 1))
STATUS=${array[${LPOS}]}
if [[ $SZ -ne 11 || $STATUS -ne 0 ]]; then
  echo "ERROR downloading the VMF1 grid files"
  for i in "${array[@]}"; do rm $i 2>/dev/null; done
  exit 254
fi

# merge files
DOY3=${DOY}
if [ $DOY -lt 10 ]; then
  DOY3=00${DOY}
else
  if [ $DOY -lt 100 ]; then
    DOY3=0${DOY}
  fi
fi
MERGED=${ODIR}/VMFG_${YEAR}${DOY3}
if [ "${ODIR}" == "./" ]; then MERGED=VMFG_${YEAR}${DOY3}; fi
MERGED=`echo "$MERGED" | sed 's|//|/|g'`
> $MERGED

if test "${XML_OUT}" == "YES"
then
  > ${MERGED}.meta
  echo -ne "<para>Vienna Mapping Function grid details: \
    Script run <command>$NAME</command> ${VERSION} (${RELEASE}) ${LAST_UPDATE} \
    Command run $XML_SENTENCE " >> ${MERGED}.meta
  echo -ne "Grid file created, named as <filename>${MERGED}</filename> \
    containing the following individual grid files: \
    <itemizedlist mark='bullet'>" >> ${MERGED}.meta
fi

for n in {0..9}; do
  out=$(( $n % 2 ))
  if [ $out -eq 0 ]; then
    cat "${array[${n}]}" >> $MERGED
    rm "${array[${n}]}"
  else
    np=$(( $n - 1 ))
    if test "${XML_OUT}" == "YES"
    then
      echo -ne "<listitem>grid file <filename>${array[${np}]}</filename></listitem>" >> ${MERGED}.meta
    else
      echo "(wgetvmf1) Downloaded VMF1 grid file ${array[${np}]} (${array[${n}]}) ; merged to $MERGED"
    fi
  fi
done

if test "${XML_OUT}" == "YES"
then
  echo -ne "</itemizedlist></para>" >> ${MERGED}.meta
fi
# //////////////////////////////////////////////////////////////////////////////
# EXIT
# //////////////////////////////////////////////////////////////////////////////
exit 0
