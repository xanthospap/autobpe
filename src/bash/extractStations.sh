#! /bin/bash

################################################################################
##
## |===========================================|
## |** Higher Geodesy Laboratory             **|
## |** Dionysos Satellite Observatory        **|
## |** National Tecnical University of Athens**|
## |===========================================|
##
## filename              : extractStations.sh
                           NAME=extractStations
## version               : v-1.0
                           VERSION=v-1.0
                           RELEASE=beta
## created               : MAY-2013
## usage                 : extractStations.sh
## exit code(s)          : 0 -> success
##                        -1 -> error
## discription           : 
## uses                  :
## needs                 : 
##                         solution output file (e.g. FFG122000.OUT)
## notes                 :
## TODO                  : 
## detailed update list  : DEC-2013 Header added
##                         DEC-2013 added -s switch
##                         DEC-2014 Major revision
                           LAST_UPDATE=DEC-2014
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
  echo " Purpose : Update station-specific files using a processing output file."
  echo ""
  echo " Usage   : extractStations.sh -y [YEAR] -d [DOY] -c [CAMPAIGN] -t [SOLUTION TYPE]"
  echo ""
  echo " Switches: -a --use-all specify no stations; just use every station found in the"
  echo "            input file (see -o)"
  echo "           -s --stations specify stations to compare seperated by "
  echo "            whitespace (e.g -s penc pdel ...)"
  echo "           -f --station-file specify station file. File must have one line,"
  echo "            where each station is seperated by a whitespace character."
  echo "           -o --solution-summary the solution summary (report) where the station crds"
  echo "            are to be extracted from"
  echo "           -d --save-dir directory where station-specific folders exist. E.g. if specified"
  echo "            station dion, and -d somepath, the the script will search for the files "
  echo "            dion.c.cts, dion.g.cts and dion.upd, at somepath/dion/..."
  echo "           -r --only-report only report differences; do NOT update station-specific files"
  echo "           -u --ultra-rapid if this switch is specified, then the script will not"
  echo "            update files station].c.cts, [station].g.cts but instead [station].c.ctsR"
  echo "            and [station].g.ctsR"
  echo "           -e --ellipsoid extract ellipsoid parameter (i.e. semi-major, semi-minor axis and"
  echo "            angle (these parameters are only shown in the report)"
  echo "           -q --quiet do NOT report missing/unprocessed stations"
  echo "           -h --help print help message and exit"
  echo "           -v --version print version and exit"
  echo ""
  echo " Exit Status:  >=0 -> Sucess (number of stations updated if # of stations < 255)"
  echo " Exit Status:  254 -> Error"
  echo " Exit Status:  253 -> Could not extract data foe one or more station(s)"
  echo ""
  echo " Note: In case of Exit Status -2, the script has encountered a station for which it could not"
  echo " extract the wanted information. However, the rest of the stations should have been updated, i.e"
  echo " the script will not stop after encountering a station-specific problem, but will report it."
  echo ""
  echo " |===========================================|"
  echo " |** Higher Geodesy Laboratory             **|"
  echo " |** Dionysos Satellite Observatory        **|"
  echo " |** National Tecnical University of Athens**|"
  echo " |===========================================|"
  echo ""
  echo "/******************************************************************************************/"
}

# //////////////////////////////////////////////////////////////////////////////
# DEFAULT VARIABLES
# //////////////////////////////////////////////////////////////////////////////
STATION_FILE=0                       ## file with list of stations to be updated
OUTPUT_FILE=                         ## processing summary (report)
STA_DIR=/media/Seagate/solutions52/stations ## station-specific folders directory
STATIONS=()                          ## list of stations extracted from the station file
TIME_STAMP=`date +%s`                ## time stamp
DATE_STAMP=`date +"%Y %b %d %H:%M"`  ## date stamp
ONLY_REPORT=NO                       ## only report, do not update
USE_RAPID_FILES=NO                   ## update the rapid files ([station].[c|g].ctsR)
NUM_OF_STA=0                         ## total number of stations to update
QUIET=NO                             ## report missing stations
XTR_ELL=NO                           ## extract ellipsoid parameters
USE_ALL_STATIONS=NO                  ## no stations provided; use all existing in file

# //////////////////////////////////////////////////////////////////////////////
# GET COMMAND LINE ARGUMENTS
# //////////////////////////////////////////////////////////////////////////////
if [ "$#" == "0" ]
then
  help
  exit 254
fi

while [ $# -gt 0 ]
do
  case "$1" in
    -s|--stations)
      shift
      while [ $# -gt 0 ]
      do
        j=$1
        if [ ${j:0:1} == "-" ]
        then
          break
        else
          STATIONS+=($j)
          shift
        fi
      done
      ;;
    -f|--station-file)
      STATION_FILE=${2}
      shift 2 ;;
    -h|--help)
      help; exit 0 ;;
    -v|--version)
      dversion; exit 0 ;;
    -r|--only-report)
      ONLY_REPORT=YES
      shift;;
    -o|--solution-summary)
      OUTPUT_FILE=${2}
      shift 2;;
    -d|--save-dir)
      STA_DIR=${2}
      shift 2;;
    -u|--ultra-rapid)
      USE_RAPID_FILES=YES
      shift;;
    -e|--ellipsoid)
      XTR_ELL=YES
      shift;;
    -q|--quiet)
      QUIET=YES
      shift;;
    -a|--use-all)
      USE_ALL_STATIONS=YES
      shift;;
    *)
      echo "Ignoring cmd: $1"
      shift
      ;;
  esac
done

# //////////////////////////////////////////////////////////////////////////////
# CHECK THAT SUMMARY FILE EXISTS
# //////////////////////////////////////////////////////////////////////////////
if [ ! -s "$OUTPUT_FILE" ]; then
  echo "***(extractStations) Processing summary file $OUTPUT_FILE does not exist"
  exit 254
fi

# //////////////////////////////////////////////////////////////////////////////
# CHECK THAT STATION DIRECTORY EXISTS
# //////////////////////////////////////////////////////////////////////////////
if [ "$ONLY_REPORT" == "NO" ]; then
  if [ ! -d "$STA_DIR" ]; then
    echo "***(extractStations) Directory $STA_DIR does not exist!"
    exit 254
  fi
fi

# //////////////////////////////////////////////////////////////////////////////
# IF FILE IS GIVEN, ADD ITS ENTRIES TO THE STATION LIST
# //////////////////////////////////////////////////////////////////////////////
if [ "$STATION_FILE" != "0" ]; then
  if [ -f "$STATION_FILE" ]; then
    TEMPARRAY=( $( cat "$STATION_FILE" ) )
    for j in ${TEMPARRAY[*]}; do
      J=`echo $j | tr 'a-z' 'A-Z'`
      STATIONS+=($J)
    done
  else
    echo "***(extractStations) File ${STATION_FILE} does not exist!"
  fi
fi

# //////////////////////////////////////////////////////////////////////////////
# IF PROCESS ALL STATIONS FOUND IN FILE
# //////////////////////////////////////////////////////////////////////////////$
if test "$USE_ALL_STATIONS" == "YES"
then
    ARRAY=$(sed -n '/num  Station name     obs e\/f\/h        X (m)           Y (m)           Z (m)        Latitude       Longitude    Height (m)/,/^$/p' ${OUTPUT_FILE} | tail -n +3 | awk '{print $2}')
    STATIONS=()
    STATIONS=$ARRAY
fi

# //////////////////////////////////////////////////////////////////////////////
# PRE_SET STATUS
# //////////////////////////////////////////////////////////////////////////////
STATUS=0
NUM_OF_STA=${#STATIONS[@]}
if [ "$NUM_OF_STA" -eq 0 ]; then
  #echo "No stations to update"
  exit 0
fi

# //////////////////////////////////////////////////////////////////////////////
# EXTRACT REFERENCE DATE FROM THE OUTPUT SUMMARY FILE
# //////////////////////////////////////////////////////////////////////////////

# date is extracted from the record:
#  Sol Station name         Typ Correction  Estimated value  RMS error   A priori value Unit    From                To                  MJD           Num Abb  
# ------------------------------------------------------------------------------------------------------------------------------------------------------------
#   1 ANKR                   X    0.03313    4121948.48269    0.00391    4121948.44956 meters  2014-07-19 00:00:00 2014-07-19 23:59:30 56857.49983     1 #CRD 
# as MJD
MJD=`egrep -A2 \
" Sol Station name         Typ Correction  Estimated value  RMS error   A priori value Unit    From                To                  MJD           Num Abb  " \
/media/Seagate/solutions52/2014/200/FFG142000.OUT | tail -1 | awk '{print $13}' 2>/dev/null`
imjd=${MJD%%.*}
fmjd=${MJD/*./0.}

DATE_STR=`python -c "
import bpepy.gpstime
import sys
s,d = bpepy.gpstime.jd2gd ('$imjd','$fmjd')
if s != 0 : sys.exit (1)
d.strftime ('%Y %j %m %d')
sys.exit (0)"` ##2>/dev/null`
    
# check for error
if test $? -ne 0 ; then
  echo "***ERROR! Failed to resolve MJD $MJD ($DATE_STR)"
  exit 254
fi

# //////////////////////////////////////////////////////////////////////////////
# FOR EVERY STATION IN UPDATE LIST
# //////////////////////////////////////////////////////////////////////////////
COUNTER=0
MISSING=()
for j in ${STATIONS[*]}; do

  STATION=${j^^}
  station=`echo $STATION | tr 'A-Z' 'a-z'`

  CRD_C_FILE=${STA_DIR}/${station}/${station}.c.cts
  CRD_G_FILE=${STA_DIR}/${station}/${station}.g.cts
  UPD_FILE=${STA_DIR}/${station}/${station}.upd
  
  if [ "$USE_RAPID_FILES" == "YES" ]; then
    CRD_C_FILE=${CRD_C_FILE}R
    CRD_G_FILE=${CRD_G_FILE}R
  fi

  ## Station information are extracted from the part:
  ## Station name          Typ   A priori value  Estimated value    Correction     RMS error      3-D ellipsoid        2-D ellipse
  ## ------------------------------------------------------------------------------------------------------------------------------------
  ## ANKR                  X      4121948.44819    4121948.45938       0.01119       0.00235
  ##                       Y      2652187.86614    2652187.87195       0.00581       0.00140
  ##                       Z      4069023.84121    4069023.83843      -0.00278       0.00209
  ##
  ##                       U          976.01641        976.02426       0.00785       0.00324     0.00325    4.7
  ##                       N         39.8873723       39.8873722      -0.01020       0.00085     0.00075   67.2     0.00079   69.1
  ##                       E         32.7584700       32.7584700      -0.00117       0.00080     0.00086    0.2     0.00086
  egrep -A6 "${STATION}                  X      [0-9. -+]+$" $OUTPUT_FILE > .tmp
  LNS=`cat .tmp | wc -l `

  if [ "${LNS}" -eq 0 ]; then   ## station not found in the processing summary
    MISSING+=(${STATION})
  elif [ "${LNS}" -ne 7 ]; then ## invalid station record in summary file
    echo "***(extractStations) Error extracting information for station ${STATION} (skipped)"
    STATUS=253
  else
    xcrd=`cat .tmp | sed -n '1p' | awk '{printf "%+09.5f\n",$4}'`
    xrms=`cat .tmp | sed -n '1p' | awk '{printf "%+09.5f\n",$6}'`
    xcor=`cat .tmp | sed -n '1p' | awk '{printf "%+09.5f\n",$5}'`
    ycrd=`cat .tmp | sed -n '2p' | awk '{printf "%+09.5f\n",$3}'`
    yrms=`cat .tmp | sed -n '2p' | awk '{printf "%+09.5f\n",$5}'`
    ycor=`cat .tmp | sed -n '2p' | awk '{printf "%+09.5f\n",$4}'`
    zcrd=`cat .tmp | sed -n '3p' | awk '{printf "%+09.5f\n",$3}'`
    zrms=`cat .tmp | sed -n '3p' | awk '{printf "%+09.5f\n",$5}'`
    zcor=`cat .tmp | sed -n '3p' | awk '{printf "%+09.5f\n",$4}'`
    ucrd=`cat .tmp | sed -n '5p' | awk '{printf "%+09.5f\n",$3}'`
    urms=`cat .tmp | sed -n '5p' | awk '{printf "%+09.5f\n",$5}'`
    ucor=`cat .tmp | sed -n '5p' | awk '{printf "%+09.5f\n",$4}'`
    ncrd=`cat .tmp | sed -n '6p' | awk '{printf "%+09.5f\n",$3}'`
    nrms=`cat .tmp | sed -n '6p' | awk '{printf "%+09.5f\n",$5}'`
    ncor=`cat .tmp | sed -n '6p' | awk '{printf "%+09.5f\n",$4}'`
    ecrd=`cat .tmp | sed -n '7p' | awk '{printf "%+09.5f\n",$3}'`
    erms=`cat .tmp | sed -n '7p' | awk '{printf "%+09.5f\n",$5}'`
    ecor=`cat .tmp | sed -n '7p' | awk '{printf "%+09.5f\n",$4}'`
    smax=`cat .tmp | sed -n '6p' | awk '{printf "%+10.6f\n",$8}'`
    smix=`cat .tmp | sed -n '7p' | awk '{printf "%+10.6f\n",$8}'`
    sazi=`cat .tmp | sed -n '6p' | awk '{printf "%+07.2f\n",$9}'`
    if [ "$ONLY_REPORT" == "NO" ]; then            ## Update station files
      for i in $CRD_C_FILE $CRD_G_FILE $UPD_FILE; do
        if [ ! -f "${i}" ]; then
          echo "***(extractStations) Error missing file ${i}; cannot update station $j (fatal)"
          exit 254
        fi
      done
      sed -i "s|^${DATE_STR}|#${DATE_STR}|g" $CRD_C_FILE 2>/dev/null
      sed -i "s|^${DATE_STR}|#${DATE_STR}|g" $CRD_G_FILE 2>/dev/null
      echo "$DATE_STR $xcrd $ycrd $zcrd $xrms $yrms $zrms $TIME_STAMP" >> $CRD_C_FILE
      echo "$DATE_STR $ncrd $ecrd $ucrd $nrms $erms $urms $TIME_STAMP" >> $CRD_G_FILE
      echo "$DATE_STAMP" > $UPD_FILE
      let COUNTER=COUNTER+1
    fi
    if test "$XTR_ELL" == "YES"
    then
        echo "$j diff: $xcor $ycor $zcor $ncor $ecor $ucor $smax $smix $sazi"
    else
        echo "$j diff: $xcor $ycor $zcor $ncor $ecor $ucor"
    fi
  fi ## if station information block is extracted
done ## for every station in list
rm .tmp 2>/dev/null

# //////////////////////////////////////////////////////////////////////////////
# REPORT MISSING STATIONS (IF ANY)
# //////////////////////////////////////////////////////////////////////////////
if [ "$QUIET" == "NO" ]; then
  if test ${#MISSING[@]} -ne 0 ; then
    for i in "${MISSING[@]}"; do
      echo "## Station $i not processed"
    done
  fi
fi

# //////////////////////////////////////////////////////////////////////////////
# EXIT
# //////////////////////////////////////////////////////////////////////////////
if [ "$ONLY_REPORT" == "NO" ]; then
  echo "(extractStations) Updated ${COUNTER} / ${NUM_OF_STA} stations"
fi
if test ${STATUS} -eq 0 ; then
  exit $COUNTER
else
  exit $STATUS
fi
