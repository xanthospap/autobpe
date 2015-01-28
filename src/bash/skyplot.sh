#! /bin/bash

################################################################################
## 
## |===========================================|
## |** Higher Geodesy Laboratory             **|
## |** Dionysos Satellite Observatory        **| 
## |** National Tecnical University of Athens**|
## |===========================================|
##
## filename              : skyplot.sh
                           NAME=skyplot
## version               : v-1.0
                           VERSION=v-1.0
                           RELEASE=beta
## created               : JAN-2015
## usage                 : 
## exit code(s)          : 0 -> success
##                         1 -> error
## discription           : 
## uses                  : 
## dependancies          : 
## notes                 :
## TODO                  : 
## detailed update list  :
                           LAST_UPDATE=JAN-2015
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
  echo " Purpose : Create a skyplot view of GPS satellites for a GPS / GNSS station."
  echo ""
  echo " Usage   : skyplot.sh -x <RINEX> -r <ORBIT_FILE> -e <CUT-OFF ANGLE> \\"
  echo "           [-s <START-DATE> -s <END-DATE> -n <STATION-NAME> -m <MP1-FILE>]"
  echo ""
  echo " Dependancies :"
  echo ""
  echo " Switches: -s --start-date= specify the date (optionally time) of the"
  echo "            start of observations. The format should be: YYYY-MM-DD or"
  echo "            YYYY-MM-DD:HH-MM-SS. All date elements should be positive integers."
  echo "           -e --end-date= specify the date (optionally time) of the"
  echo "            last observation. The format should be: YYYY-MM-DD or"
  echo "            YYYY-MM-DD:HH-MM-SS. All date elements should be positive integers."
  echo "           -n --station-name= specify the station name"
  echo "           -r --orbit-file= specify orbit information file which can be either "
  echo "            a broadcast or SP3 formated file"
  echo "           -c --cut-off-angle= specify the elevation cut-off angle in degrees"
  echo "            (positive integer)"
  echo "           -x --rinex-file= specify the input rinex file"
  echo "           -m --mp1-file= specify the mp1 file"
  echo "           -g --set-gmt if this switch is used, then a 'gmt' will be used"
  echo "            before the actual gmt program names (i.e. instead of using 'psxy [...]'"
  echo "            the script will issue 'gmt psxy [...]'"
  echo "           -o --output-dir= specify the output directory"
  echo "           -h --help display (this) help message and exit"
  echo "           -v --version dsiplay version and exit"
  echo ""
  echo " Exit Status: 1 -> error"
  echo " Exit Status: 0 -> sucess"
  echo ""
  echo " Example Usage"
  echo ""
  echo " WARNING !! The long options are only available if the GNU-enhanced version of getopt is"
  echo "            available; else, the user must only use short options"
  echo ""
  echo " |===========================================|"
  echo " |** Higher Geodesy Laboratory             **|"
  echo " |** Dionysos Satellite Observatory        **|"
  echo " |** National Tecnical University of Athens**|"
  echo " |===========================================|"
  echo ""
  echo "/******************************************************************************************/"
  exit 0
}


# //////////////////////////////////////////////////////////////////////////////
# PRE-DEFINE BASIC VARIABLES
# //////////////////////////////////////////////////////////////////////////////
START_DATE_STR=        ## The input string of first epoch
END_DATE_STR=          ## The input string of last epoch
STA_NAME=              ## Station name
ORBIT_FILE=            ## Orbit information file
ELEVATION=             ## Cut off angle
RINEX=                 ## Rinex file
SET_GMT=NO             ## Use 'gmt gmtname' instead of 'gmtname'
OUT_DIR=               ## Output directory
INP=cf2sky.inp         ## the skyplot .inp file
>${INP}

# //////////////////////////////////////////////////////////////////////////////
# GET COMMAND LINE ARGUMENTS
# //////////////////////////////////////////////////////////////////////////////
if [ "$#" == "0" ]; then help; fi

# Call getopt to validate the provided input. This depends on the getopt version available
getopt -T > /dev/null
if [ $? -eq 4 ]; then
  # GNU enhanced getopt is available
  ARGS=`getopt -o s:e:n:r:c:x:hvgo: \
  -l  start-date:,end-date:,station-name:,orbit-file:,cut-off-angle:,rinex-file:,help,version,set-gmt,output-dir: \
  -n 'skyplot' -- "$@"`
else
  # Original getopt is available (no long option names, no whitespace, no sorting)
  ARGS=`getopt s:e:n:r:c:x:hvgo: "$@"`
fi
# check for getopt error
if [ $? -ne 0 ] ; then echo "getopt error code : $status ;Terminating..." >&2 ; exit 1 ; fi
eval set -- $ARGS

# extract options and their arguments into variables.
while true ; do
  case "$1" in
    -s|--start-date)
      START_DATE_STR="${2}"; shift;;
    -e|--end-date)
      END_DATE_STR="${2}"; shift;;
    -n|--station-name)
      STA_NAME="${2}"; shift;;
    -r|--orbit-file)
      ORBIT_FILE="${2}"; shift;;
    -c|--cut-off-angle)
      ELEVATION="${2}"; shift;;
    -x|--rinex-file)
      RINEX="${2}"; shift;;
    -m|--mp1-file)
      MP1="${2}"; shift;;
    -g|--set-gmt)
      SET_GMT=YES;;
    -o|--output-dir)
      OUT_DIR="${2}"; shift;;
    -h|--help)
      help; exit 0;;
    -v|--version)
      dversion; exit 0;;
    --) # end of options
      shift; break;;
     *) 
      echo "*** Invalid argument $1 ; fatal" ; exit 1 ;;
  esac
  shift 
done

# //////////////////////////////////////////////////////////////////////////////
# RESOLVE VARIABLES
# //////////////////////////////////////////////////////////////////////////////
if test -z $ORBIT_FILE ; then
  echo "ERROR. You must specify the orbit filename"
  exit 1
fi

if test -z $RINEX ; then
  echo "ERROR. You must at least specify the RINEX name"
  exit 1
else
  if ! test -f $RINEX ; then
    echo "ERROR. Could not find rinex file $RINEX"
    exit 1
  fi
fi

## if the mp1 file not defined, set its name from rinex
I=${RINEX:(-3)}
if test -z $MP1 ; then
  MP1=${RINEX%%${I}}mp1
  echo "## MP1 filename missing; Set from rinex file, as: $MP1"
fi
if ! test -f ${MP1} ; then
  echo "ERROR. Failed to locate mp1 file : $MP1"
  exit 1
fi

## if the station name file not defined, set its name from rinex
if test -z $STA_NAME ; then
##STA_NAME=${RINEX:0:4}
  STA_NAME=`head -n 500 $RINEX | egrep "MARKER NAME$" | awk '{print $1}' 2>/dev/null`
  echo "## Station name missing; Set from rinex file, as: $STA_NAME"
fi

## if start date not defined, set its name from rinex
if test -z $START_DATE_STR ; then
  START_DATE_STR=`head -n 500 $RINEX | egrep "TIME OF FIRST OBS$" | \
                awk '{printf "%4i-%02i-%02i:%02i-%02i-%02i",$1,$2,$3,$4,$5,$6}' 2>/dev/null`
  echo "## Starting date missing; Set from rinex file, as: $START_DATE_STR"
fi

## if end date not defined, set its name from rinex
if test -z $END_DATE_STR ; then
  END_DATE_STR=`tail -n 150 $RINEX | egrep [0-9]G | tail -n 1 | \
                awk '{printf "%02i-%02i-%02i:%02i-%02i-%02i",$1,$2,$3,$4,$5,$6}' 2>/dev/null`
  if test ${END_DATE_STR:0:2} -lt 50 ; then
    END_DATE_STR=20${END_DATE_STR}
  else
    END_DATE_STR=19${END_DATE_STR}
  fi
  echo "## Ending date missing; Set from rinex file, as: $END_DATE_STR"
fi

# //////////////////////////////////////////////////////////////////////////////
# RESOLVE DATES
# //////////////////////////////////////////////////////////////////////////////
if echo $START_DATE_STR | grep ":" &>/dev/null ; then
  HAS_TIME=1
  STAMP=`echo ${START_DATE_STR%%:[0-9]*} | sed 's|-||g'`
else
  HAS_TIME=0
  STAMP=`echo $START_DATE_STR | sed 's|-||g'`
fi

if test ${HAS_TIME} -eq 0 ; then
  if ! date -d $START_DATE_STR '+%Y %m %d %H %M %S' 1>${INP} ; then
    echo "ERROR! Invalid start date: $START_DATE_STR"
    exit 1
  fi
else
  SDS=${START_DATE_STR%%:[0-9]*}
  HMS=${START_DATE_STR##[0-9]*:}
  HMS=`echo $HMS | sed 's|-|:|g'`
  if ! date -d "$SDS $HMS" '+%Y %m %d %H %M %S' 1>>${INP} ; then
    echo "ERROR! Invalid start date: $START_DATE_STR"
    exit 1
  fi
fi

if echo $END_DATE_STR | grep ":" &>/dev/null ; then
  HAS_TIME=1
else
  HAS_TIME=0
fi

if test ${HAS_TIME} -eq 0 ; then
  if ! date -d $END_DATE_STR '+%Y %m %d %H %M %S' 1>>${INP} ; then
    echo "ERROR! Invalid end date: $END_DATE_STR"
    exit 1
  fi
else
  SDS=${END_DATE_STR%%:[0-9]*}
  HMS=${END_DATE_STR##[0-9]*:}
  HMS=`echo $HMS | sed 's|-|:|g'`
  if ! date -d "$SDS $HMS" '+%Y %m %d %H %M %S' 1>>${INP} ; then
    echo "ERROR! Invalid end date: $END_DATE_STR"
    exit 1
  fi
fi

# //////////////////////////////////////////////////////////////////////////////
# ORBIT INFORMATION FILE
# //////////////////////////////////////////////////////////////////////////////
if ! test -f $ORBIT_FILE ; then
  echo "ERROR! Orbit file $ORBIT_FILE not found!"
  exit 1
else
  echo $ORBIT_FILE 1>>${INP}
fi

# //////////////////////////////////////////////////////////////////////////////
# CREATE THE TITLE
# //////////////////////////////////////////////////////////////////////////////
echo "P1 Pseudorange Multipath at $STA_NAME" 1>>${INP}

# //////////////////////////////////////////////////////////////////////////////
# ELEVATION CUT-OFF ANGLE
# //////////////////////////////////////////////////////////////////////////////
if [[ $ELEVATION =~ ^[0-9]+$ ]]; then
    echo $ELEVATION 1>>${INP}
else
   echo "ERROR. Invalid elevation angle $ELEVATION"
   exit 1
fi

# //////////////////////////////////////////////////////////////////////////////
# RINEX FILE
# //////////////////////////////////////////////////////////////////////////////
echo $RINEX 1>>${INP}

# //////////////////////////////////////////////////////////////////////////////
# MP1 FILE
# //////////////////////////////////////////////////////////////////////////////
echo $MP1 1>>${INP}

# //////////////////////////////////////////////////////////////////////////////
# RUN cf2sky.e (SKYPLOT)
# //////////////////////////////////////////////////////////////////////////////
rm cf2sky.log 2>/dev/null
/usr/local/bin/cf2sky &>/dev/null
if ! cat cf2sky.log | grep "^Normal Termination" &>/dev/null ; then
  echo "ERROR. Failed run of cf2sky.e"
  exit 1
fi

# //////////////////////////////////////////////////////////////////////////////
# RUN THE BATCH FILE SKYPLOT.BAT
# //////////////////////////////////////////////////////////////////////////////
chmod +x skyplot.bat
if test "${SET_GMT}" == "YES" ; then
  sed -i 's|^psxy|gmt psxy|g' skyplot.bat
  sed -i 's|^pstext|gmt pstext|g' skyplot.bat
  sed -i 's|^psvelo|gmt psvelo|g' skyplot.bat
fi
./skyplot.bat &>/dev/null
mv skyplot.ps ${STA_NAME}-${STAMP}-cf2sky.ps &>/dev/null
if test $? -ne 0 ; then
  echo "ERROR. PostScript file seems to be missing."
  rm cf2sky.inp cf2sky.log rm.me skyplot.inp skyplot.bat 2>/dev/null
  exit 1
fi

# //////////////////////////////////////////////////////////////////////////////
# MOVE THE PLOT TO THE OUTPUT DIRECTORY
# //////////////////////////////////////////////////////////////////////////////
if ! test -z $OUT_DIR
then
  if test -d ${OUT_DIR}
  then
    mv ${STA_NAME}-${STAMP}-cf2sky.ps ${OUT_DIR}/${STA_NAME}-${STAMP}-cf2sky.ps
  else
    echo "ERROR. Failed to move plot; direcoty $OUT_DIR does not exist"
  fi
fi

# //////////////////////////////////////////////////////////////////////////////
# EXIT
# //////////////////////////////////////////////////////////////////////////////
rm cf2sky.inp cf2sky.log rm.me skyplot.inp skyplot.bat 2>/dev/null
exit 0
