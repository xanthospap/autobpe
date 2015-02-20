#! /bin/bash

################################################################################
## 
## |===========================================|
## |** Higher Geodesy Laboratory             **|
## |** Dionysos Satellite Observatory        **| 
## |** National Tecnical University of Athens**|
## |===========================================|
##
## filename              : wgetorbit.sh
                           NAME=wgetorbit
## version               : v-1.0
                           VERSION=v-1.0
                           RELEASE=beta
## created               : NOV-2014
## usage                 : wgetorbit.sh
## exit code(s)          : 0 -> success
##                         1 -> error
## discription           : download GNSS (actually gps and/or glonass) orbit files
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
  echo " Program Name : wgetorbit.sh"
  echo " Version      : $VERSION"
  echo " Last Update  : $LAST_UPDATE"
  echo ""
  echo " Purpose : download GNSS (actually gps and/or glonass) orbit files"
  echo ""
  echo " Usage   : wgetorbit.sh"
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
  echo "            Note also, that GLONASS orbit files are not available as 'rapid'."
  echo "            In case two files must be downloaded (for gps and glonass), then"
  echo "            the two files will be merged to one mixed orbit file, named as"
  echo "            the original gps sp3. E.g. running wgetorbit.sh -a igs -t f [...]"
  echo "            the resulting file will be igsWWWWD.sp3.Z which will contain the"
  echo "            respective iglWWWWD.sp3 file"
  echo "           -o --output-directory= specify the output directory; default is"
  echo "            the running directory"
  echo "           -r --force-remove by default, if the file to be downloaded is "
  echo "            already available, then the script will not re-download it but"
  echo "            will report it as success. If -r is turned on, then the already"
  echo "            available file will be deleted and re-downloaded."
  echo "           -s --standard-names if this switch is turned on, then the downloaded"
  echo "            file will be renamed to the standard naming convention, i.e"
  echo "              * if AC = igs, then"
  echo "                      final -> igsWWWWD.sp3.Z"
  echo "                      rapid -> igrWWWWD.sp3.Z"
  echo "                ultra-rapid -> iguWWWWD.sp3.Z"
  echo "              * if AC = cod, then"
  echo "                      final -> codWWWWD.sp3.Z"
  echo "                      rapid -> codWWWWD.sp3.Z"
  echo "                ultra-rapid -> codWWWWD.sp3.Z"
  echo "           -n --no-glonass (for ac = igs) by default the routine will download"
  echo "            both the gps and the glonass sp3 files; if this switch is turned on,"
  echo "            then no glonass file will be downloaded"
  echo "           -z --decompress decompress the downloaded file(s)"
  echo "           -y --year specify year (4-digit)"
  echo "           -d --doy specify day of year"
  echo "           -u --upper-case rename downloaded file to upper case"
  echo "           -x --xml-output provide a summary file in xml format. The file will be named"
  echo "            as the downloaded file, using an extra .meta extension"
  echo "           -h --help display (this) help message and exit"
  echo "           -v --version dsiplay version and exit"
  echo ""
  echo " Exit Status:255-1 -> error"
  echo " Exit Status:    0 -> sucess"
  echo ""
  echo " !! Explicit Cases !!"
  echo "=================================================================================================================="
  echo "+--------------------------------------------+--------------------------------------------------+----------------+"
  echo "|GNSS       | type | file              | ac  | wgetorbit -t type -a igs [-n]                    | -s (on)        |"
  echo "+-----------+------+-------------------+-----+--------------------------------------------------+----------------+"
  echo "|gps        | f    | igswwwwd.sp3.Z    | igs | igswwwwd.sp3.Z                                   | igswwwwd.sp3.Z |"
  echo "+-----------+------+-------------------+-----+--------------------------------------------------+----------------+"
  echo "|glonass    | f    | iglwwwwd.sp3.Z    | igs | NO OPTION                                        | -              |"
  echo "+-----------+------+-------------------+-----+--------------------------------------------------+----------------+"
  echo "|gps+glonass| f    | NOT AVAILABLE     | igs | igswwwwd.sp3.Z + iglwwwwd.sp3.Z \                | igswwwwd.sp3.Z |"
  echo "|           |      | BY IGS            |     |  > igswwwwd.sp3.Z                                |                |"
  echo "+-----------+------+-------------------+-----+--------------------------------------------------+----------------+"
  echo "|gps        | r    | igrwwwwd.sp3.Z    | igs | igrwwwwd.sp3.Z                                   | igrwwwwd.sp3.Z |"
  echo "+-----------+------+-------------------+-----+--------------------------------------------------+----------------+"
  echo "|glonass    | r    | NOT AVAILABLE     | igs | NO OPTION                                        | -              |"
  echo "+-----------+------+-------------------+-----+--------------------------------------------------+----------------+"
  echo "|gps+glonass| r    | NOT AVAILABLE     | igs | -                                                | ERROR (-1)     |"
  echo "+-----------+------+-------------------+-----+--------------------------------------------------+----------------+"
  echo "|gps        | u    | iguwwwwd_HH.sp3.Z | igs | iguwwwwd_HH.sp3.Z                                | iguwwwwd.sp3.Z |"
  echo "+-----------+------+-------------------+-----+--------------------------------------------------+----------------+"
  echo "|glonass    | u    | NOT AVAILABLE     | igs | NO OPTION                                        | -              |"
  echo "+-----------+------+-------------------+-----+--------------------------------------------------+----------------+"
  echo "|gps+glonass| u    | igvwwwwd_HH.sp3.Z | igs | igvwwwwd_HH.sp3.Z                                | igvwwwwd.sp3.Z |"
  echo "+-----------+------+-------------------+-----+--------------------------------------------------+----------------+"
  echo "|gps+glonass| f    | CODwwwwd.EPH.Z    | cod | CODwwwwd.EPH.Z                                   | codwwwwd.sp3.Z |"
  echo "+-----------+------+-------------------+-----+--------------------------------------------------+----------------+"
  echo "|gps+glonass| r    | CODwwwwd.EPH_R    | cod | CODwwwwd.EPH_R                                   | corwwwwd.sp3   |"
  echo "+-----------+------+-------------------+-----+--------------------------------------------------+----------------+"
  echo "|gps+glonass| u    | COD.EPH_U         | cod | COD.EPH_U                                        | couwwwwd.sp3   |"
  echo "+-----------+------+-------------------+-----+--------------------------------------------------+----------------+"
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
USE_GLONASS=True     ## download glonass sp3
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
XML_OUT=NO           ## provide xml output file

# //////////////////////////////////////////////////////////////////////////////
# GET COMMAND LINE ARGUMENTS
# //////////////////////////////////////////////////////////////////////////////
if [ "$#" == "0" ]; then help; fi
# Call getopt to validate the provided input. This depends on the getopt version available
getopt -T > /dev/null
if [ $? -eq 4 ]; then
  # GNU enhanced getopt is available
  ARGS=`getopt -o y:d:a:t:o:rsnzhuvx \
  -l year:,doy:,analysis-center:,type:,output-directory:,force-remove,standard-names,no-glonass,decompress,help,upper-case,version,xml-output \
  -n 'wgetorbit.sh' -- "$@"`
else
  # Original getopt is available (no long option names, no whitespace, no sorting)
  ARGS=`getopt a:t:o:rsnzhy:d:uvx "$@"`
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
    -a|--analysis-center)
      XML_SENTENCE="${XML_SENTENCE} <arg>${1} <replaceable>${2}</replaceable></arg>"
      AC=`echo "$2" | tr 'A-Z' 'a-z'`; shift;;
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
    -n|--no-glonass)
      XML_SENTENCE="${XML_SENTENCE} <arg>${1}</arg>"
      USE_GLONASS=False;;
    -z|--decompress)
      XML_SENTENCE="${XML_SENTENCE} <arg>${1}</arg>"
      DECOMPRESS=YES;;
    -u|--upper-case)
      XML_SENTENCE="${XML_SENTENCE} <arg>${1}</arg>"
      TRUNCATE=YES;;
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
# SOME CASES ARE UNRESOLVED
# //////////////////////////////////////////////////////////////////////////////
if [ "$AC" == "igs" ]; then
  if [[ "$TYPE" == "r" && "$USE_GLONASS" == "True" ]]; then
    echo "No availabe file for combination: $AC + $TYPE + (GPS & GLONASS)"
    exit 254
  fi
fi

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
if [ "$USE_GLONASS" == "False" ]; then SKIP_GLONASS=True; else SKIP_GLONASS=False; fi
if [ -z "$ODIR" ]; then ODIR="./"; fi

P_LIST=`python -c "import bpepy.gpstime
import bpepy.products.orbits
import sys
rtn = bpepy.products.orbits.getorb ($YEAR,$DOY,'"$AC"','"$ODIR"',${USE_STD_NAMES},${SKIP_GLONASS},'"$TYPE"',$FDEL,$CHECK_FOR_UNC)
if rtn[0] != 0: sys.exit(1)
print rtn
sys.exit(0)"` ##2>/dev/null`

if [ $? -ne 0 ]; then
  echo "*** Failed to run python script bpepy.products.orbits.getorb"
  echo "*** Additional python output : ${P_LIST}"
  echo "*** python: bpepy.products.orbits.getorb ($YEAR,$DOY,'"$AC"','"$ODIR"',${USE_STD_NAMES},${SKIP_GLONASS},'"$TYPE"',$FDEL,$CHECK_FOR_UNC)"
  exit 254
fi

# //////////////////////////////////////////////////////////////////////////////
# RESOLVE THE ANSWER STRING (LIST)
# //////////////////////////////////////////////////////////////////////////////
PLIST=`echo "$P_LIST" | sed "s|'||g" | sed 's|,||g' | sed 's|\[||g' | sed 's|\]||g' | sed 's|(||g' | sed 's|)||g'`
# first check the status
STATUS=`echo "$PLIST" | awk '{print $1}'` ## status
if [ $STATUS -ne 0 ]; then
  echo 'Error running bpepy.products.orbits.getorb function; failed to get orbits'
  exit 254
fi
# archive all strings in an array
IFS=' ' read -a array <<< "$PLIST"
# how many files are downloaded (1 or 2)
NF=1
if [ "${#array[@]}" -gt 4 ]; then
  NF=2
  OF1=${array[1]} ## original file
  OF2=${array[2]} ## original file
  DF1=${array[3]} ## downloaded file
  DF2=${array[4]} ## downloaded file
  TF1=${array[5]} ## type file
  TF2=${array[6]} ## type file
else
  NF=1
  OF1=${array[1]} ## original file
  DF1=${array[2]} ## downloaded file
  TF1=${array[3]} ## type file
fi
ORIGINAL_DF1=${DF1}

# //////////////////////////////////////////////////////////////////////////////
# UNCOMPRESS
# //////////////////////////////////////////////////////////////////////////////
if [ "$DECOMPRESS" == "YES" ]; then
  if [[ $DF1 =~ .Z$ ]]; then uncompress -f $DF1 ;fi #2>/dev/null
  #if [ "$?" -ne 0 ]; then echo "Error! failed to decompress $DF1"; exit -1; fi
  DF1=`echo "$DF1" | sed 's|.Z$||g'`
  if [ $NF -eq 2 ]; then 
    if [[ $DF2 =~ .Z$ ]]; then uncompress -f $DF2 ; fi #2>/dev/null
    #if [ "$?" -ne 0 ]; echo "Error! failed to decompress $DF1"; then exit -1; fi
    DF2=`echo "$DF2" | sed 's|.Z$||g'`
  fi
fi
if [[ "$DECOMPRESS" == "NO" && $NF -eq 2 ]]; then
  >&2 echo '!! Decompress not specified but needed to merge files! Files force decompressed !!'
  if [[ $DF1 =~ .Z$ ]]; then uncompress -f $DF1 ; fi #2>/dev/null
  #if [ "$?" -ne 0 ]; then echo "Error! failed to decompress $DF1"; exit -1; fi
  if [[ $DF2 =~ .Z$ ]]; then uncompress -f $DF2 ; fi #2>/dev/null
  #if [ "$?" -ne 0 ]; then echo "Error! failed to decompress $DF2"; exit -1; fi
  DF1=`echo "$DF1" | sed 's|.Z$||g'`
  DF2=`echo "$DF2" | sed 's|.Z$||g'`
fi
ORIGINAL_DF1=${DF1}

# //////////////////////////////////////////////////////////////////////////////
# MERGE FILES
# //////////////////////////////////////////////////////////////////////////////
if [ $NF -eq 2 ]; then
python -c \
"import bpepy.merge_igl_igs; \
 bpepy.merge_igl_igs.merge_igl_igs('"$DF1"','"$DF2"');" \
 1>.tmp.sp3 2>.bpepy.merge_igl_igs.log
  # first check the status
  STATUS=$?
  if [ $STATUS -ne 0 ]; then ## failure (!!)
    >&2 echo "Error merging files $DF1 and $DF2 ; details:"
    cat .bpepy.merge_igl_igs.log
    rm $DF1 $DF2 .tmp.sp3 .bpepy.merge_igl_igs.log 2>/dev/null
    exit -1
  fi
  # STATUS ok, move temporary merged file to igs file
  mv .tmp.sp3 $DF1
  rm $DF2 .bpepy.merge_igl_igs.log
  if [ "$DECOMPRESS" == "NO" ]; then 
    compress ${DF1}
    DF1=${DF1}.Z
  fi
fi

# //////////////////////////////////////////////////////////////////////////////
# RENAME TO UPPER-CASE
# //////////////////////////////////////////////////////////////////////////////
if [ "$TRUNCATE" == "YES" ]; then
  mv $DF1 ${DF1^^}
  DF1=${DF1^^}
fi

# //////////////////////////////////////////////////////////////////////////////
# REPORT
# //////////////////////////////////////////////////////////////////////////////
if test "${XML_OUT}" == "YES"
then
  > ${DF1}.meta
  echo -ne "<para>Orbit meta-information details: \
    Script run <command>$NAME</command> ${VERSION} (${RELEASE}) ${LAST_UPDATE} \
    Command run $XML_SENTENCE " >> ${DF1}.meta
  if [ $NF -eq 2 ]
  then
    echo -ne "Downloaded file <filename>$OF1</filename>, stored localy as \
      <filename>${ORIGINAL_DF1}</filename>, of type <emphasis>$TF1</emphasis> \
      and <filename>$OF2</filename>, stored localy as \
      <filename>${DF2}</filename>, of type <emphasis>$TF2</emphasis> \
      both from ${AC} Analysis Center. The two files were merged to \
      <filename>$DF1</filename>." >> ${DF1}.meta
  else
    echo -ne "Downloaded file <filename>$OF1</filename>, stored localy as \
      <filename>${DF1}</filename>, of type <emphasis>$TF1</emphasis> \
      from ${AC} Analysis Center.</para>" >> ${DF1}.meta
  fi
else
    echo "(wgetorbit) Downloaded Orbit File: $OF1 as ${DF1} of type: $TF1 from AC: ${AC}"
    if [ $NF -eq 2 ]; then
        echo "(wgetorbit) Downloaded Orbit File: $OF1 as ${ORIGINAL_DF1} of type: $TF1 from AC: ${AC}"
        echo "(wgetorbit) Downloaded Orbit File: $OF2 as ${DF2} of type: $TF2 from AC: ${AC}"
        echo "(wgetorbit) Orbit files merged to: $DF1"
    fi
fi

# //////////////////////////////////////////////////////////////////////////////
# EXIT
# //////////////////////////////////////////////////////////////////////////////
exit 0
