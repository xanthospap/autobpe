#! /bin/bash

################################################################################
## 
## |===========================================|
## |** Higher Geodesy Laboratory             **|
## |** Dionysos Satellite Observatory        **| 
## |** National Tecnical University of Athens**|
## |===========================================|
##
## filename              : wgeterp.sh
                           NAME=wgeterp
## version               : v-1.0
                           VERSION=v-1.0
                           RELEASE=beta
## created               : NOV-2014
## usage                 : wgeterp.sh
## exit code(s)          : 0 -> success
##                         1 -> error
## discription           : download Earth Rotation Parameters (erp) files
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
  echo " Purpose : download Earth Rotation Parameters (erp) files"
  echo ""
  echo " Usage   : wgeterp"
  echo ""
  echo " Dependancies : the python libraries bpepy.gpstime and bpepy.products must"
  echo "                be installed and set in the python path variable."
  echo ""
  echo " Switches: -a --analysis-center= specify the analysis center; this can be"
  echo "              * igs, or"
  echo "              * cod (default)"
  echo "           -t --type= specify the product type; this can be:"
  echo "              * 'f' for final products,"
  echo "              * 'r' for rapid products,"
  echo "              * 'u' for ultra-rapid products."
  echo "            Note that if -t is not turned on (default), then the script will"
  echo "            search for whatever type is available (starting from final,"
  echo "            then rapid and then for ultra-rapid) and download the first file"
  echo "            that it finds."
  echo "           -o --output-directory= specify the output directory; default is"
  echo "            the running directory"
  echo "           -r --force-remove by default, if the file to be downloaded is "
  echo "            already available, then the script will not re-download it but"
  echo "            will report it as success. If -r is turned on, then the already"
  echo "            available file will be deleted and re-downloaded."
  echo "           -s --standard-names if this switch is turned on, then the downloaded"
  echo "            file will be renamed to the standard naming convention, i.e"
  echo "              * if AC = igs, then"
  echo "                      final -> igsWWWW7.erp.Z"
  echo "                      rapid -> igrWWWW7.erp.Z"
  echo "                ultra-rapid -> iguWWWW7.erp.Z"
  echo "              * if AC = cod, then"
  echo "                      final -> codWWWW7.erp.Z"
  echo "                      rapid -> codWWWW7.erp.Z"
  echo "                ultra-rapid -> codWWWW7.erp.Z"
  echo "           -z --decompress decompress the downloaded file(s)"
  echo "           -y --year specify year (4-digit)"
  echo "           -d --doy specify day of year"
  echo "           -u --upper-case rename downloaded file to upper case"
  echo "           -h --help display (this) help message and exit"
  echo "           -v --version dsiplay version and exit"
  echo ""
  echo " Exit Status:255-1 -> error"
  echo " Exit Status:    0 -> sucess"
  echo ""
  echo " !! Explicit Cases !!"
  echo "=================================================================================================================="
  echo "+-----------------------------------------------------------------------------+"
  echo "| type | file              | ac  | wgeterp -t <type> -a <ac> | -s (on)        |"
  echo "+------+-------------------+-----+---------------------------+----------------+"
  echo "| f    | igswwww7.erp.Z    | igs | igswwww7.erp.Z            | igswwwwd.erp.Z |"
  echo "+------+-------------------+-----+---------------------------+----------------+"
  echo "| r    | igrwwwwd.sp3.Z    | igs | igrwwwwd.erp.Z            | igrwwwwd.erp.Z |"
  echo "+------+-------------------+-----+---------------------------+----------------+"
  echo "| u    | igrwwwwd_HH.erp.Z | igs | iguwwwwd.erp.Z            | iguwwwwd.erp.Z |"
  echo "+------+-------------------+-----+---------------------------+----------------+"
  echo "| f    | CODWWWW7.ERP.Z    | cod | CODWWWW7.ERP.Z            | CODWWWWD.ERP.Z |"
  echo "+------+-------------------+-----+---------------------------+----------------+"
  echo "| r    | CODWWWWD.ERP_R    | cod | CODWWWWD.ERP_R            | CORWWWWD.ERP.Z |"
  echo "+------+-------------------+-----+---------------------------+----------------+"
  echo "| u    | COD.ERP_U         | cod | COD.ERP_U                 | COUWWWWD.ERP.Z |"
  echo "+------+-------------------+-----+---------------------------+----------------+"
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
USE_STD_NAMES=False  ## use standard names
AC=cod               ## analysis center
TYPE=x               ## product type
ODIR=                ## output directory
FDEL=False           ## force remove
DECOMPRESS=NO        ## decompress
YEAR=                ## year (4-digit)
DOY=                 ## doy
TRUNCATE=NO          ## rename to upper case
CHECK_FOR_UNC=NO     ## check for uncompressed files
XML_SENTENCE="<command>$NAME " ## command run in xml format

# //////////////////////////////////////////////////////////////////////////////
# GET COMMAND LINE ARGUMENTS
# //////////////////////////////////////////////////////////////////////////////
if [ "$#" == "0" ]; then help; fi
# Call getopt to validate the provided input. This depends on the getopt version available
getopt -T > /dev/null
if [ $? -eq 4 ]; then
  # GNU enhanced getopt is available
  ARGS=`getopt -o y:d:a:t:o:rszhuv \
  -l year:,doy:,analysis-center:,type:,output-directory:,force-remove,standard-names,decompress,help,upper-case,version \
  -n 'wgetorbit.sh' -- "$@"`
else
  # Original getopt is available (no long option names, no whitespace, no sorting)
  ARGS=`getopt a:t:o:rszhy:d:uv "$@"`
fi
# check for getopt error
if [ $? -ne 0 ] ; then echo "getopt error code : $status ;Terminating..." >&2 ; exit 254 ; fi
eval set -- $ARGS

# extract options and their arguments into variables.
while true ; do
  case "$1" in
    -y|--year)
      
      YEAR="$2"; shift;;
    -d|--doy)

      DOY=`echo "$2" | sed 's|^0*||g'`; shift;;
    -a|--analysis-center)

      AC=`echo "$2" | tr 'A-Z' 'a-z'`; shift;;
    -t|--type)

      TYPE=`echo "$2" | tr 'A-Z' 'a-z'`; shift;;
    -o|--output-directory)

      ODIR="$2"; shift;;
    -r|--force-remove)

      FDEL=True;;
    -s|--standard-names)

      USE_STD_NAMES=True;;

    -z|--decompress)
      DECOMPRESS=YES;;
    -u|--upper-case)
      TRUNCATE=YES;;
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

# //////////////////////////////////////////////////////////////////////////////
# CHECK THAT YEAR AND DOY IS SET AND VALID
# //////////////////////////////////////////////////////////////////////////////
if [ $YEAR -lt 1950 ]
then
  echo "*** Need to provide a valid year [>1950]"
  exit 254
fi
YR2=${YEAR:2:2}
if [ $DOY -lt 1 ] || [ $DOY -gt 366 ]
then
  echo "*** Need to provide a valid doy [1-366]"
  exit 254
fi

# //////////////////////////////////////////////////////////////////////////////
# IF OUTPUT DIR GIVEN, SEE THAT IT EXISTS
# //////////////////////////////////////////////////////////////////////////////
if [ ! -d $ODIR ]
then
  echo "*** Directory $ODIR does not exist!"
  exit 254
fi

# //////////////////////////////////////////////////////////////////////////////
# JUST CALL PYTHON
# //////////////////////////////////////////////////////////////////////////////
if [ "$DECOMPRESS" == "YES" ]; then CHECK_FOR_UNC=True; else CHECK_FOR_UNC=False; fi
if [ -z "$ODIR" ]; then ODIR="./"; fi

P_LIST=`python -c "import bpepy.gpstime
import bpepy.products.erps
import sys
rtn = bpepy.products.erps.geterp ($YEAR,$DOY,'"$AC"','"$ODIR"',${USE_STD_NAMES},'"$TYPE"',$FDEL,$CHECK_FOR_UNC)
if rtn[0] != 0:
  sys.exit (1)
print rtn
sys.exit (0)" 2>/dev/null`

if test $? -ne 0
then
  echo "***ERROR! Failed to run script bpepy.products.erps.geterp()"
  echo "Answer: $P_LIST"
  exit 254
fi

# //////////////////////////////////////////////////////////////////////////////
# RESOLVE THE ANSWER STRING (LIST)
# //////////////////////////////////////////////////////////////////////////////
## TODO Re-write this a bit better !!
PLIST=`echo "$P_LIST" | sed "s|'||g" | sed 's|,||g' | sed 's|\[||g' | sed 's|\]||g' | sed 's|(||g' | sed 's|)||g'`
# echo $PLIST
# first check the status
STATUS=`echo "$PLIST" | awk '{print $1}'` ## status
if [ $STATUS -ne 0 ]; then
  echo 'Error running bpepy.products.erps.geterp function; failed to get erp'
  exit 254
fi
# archive all strings in an array
IFS=' ' read -a array <<< "$PLIST"
# 
if [ "${#array[@]}" -ne 4 ]; then
  echo "Error running bpepy.products.erps.geterp function; Returned string: ${PLIST}"
else
  OF=${array[1]} ## original file
  DF=${array[2]} ## downloaded file
  TF=${array[3]} ## type file
fi

# //////////////////////////////////////////////////////////////////////////////
# IF FILE IS UNCOMPRESS THEN COMPRESS IT
# //////////////////////////////////////////////////////////////////////////////
if [[ $DF =~ .Z$ ]]; then 
  DF=${DF}
else 
  compress ${DF}
  DF=${DF}.Z
fi

# //////////////////////////////////////////////////////////////////////////////
# UNCOMPRESS
# //////////////////////////////////////////////////////////////////////////////
if [ "$DECOMPRESS" == "YES" ]; then
  if [[ $DF =~ .Z$ ]]; then uncompress -f $DF ;fi #2>/dev/null
  #if [ "$?" -ne 0 ]; then echo "Error! failed to decompress $DF1"; exit -1; fi
  DF=`echo "$DF" | sed 's|.Z$||g'`
fi

# //////////////////////////////////////////////////////////////////////////////
# RENAME TO UPPER-CASE
# //////////////////////////////////////////////////////////////////////////////
if [ "$TRUNCATE" == "YES" ]; then
  mv $DF ${DF^^}
  DF=${DF^^}
fi

# //////////////////////////////////////////////////////////////////////////////
# REPORT
# //////////////////////////////////////////////////////////////////////////////
echo "(wgeterp) Downloaded ERP File: $OF as $DF  of type: $TF from AC: ${AC}"

# //////////////////////////////////////////////////////////////////////////////
# EXIT
# //////////////////////////////////////////////////////////////////////////////
exit 0
