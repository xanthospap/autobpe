#! /bin/bash

################################################################################
## 
## |===========================================|
## |** Higher Geodesy Laboratory             **|
## |** Dionysos Satellite Observatory        **| 
## |** National Tecnical University of Athens**|
## |===========================================|
##
## filename              : wgetion.sh
                           NAME=wgetion
## version               : v-1.0
                           VERSION=v-1.0
                           RELEASE=beta
## created               : NOV-2014
## usage                 : wgetion.sh
## exit code(s)          : 0 -> success
##                         1 -> error
## discription           : download Bernese-format ION files
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
  echo " Program Name : $NAME"
  echo " Version      : $VERSION"
  echo " Last Update  : $LAST_UPDATE"
  echo ""
  echo " Purpose : download Bernese-formated ionospheric correction files (.ion)"
  echo ""
  echo " Usage   : wgetion"
  echo ""
  echo " Dependancies : the python libraries bpepy.gpstime and bpepy.products must"
  echo "                be installed and set in the python path variable."
  echo ""
  echo " Switches: -t --type= specify the product type; this can be:"
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
  echo "                      final -> CODWWWWD.ION.Z from CODWWWWD.ION.Z"
  echo "                      rapid -> CORWWWWD.ION.Z from CODWWWWD.ION_R"
  echo "                ultra-rapid -> COUWWWWD.ION.Z from COD.ION_U"
  echo "           -z --decompress decompress the downloaded file(s)"
  echo "           -y --year specify year (4-digit)"
  echo "           -d --doy specify day of year"
  echo "           -x --xml-output provide a summary file in xml format. The file will be named"
  echo "            as the downloaded file, using an extra .meta extension"
  echo "           -h --help display (this) help message and exit"
  echo "           -v --version dsiplay version and exit"
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
USE_STD_NAMES=False  ## use standard names
TYPE=x               ## product type
ODIR=                ## output directory
FDEL=False           ## force remove
DECOMPRESS=NO        ## decompress
YEAR=                ## year (4-digit)
DOY=                 ## doy
TRUNCATE=NO          ## rename to upper case
CHECK_FOR_UNC=NO     ## check for uncompressed files
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
  ARGS=`getopt -o y:d:t:o:rszhvx \
  -l year:,doy:,type:,output-directory:,force-remove,standard-names,decompress,help,version,xml-output \
  -n 'wgetion.sh' -- "$@"`
else
  # Original getopt is available (no long option names, no whitespace, no sorting)
  ARGS=`getopt t:o:rszhy:d:vx "$@"`
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
    -t|--type)
      XML_SENTENCE="${XML_SENTENCE} <arg>${1} <replaceable>${2}</replaceable></arg>"
      TYPE=`echo "$2" | tr 'A-Z' 'a-z'`; shift;;
    -o|--output-directory)
      XML_SENTENCE="${XML_SENTENCE} <arg>${1} <replaceable>${2}</replaceable></arg>"
      ODIR="$2"; shift;;
    -r|--force-remove)
      XML_SENTENCE="${XML_SENTENCE} <arg>${1}</arg>"
      FDEL=True;;
    -s|--standard-names)
      XML_SENTENCE="${XML_SENTENCE} <arg>${1}</arg>"
      USE_STD_NAMES=True;;
    -z|--decompress)
      XML_SENTENCE="${XML_SENTENCE} <arg>${1}</arg>"
      DECOMPRESS=YES;;
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
if [ "$DECOMPRESS" == "YES" ]; then CHECK_FOR_UNC=True; else CHECK_FOR_UNC=False; fi
if [ -z "$ODIR" ]; then ODIR="./"; fi

P_LIST=`python -c "import bpepy.gpstime
import bpepy.products.ion
import sys
rtn = bpepy.products.ion.getion ($YEAR,$DOY,'"$ODIR"',${USE_STD_NAMES},'"$TYPE"',$FDEL,$CHECK_FOR_UNC)
if rtn[0] != 0: sys.exit (1)
print rtn
sys.exit (0)" 2>/dev/null`

if [ $? -ne 0 ]; then
  echo "Error running bpepy.products.ion.getion function; failed to get ion"
  exit 254
fi

# //////////////////////////////////////////////////////////////////////////////
# RESOLVE THE ANSWER STRING (LIST)
# //////////////////////////////////////////////////////////////////////////////
PLIST=`echo "$P_LIST" | sed "s|'||g" | sed 's|,||g' | sed 's|\[||g' | sed 's|\]||g' | sed 's|(||g' | sed 's|)||g'`

#  first check the status (no need for this since we have checked python's returned
#+ status) but anyway ...
STATUS=`echo "$PLIST" | awk '{print $1}'` ## status
if [ $STATUS -ne 0 ]; then
  echo 'Error running bpepy.products.ion.getion function; failed to get ion'
  exit 254
fi

# archive all strings in an array
IFS=' ' read -a array <<< "$PLIST"
# 
if [ "${#array[@]}" -ne 4 ]; then
  echo "Error running bpepy.products.ion.getion function; Returned string: ${PLIST}"
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
# REPORT
# //////////////////////////////////////////////////////////////////////////////
AC=cod
if test "${XML_OUT}" == "YES"
then
  > ${DF}.meta
  echo -ne "<para>Ionospheric Corrections meta-information details: \
    Script run <command>$NAME</command> ${VERSION} (${RELEASE}) ${LAST_UPDATE} \
    Command run $XML_SENTENCE " >> ${DF}.meta
  echo -ne "Downloaded file <filename>$OF</filename>, stored localy as \
    <filename>${DF}</filename>, of type <emphasis>$TF</emphasis> \
    from ${AC} Analysis Center." >> ${DF}.meta
  echo -ne "<note>Format of this file is Bermese-specific (extension \
    .ion)</note></para>"  >> ${DF}.meta
else
  echo "(wgetion) Downloaded ION File: $OF as $DF  of type: $TF from AC: ${AC}"
fi

# //////////////////////////////////////////////////////////////////////////////
# EXIT
# //////////////////////////////////////////////////////////////////////////////
exit 0
